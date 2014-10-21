package Code::TidyAll;
BEGIN {
  $Code::TidyAll::VERSION = '0.07';
}
use Cwd qw(realpath);
use Config::INI::Reader;
use Code::TidyAll::Cache;
use Code::TidyAll::Util
  qw(abs2rel basename can_load dirname dump_one_line mkpath read_dir read_file rel2abs tempdir_simple uniq write_file);
use Code::TidyAll::Result;
use Date::Format;
use Digest::SHA1 qw(sha1_hex);
use File::Find qw(find);
use File::Zglob;
use List::Pairwise qw(grepp mapp);
use List::MoreUtils qw(uniq);
use Moo;
use Time::Duration::Parse qw(parse_duration);
use Try::Tiny;
use strict;
use warnings;

# External
has 'backup_ttl'    => ( is => 'ro', default => sub { '1 hour' } );
has 'check_only'    => ( is => 'ro' );
has 'data_dir'      => ( is => 'lazy' );
has 'mode'          => ( is => 'ro', default => sub { 'cli' } );
has 'no_backups'    => ( is => 'ro' );
has 'no_cache'      => ( is => 'ro' );
has 'output_suffix' => ( is => 'ro', default => sub { '' } );
has 'plugins'       => ( is => 'ro', required => 1 );
has 'quiet'         => ( is => 'ro' );
has 'refresh_cache' => ( is => 'ro' );
has 'root_dir'      => ( is => 'ro', required => 1 );
has 'verbose'       => ( is => 'ro' );

# Internal
has 'backup_dir'       => ( is => 'lazy', init_arg => undef, trigger => 1 );
has 'backup_ttl_secs'  => ( is => 'lazy', init_arg => undef );
has 'base_sig'         => ( is => 'lazy', init_arg => undef );
has 'cache'            => ( is => 'lazy', init_arg => undef );
has 'plugin_objects'   => ( is => 'lazy', init_arg => undef );
has 'plugins_for_mode' => ( is => 'lazy', init_arg => undef );

my $ini_name = 'tidyall.ini';

sub _build_backup_dir {
    my $self = shift;
    return $self->data_dir . "/backups";
}

sub _build_backup_ttl_secs {
    my $self = shift;
    return parse_duration( $self->backup_ttl );
}

sub _build_base_sig {
    my $self = shift;
    my $active_plugins = join( "|", map { $_->name } @{ $self->plugin_objects } );
    return $self->_sig( [ $Code::TidyAll::VERSION || 0, $active_plugins ] );
}

sub _build_cache {
    my $self = shift;
    return Code::TidyAll::Cache->new( cache_dir => $self->data_dir . "/cache" );
}

sub _build_data_dir {
    my $self = shift;
    return $self->root_dir . "/.tidyall.d";
}

sub _build_plugins_for_mode {
    my $self    = shift;
    my $plugins = $self->plugins;
    if ( my $mode = $self->mode ) {
        $plugins = { grepp { $self->_plugin_conf_matches_mode( $b, $mode ) } %{ $self->plugins } };
    }
    return $plugins;
}

sub _build_plugin_objects {
    my $self = shift;
    return [
        map { $self->_load_plugin( $_, $self->plugins->{$_} ) }
        sort keys( %{ $self->plugins_for_mode } )
    ];
}

sub BUILD {
    my ( $self, $params ) = @_;

    # Strict constructor
    #
    if ( my @bad_params = grep { !$self->can($_) } keys(%$params) ) {
        die sprintf( "unknown constructor param(s) %s",
            join( ", ", sort map { "'$_'" } @bad_params ) );
    }

    $self->{root_dir}         = realpath( $self->{root_dir} );
    $self->{plugins_for_path} = {};

    unless ( $self->no_backups ) {
        mkpath( $self->backup_dir, 0, 0775 );
        $self->_purge_backups_periodically();
    }
}

sub new_from_conf_file {
    my ( $class, $conf_file, %params ) = @_;

    die "no such file '$conf_file'" unless -f $conf_file;
    my $conf_params = $class->_read_conf_file($conf_file);
    my $main_params = delete( $conf_params->{'_'} ) || {};
    %params = (
        plugins  => $conf_params,
        root_dir => realpath( dirname($conf_file) ),
        %$main_params, %params
    );

    # Initialize with alternate class if given
    #
    if ( my $tidyall_class = delete( $params{tidyall_class} ) ) {
        die "cannot load '$tidyall_class'" unless can_load($tidyall_class);
        $class = $tidyall_class;
    }

    $class->msg( "constructing %s with these params: %s", $class, dump_one_line( \%params ) )
      if ( $params{verbose} );

    return $class->new(%params);
}

sub _load_plugin {
    my ( $self, $plugin_name, $plugin_conf ) = @_;
    my $class_name = (
        $plugin_name =~ /^\+/
        ? substr( $plugin_name, 1 )
        : "Code::TidyAll::Plugin::$plugin_name"
    );
    try {
        can_load($class_name) || die "not found";
    }
    catch {
        die "could not load plugin class '$class_name': $_";
    };

    return $class_name->new(
        conf    => $plugin_conf,
        name    => $plugin_name,
        tidyall => $self
    );
}

sub _plugin_conf_matches_mode {
    my ( $self, $conf, $mode ) = @_;

    if ( my $only_modes = $conf->{only_modes} ) {
        return 0 if ( " " . $only_modes . " " ) !~ / $mode /;
    }
    if ( my $except_modes = $conf->{except_modes} ) {
        return 0 if ( " " . $except_modes . " " ) =~ / $mode /;
    }
    return 1;
}

sub process_all {
    my $self = shift;

    return $self->process_files( $self->find_matched_files );
}

sub process_files {
    my ( $self, @files ) = @_;

    return map { $self->process_file( realpath($_) ) } @files;
}

sub process_file {
    my ( $self, $file ) = @_;

    my $path      = $self->_small_path($file);
    my $cache     = $self->no_cache ? undef : $self->cache;
    my $cache_key = "sig/$path";
    my $contents  = my $orig_contents = read_file($file);
    if ( $cache && ( my $sig = $cache->get($cache_key) ) ) {
        if ( $self->refresh_cache ) {
            $cache->remove($cache_key);
        }
        elsif ( $sig eq $self->_file_sig( $file, $orig_contents ) ) {
            $self->msg( "[cached] %s", $path ) if $self->verbose;
            return Code::TidyAll::Result->new( path => $path, state => 'cached' );
        }
    }

    my $result = $self->process_source( $orig_contents, $path );

    if ( $result->state eq 'tidied' ) {
        $self->_backup_file( $path, $contents );
        $contents = $result->new_contents;
        write_file( join( '', $file, $self->output_suffix ), $contents );
    }
    $cache->set( $cache_key, $self->_file_sig( $file, $contents ) ) if $cache && $result->ok;

    return $result;
}

sub process_source {
    my ( $self, $contents, $path ) = @_;

    my @plugins = $self->plugins_for_path($path);
    if ( !@plugins ) {
        $self->msg( "[no plugins apply%s] %s",
            $self->mode ? " for mode '" . $self->mode . "'" : "", $path )
          if $self->verbose;
        return Code::TidyAll::Result->new( path => $path, state => 'no_match' );
    }

    my $basename = basename($path);
    my $error;

    my $new_contents = my $orig_contents = $contents;
    my $plugin;

    try {
        foreach my $method (qw(preprocess_source process_source_or_file postprocess_source)) {
            foreach $plugin (@plugins) {
                $new_contents = $plugin->$method( $new_contents, $basename );
            }
        }
    }
    catch {
        chomp;
        $error = $_;
        $error = sprintf( "*** '%s': %s", $plugin->name, $_ ) if $plugin;
    };

    my $was_tidied = !$error && ( $new_contents ne $orig_contents );
    if ( $was_tidied && $self->check_only ) {
        $error = "*** needs tidying";
        undef $was_tidied;
    }

    if ( !$self->quiet || $error ) {
        my $status = $was_tidied ? "[tidied]  " : "[checked] ";
        my $plugin_names =
          $self->verbose ? sprintf( " (%s)", join( ", ", map { $_->name } @plugins ) ) : "";
        $self->msg( "%s%s%s", $status, $path, $plugin_names );
    }

    if ($error) {
        $self->msg( "%s", $error );
        return Code::TidyAll::Result->new( path => $path, state => 'error', msg => $error );
    }
    elsif ($was_tidied) {
        return Code::TidyAll::Result->new(
            path         => $path,
            state        => 'tidied',
            new_contents => $new_contents
        );
    }
    else {
        return Code::TidyAll::Result->new( path => $path, state => 'checked' );
    }
}

sub _read_conf_file {
    my ( $class, $conf_file ) = @_;
    my $conf_string = read_file($conf_file);
    my $root_dir    = dirname($conf_file);
    $conf_string =~ s/\$ROOT/$root_dir/g;
    my $conf_hash = Config::INI::Reader->read_string($conf_string);
    die "'$conf_file' did not evaluate to a hash"
      unless ( ref($conf_hash) eq 'HASH' );
    return $conf_hash;
}

sub _backup_file {
    my ( $self, $path, $contents ) = @_;
    unless ( $self->no_backups ) {
        my $backup_file = join( "/", $self->backup_dir, $self->_backup_filename($path) );
        mkpath( dirname($backup_file), 0, 0775 );
        write_file( $backup_file, $contents );
    }
}

sub _backup_filename {
    my ( $self, $path ) = @_;

    return join( "", $path, "-", time2str( "%Y%m%d-%H%M%S", time ), ".bak" );
}

sub _purge_backups_periodically {
    my ($self) = @_;
    my $cache = $self->cache;
    my $last_purge_backups = $cache->get("last_purge_backups") || 0;
    if ( time > $last_purge_backups + $self->backup_ttl_secs ) {
        $self->_purge_backups();
        $cache->set( "last_purge_backups", time() );
    }
}

sub _purge_backups {
    my ($self) = @_;
    $self->msg("purging old backups") if $self->verbose;
    find(
        {
            follow => 0,
            wanted => sub {
                unlink $_ if -f && /\.bak$/ && time > ( stat($_) )[9] + $self->backup_ttl_secs;
            },
            no_chdir => 1
        },
        $self->backup_dir
    );
}

sub find_conf_file {
    my ( $class, $start_dir ) = @_;

    my $path1     = rel2abs($start_dir);
    my $path2     = realpath($start_dir);
    my $conf_file = $class->_find_conf_file_upward($path1)
      || $class->_find_conf_file_upward($path2);
    unless ( defined $conf_file ) {
        die sprintf( "could not find $ini_name upwards from %s",
            ( $path1 eq $path2 ) ? "'$path1'" : "'$path1' or '$path2'" );
    }
    return $conf_file;
}

sub _find_conf_file_upward {
    my ( $class, $search_dir ) = @_;

    $search_dir =~ s{/+$}{};

    my $cnt = 0;
    while (1) {
        my $try_path = "$search_dir/$ini_name";
        if ( -f $try_path ) {
            return $try_path;
        }
        elsif ( $search_dir eq '/' ) {
            return undef;
        }
        else {
            $search_dir = dirname($search_dir);
        }
        die "inf loop!" if ++$cnt > 100;
    }
}

sub find_matched_files {
    my ($self) = @_;

    my @matched_files;
    my $plugins_for_path = $self->{plugins_for_path};
    my $root_length      = length( $self->root_dir );
    foreach my $plugin ( @{ $self->plugin_objects } ) {
        my @selected = grep { -f && !-l } $self->_zglob( $plugin->select );
        if ( defined( $plugin->ignore ) ) {
            my %is_ignored = map { ( $_, 1 ) } $self->_zglob( $plugin->ignore );
            @selected = grep { !$is_ignored{$_} } @selected;
        }
        push( @matched_files, @selected );
        foreach my $file (@selected) {
            my $path = substr( $file, $root_length + 1 );
            $plugins_for_path->{$path} ||= [];
            push( @{ $plugins_for_path->{$path} }, $plugin );
        }
    }
    return sort( uniq(@matched_files) );
}

sub plugins_for_path {
    my ( $self, $path ) = @_;

    $self->{plugins_for_path}->{$path} ||=
      [ grep { $_->matches_path($path) } @{ $self->plugin_objects } ];
    return @{ $self->{plugins_for_path}->{$path} };
}

sub _zglob {
    my ( $self, $expr ) = @_;

    local $File::Zglob::NOCASE = 0;
    return File::Zglob::zglob( join( "/", $self->root_dir, $expr ) );
}

sub _small_path {
    my ( $self, $path ) = @_;
    die sprintf( "'%s' is not underneath root dir '%s'!", $path, $self->root_dir )
      unless index( $path, $self->root_dir ) == 0;
    return substr( $path, length( $self->root_dir ) + 1 );
}

sub _file_sig {
    my ( $self, $file, $contents ) = @_;
    my $last_mod = ( stat($file) )[9];
    $contents = read_file($file) if !defined($contents);
    return $self->_sig( [ $self->base_sig, $last_mod, $contents ] );
}

sub _sig {
    my ( $self, $data ) = @_;
    return sha1_hex( join( ",", @$data ) );
}

sub _tempdir {
    my ($self) = @_;
    $self->{tempdir} ||= tempdir_simple();
    return $self->{tempdir};
}

sub msg {
    my ( $self, $format, @params ) = @_;
    printf "$format\n", @params;
}

1;



=pod

=head1 NAME

Code::TidyAll - Engine for tidyall, your all-in-one code tidier and validator

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use Code::TidyAll;

    my $ct = Code::TidyAll->new_from_conf_file(
        '/path/to/conf/file',
        ...
    );

    # or

    my $ct = Code::TidyAll->new(
        root_dir => '/path/to/root',
        plugins  => {
            perltidy => {
                select => qr/\.(pl|pm|t)$/,
                options => { argv => '-noll -it=2' },
            },
            ...
        }
    );

    # then...

    $ct->process_files($file1, $file2);

    # or

    $ct->process_all();

=head1 DESCRIPTION

This is the engine used by L<tidyall|tidyall> - read that first to get an
overview.

You can call this API from your own program instead of executing C<tidyall>.

=head1 CONSTRUCTION

=head2 Construtor methods

=over

=item new (%params)

The regular constructor. Must pass at least I<plugins> and I<root_dir>.

=item new_with_conf_file ($conf_file, %params)

Takes a conf file path, followed optionally by a set of key/value parameters. 
Reads parameters out of the conf file and combines them with the passed
parameters (the latter take precedence), and calls the regular constructor.

If the conf file or params defines I<tidyall_class>, then that class is
constructed instead of C<Code::TidyAll>.

=back

=head2 Constructor parameters

=over

=item plugins

Specify a hash of plugins, each of which is itself a hash of options. This is
equivalent to what would be parsed out of the sections in C<tidyall.ini>.

=item backup_ttl

=item check_only

=item data_dir

=item mode

=item no_backups

=item no_cache

=item output_suffix

=item quiet

=item root_dir

=item verbose

These options are the same as the equivalent C<tidyall> command-line options,
replacing dashes with underscore (e.g. the C<backup-ttl> option becomes
C<backup_ttl> here).

=back

=head1 METHODS

=over

=item process_all

Process all files; this implements the C<tidyall -a> option.

=item process_files (file, ...)

Call L</process_file> on each file. Return a list of
L<Code::TidyAll::Result|Code::TidyAll::Result> objects, one for each file.

=item process_file (file)

Process the I<file>, meaning

=over

=item *

Check the cache and return immediately if file has not changed

=item *

Apply appropriate matching plugins

=item *

Print success or failure result to STDOUT, depending on quiet/verbose settings

=item *

Write the cache if enabled

=item *

Return a L<Code::TidyAll::Result|Code::TidyAll::Result> object

=back

=item process_source (source, path)

Same as L</process_file>, but process the I<source> string instead of a file.
You must still pass the relative I<path> from the root as the second argument,
so that we know which plugins to apply. Return a
L<Code::TidyAll::Result|Code::TidyAll::Result> object.

=item plugins_for_path (path)

Given a relative I<path> from the root, return a list of
L<Code::TidyAll::Plugin|Code::TidyAll::Plugin> objects that apply to it, or an
empty list if no plugins apply.

=item find_conf_file (start_dir)

Class method. Start in the I<start_dir> and work upwards, looking for a
C<tidyall.ini>.  Return the pathname if found or throw an error if not found.

=back

=head1 SEE ALSO

L<Code::TidyAll|Code::TidyAll>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

