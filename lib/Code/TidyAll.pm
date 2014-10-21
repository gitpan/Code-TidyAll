package Code::TidyAll;
BEGIN {
  $Code::TidyAll::VERSION = '0.02';
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
use Time::Duration::Parse qw(parse_duration);
use Try::Tiny;
use strict;
use warnings;

sub valid_params {
    return qw(
      backup_ttl
      check_only
      conf_file
      data_dir
      mode
      no_backups
      no_cache
      output_suffix
      plugins
      postfilter
      prefilter
      quiet
      refresh_cache
      root_dir
      verbose
    );
}
my %valid_params_hash;

# Incoming parameters
use Object::Tiny ( valid_params() );

# Internal
use Object::Tiny qw(
  backup_dir
  base_sig
  cache
  matched_files
  plugin_objects
);

my $ini_name = 'tidyall.ini';

sub new {
    my $class  = shift;
    my %params = @_;

    # Read params from conf file
    #
    if ( my $conf_file = delete( $params{conf_file} ) ) {
        my $conf_params = $class->_read_conf_file($conf_file);
        my $main_params = delete( $conf_params->{'_'} ) || {};
        %params = (
            plugins  => $conf_params,
            root_dir => realpath( dirname($conf_file) ),
            %$main_params, %params
        );
    }
    else {
        die "conf_file or plugins required"  unless $params{plugins};
        die "conf_file or root_dir required" unless $params{root_dir};
        $params{root_dir} = realpath( $params{root_dir} );
    }

    # Initialize with alternate class if given
    #
    if ( my $tidyall_class = delete( $params{tidyall_class} ) ) {
        die "cannot load '$tidyall_class'" unless can_load($tidyall_class);
        return $tidyall_class->new(%params);
    }

    # Check param validity
    #
    my $valid_params_hash = $valid_params_hash{$class} ||=
      { map { ( $_, 1 ) } $class->valid_params() };
    if ( my @bad_params = grep { !$valid_params_hash->{$_} } keys(%params) ) {
        die sprintf( "unknown constructor param(s) %s",
            join( ", ", sort map { "'$_'" } @bad_params ) );
    }

    $class->msg( "constructing %s with these params: %s", $class, dump_one_line( \%params ) )
      if ( $params{verbose} );

    my $self = $class->SUPER::new(%params);

    $self->{data_dir} ||= $self->root_dir . "/.tidyall.d";
    $self->{output_suffix} ||= '';

    unless ( $self->no_cache ) {
        $self->{cache} = Code::TidyAll::Cache->new( cache_dir => $self->data_dir . "/cache" );
    }

    unless ( $self->no_backups ) {
        $self->{backup_dir} = $self->data_dir . "/backups";
        mkpath( $self->backup_dir, 0, 0775 );
        $self->{backup_ttl} ||= '1 hour';
        $self->{backup_ttl} = parse_duration( $self->{backup_ttl} )
          unless $self->{backup_ttl} =~ /^\d+$/;
        $self->_purge_backups_periodically();
    }

    if ( my $mode = $self->mode ) {
        $self->{plugins} =
          { grepp { $b->{modes} && ( " " . $b->{modes} . " " =~ /$mode/ ) } %{ $self->plugins } };
    }

    $self->{base_sig} = $self->_sig( [ $Code::TidyAll::VERSION || 0 ] );
    $self->{plugin_objects} =
      [ map { $self->_load_plugin( $_, $self->plugins->{$_} ) } sort keys( %{ $self->plugins } ) ];
    $self->{matched_files} = $self->_find_matched_files;

    return $self;
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
        conf => $plugin_conf,
        name => $plugin_name
    );
}

sub process_all {
    my $self = shift;

    return $self->process_files( sort keys( %{ $self->matched_files } ) );
}

sub process_files {
    my ( $self, @files ) = @_;

    my $error_count = 0;
    my @results;
    foreach my $file (@files) {
        $file = realpath($file);
        push( @results, $self->process_file($file) );
    }
    return @results;
}

sub process_file {
    my ( $self, $file ) = @_;

    my @plugins = @{ $self->matched_files->{$file} || [] };
    my $small_path = $self->_small_path($file);
    if ( !@plugins ) {
        $self->msg( "[no plugins apply] %s", $small_path ) unless $self->quiet;
        return Code::TidyAll::Result->new( file => $file, state => 'no_match' );
    }

    my $cache     = $self->cache;
    my $cache_key = "sig/$small_path";
    my $error;
    my $contents = my $orig_contents = read_file($file);
    if ( $cache && ( my $sig = $cache->get($cache_key) ) ) {
        if ( $self->refresh_cache ) {
            $cache->remove($cache_key);
        }
        else {
            return Code::TidyAll::Result->new( file => $file, state => 'cached' )
              if $sig eq $self->_file_sig( $file, $orig_contents );
        }
    }

    $contents = $self->prefilter->($contents) if $self->prefilter;
    foreach my $plugin (@plugins) {
        try {
            my $new_contents = $plugin->process_source_or_file( $contents, $file );
            if ( $new_contents ne $contents ) {
                die "needs tidying\n" if $self->check_only;
                $contents = $new_contents;
            }
        }
        catch {
            $error = sprintf( "*** '%s': %s", $plugin->name, $_ );
        };
        last if $error;
    }
    $contents = $self->postfilter->($contents) if !$error && $self->postfilter;

    my $was_tidied = ( $contents ne $orig_contents ) && !$error;
    unless ( $self->quiet ) {
        my $status = $was_tidied ? "[tidied]  " : "[checked] ";
        my $plugin_names =
          $self->verbose ? sprintf( " (%s)", join( ", ", map { $_->name } @plugins ) ) : "";
        $self->msg( "%s%s%s", $status, $small_path, $plugin_names );
    }

    if ($was_tidied) {
        $self->_backup_file( $file, $orig_contents );
        write_file( join( '', $file, $self->output_suffix ), $contents );
    }

    if ($error) {
        $self->msg( "%s", $error );
        return Code::TidyAll::Result->new( file => $file, state => 'error', msg => $error );
    }
    else {
        $cache->set( $cache_key, $self->_file_sig( $file, $contents ) ) if $cache;
        my $state = $was_tidied ? 'tidied' : 'checked';
        return Code::TidyAll::Result->new( file => $file, state => $state );
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
    my ( $self, $file, $contents ) = @_;
    unless ( $self->no_backups ) {
        my $backup_file = join( "/", $self->backup_dir, $self->_backup_filename($file) );
        mkpath( dirname($backup_file), 0, 0775 );
        write_file( $backup_file, $contents );
    }
}

sub _backup_filename {
    my ( $self, $file ) = @_;

    return join( "", $self->_small_path($file), "-", time2str( "%Y%m%d-%H%M%S", time ), ".bak" );
}

sub _purge_backups_periodically {
    my ($self) = @_;
    if ( my $cache = $self->cache ) {
        my $last_purge_backups = $cache->get("last_purge_backups") || 0;
        if ( time > $last_purge_backups + $self->backup_ttl ) {
            $self->_purge_backups();
            $cache->set( "last_purge_backups", time() );
        }
    }
}

sub _purge_backups {
    my ($self) = @_;
    $self->msg("purging old backups") if $self->verbose;
    find(
        {
            follow => 0,
            wanted => sub {
                unlink $_ if -f && /\.bak$/ && time > ( stat($_) )[9] + $self->backup_ttl;
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

sub _find_matched_files {
    my ($self) = @_;

    my %matched_files;
    foreach my $plugin ( @{ $self->plugin_objects } ) {
        my @selected = grep { -f && !-l } $self->_zglob( $plugin->select );
        if ( defined( $plugin->ignore ) ) {
            my %is_ignored = map { ( $_, 1 ) } $self->_zglob( $plugin->ignore );
            @selected = grep { !$is_ignored{$_} } @selected;
        }
        foreach my $file (@selected) {
            $matched_files{$file} ||= [];
            push( @{ $matched_files{$file} }, $plugin );
        }
    }
    return \%matched_files;
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

sub msg {
    my ( $self, $format, @params ) = @_;
    printf "$format\n", @params;
}

1;



=pod

=head1 NAME

Code::TidyAll - Engine for tidyall, your all-in-one code tidier and validator

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Code::TidyAll;

    my $ct = Code::TidyAll->new(
        conf_file => '/path/to/conf/file'
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

=head1 CONSTRUCTOR OPTIONS

You must either pass C<conf_file>, or both C<plugins> and C<root_dir>.

=over

=item plugins

Specify a hash of plugins, each of which is itself a hash of options. This is
equivalent to what would be parsed out of the sections in C<tidyall.ini>.

=item prefilter

A code reference that will be applied to code before processing. It is expected
to take the full content as a string in its input, and output the transformed
content.

=item postfilter

A code reference that will be applied to code after processing. It is expected
to take the full content as a string in its input, and output the transformed
content.

=item backup_ttl

=item check_only

=item conf_file

=item data_dir

=item mode

=item no_backups

=item no_cache

=item root_dir

=item quiet

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

Calls L</process_file> on each file. Return a list of
L<Code::TidyAll::Result|Code::TidyAll::Result> objects, one for each file.

=item process_file (file)

Process the file, meaning

=over

=item *

Check the cache and return immediately if file has not changed

=item *

Apply prefilters, appropriate matching plugins, and postfilters

=item *

Print success or failure result to STDOUT, depending on quiet/verbose settings

=item *

Write the cache if enabled

=item *

Return a L<Code::TidyAll::Result|Code::TidyAll::Result> object

=back

=item find_conf_file (start_dir)

Start in the I<start_dir> and work upwards, looking for a C<tidyall.ini>.
Return the pathname if found or throw an error if not found.

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

