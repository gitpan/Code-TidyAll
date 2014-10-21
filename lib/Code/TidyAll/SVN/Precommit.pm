package Code::TidyAll::SVN::Precommit;
{
  $Code::TidyAll::SVN::Precommit::VERSION = '0.17';
}
use Capture::Tiny qw(capture_stdout capture_stderr);
use Code::TidyAll;
use Code::TidyAll::Util qw(basename dirname mkpath realpath tempdir_simple write_file);
use Log::Any qw($log);
use Moo;
use SVN::Look;
use Try::Tiny;

# Public
has 'conf_name'                => ( is => 'ro' );
has 'emergency_comment_prefix' => ( is => 'ro', default => sub { "NO TIDYALL" } );
has 'extra_conf_files'         => ( is => 'ro', default => sub { [] } );
has 'reject_on_error'          => ( is => 'ro' );
has 'repos'                    => ( is => 'ro', default => sub { $ARGV[0] } );
has 'tidyall_class'            => ( is => 'ro', default => sub { "Code::TidyAll" } );
has 'tidyall_options'          => ( is => 'ro', default => sub { {} } );
has 'txn'                      => ( is => 'ro', default => sub { $ARGV[1] } );

# Private
has 'cat_file_cache' => ( init_arg => undef, is => 'ro', default => sub { {} } );
has 'revlook'        => ( init_arg => undef, is => 'lazy' );

sub _build_revlook {
    my $self = shift;
    return SVN::Look->new( $self->repos, '-t' => $self->txn );
}

sub check {
    my ( $class, %params ) = @_;

    my $fail_msg;

    try {
        my $self    = $class->new(%params);
        my $revlook = $self->revlook;

        # Skip if emergency comment prefix is present
        #
        if ( my $prefix = $self->emergency_comment_prefix ) {
            if ( index( $revlook->log_msg, $prefix ) == 0 ) {
                return;
            }
        }

        my @files = ( $self->revlook->added(), $self->revlook->updated() );
        $log->info("----------------------------");
        $log->infof(
            "%s [%s] repos = %s; txn = %s",
            scalar(localtime), $$, scalar( getpwuid($<) ),
            $self->repos, $self->txn
        );
        $log->infof( "looking at files: %s", join( ", ", @files ) );

        my %conf_files;
        foreach my $file (@files) {
            if ( my $conf_file = $self->find_conf_for_file($file) ) {
                my $root = dirname($conf_file);
                my $rel_file = substr( $file, length($root) + 1 );
                $conf_files{$conf_file}->{$rel_file}++;
            }
            else {
                my $msg = sprintf( "** could not find conf file upwards from '%s'", $file );
                $log->error($msg);
                die $msg if $self->reject_on_error;
            }
        }

        my @results;
        while ( my ( $conf_file, $file_map ) = each(%conf_files) ) {
            my $root      = dirname($conf_file);
            my $conf_name = basename($conf_file);
            $log->error("$root, $conf_file");
            my $tempdir = tempdir_simple();
            my @files   = keys(%$file_map);
            foreach my $rel_file ( $conf_name, @{ $self->extra_conf_files }, @files ) {

                # TODO: what if cat fails
                my $contents  = $self->cat_file("$root/$rel_file");
                my $full_path = "$tempdir/$rel_file";
                mkpath( dirname($full_path), 0, 0775 );
                write_file( $full_path, $contents );
            }
            my $tidyall = $self->tidyall_class->new_from_conf_file(
                join( "/", $tempdir, $conf_name ),
                no_cache   => 1,
                check_only => 1,
                mode       => 'commit',
                %{ $self->tidyall_options },
            );
            my $stdout = capture_stdout {
                push( @results, $tidyall->process_paths( map { "$tempdir/$_" } @files ) );
            };
            if ($stdout) {
                chomp($stdout);
                $log->info($stdout);
            }
        }

        if ( my @error_results = grep { $_->error } @results ) {
            my $error_count = scalar(@error_results);
            $fail_msg = join(
                "\n",
                sprintf(
                    "%d file%s did not pass tidyall check",
                    $error_count, $error_count > 1 ? "s" : ""
                ),
                map { join( ": ", $_->path, $_->error ) } @error_results
            );
        }
    }
    catch {
        my $error = $_;
        $log->error($error);
        die $error if $params{reject_on_error};
    };
    die $fail_msg if $fail_msg;
}

sub find_conf_for_file {
    my ( $self, $file ) = @_;

    my @conf_names = $self->conf_name ? ( $self->conf_name ) : Code::TidyAll->default_conf_names;
    my $search_dir = dirname($file);
    $search_dir =~ s{/+$}{};
    my $cnt = 0;
    while (1) {
        foreach my $conf_name (@conf_names) {
            my $conf_file = "$search_dir/$conf_name";
            return $conf_file if ( $self->cat_file($conf_file) );
        }
        if ( $search_dir eq '/' || $search_dir eq '' || $search_dir eq '.' ) {
            return undef;
        }
        else {
            $search_dir = dirname($search_dir);
        }
        die "inf loop!" if ++$cnt > 100;
    }
}

sub cat_file {
    my ( $self, $file ) = @_;
    my $contents;
    if ( exists( $self->cat_file_cache->{$file} ) ) {
        $contents = $self->cat_file_cache->{$file};
    }
    else {
        try {
            capture_stderr { $contents = $self->revlook->cat($file) };
        }
        catch {
            $contents = '';
        };
        $self->cat_file_cache->{$file} = $contents;
    }
    return $contents;
}

1;

__END__

=pod

=head1 NAME

Code::TidyAll::SVN::Precommit - Subversion pre-commit hook that requires files
to be tidyall'd

=head1 VERSION

version 0.17

=head1 SYNOPSIS

  In hooks/pre-commit in your svn repo:

    #!/usr/bin/perl
    use Code::TidyAll::SVN::Precommit;
    use Log::Any::Adapter (File => "/path/to/hooks/logs/tidyall.log");
    use strict;
    use warnings;
    
    Code::TidyAll::SVN::Precommit->check();

=head1 DESCRIPTION

This module implements a L<Subversion pre-commit
hook|http://svnbook.red-bean.com/en/1.7/svn.ref.reposhooks.pre-commit.html>
that checks if all files are tidied and valid according to L<tidyall|tidyall>,
and rejects the commit if not.

=head1 METHODS

=over

=item check (key/value params...)

Class method. Check that all files being added or modified in this commit are
tidied and valid according to L<tidyall|tidyall>. If not, then the entire
commit is rejected and the reason(s) are output to the client. e.g.

    % svn commit -m "fixups" CHI.pm CHI/Driver.pm 
    Sending        CHI/Driver.pm
    Sending        CHI.pm
    Transmitting file data ..svn: Commit failed (details follow):
    svn: Commit blocked by pre-commit hook (exit code 255) with output:
    2 files did not pass tidyall check
    lib/CHI.pm: *** 'PerlTidy': needs tidying
    lib/CHI/Driver.pm: *** 'PerlCritic': Code before strictures are enabled
      at /tmp/Code-TidyAll-0e6K/Driver.pm line 2
      [TestingAndDebugging::RequireUseStrict]

In an emergency the hook can be bypassed by prefixing the comment with "NO
TIDYALL", e.g.

    % svn commit -m "NO TIDYALL - this is an emergency!" CHI.pm CHI/Driver.pm 
    Sending        CHI/Driver.pm
    Sending        CHI.pm
    Transmitting file data .                                                              
    Committed revision 7562.  

The configuration file (C<tidyall.ini> or C<.tidyallrc>) must be checked into
svn. For each file, the hook will look upwards from the file's repo location
and use the first configuration file it finds.

By default, if the configuration file cannot be found, or if a runtime error
occurs, a warning is logged (see L</LOGGING> below) but the commit is allowed
to proceed. This is so that unexpected problems do not prevent valid commits.

Passes mode = "commit" by default; see L<modes|tidyall/MODES>.

Key/value parameters:

=over

=item conf_name

Conf file name to search for instead of the defaults.

=item emergency_comment_prefix

Commit prefix that will cause this hook to be bypassed. Defaults to "NO
TIDYALL". e.g.

    svn commit -m "NO TIDYALL - must get fix to production!"

Set to a false value (e.g. blank or undefined) to disable bypassing.

=item extra_conf_files

A listref of other configuration files referred to from the main configuration
file, e.g.

    extra_conf_files => ['perlcriticrc', 'perltidyrc']

If you don't list them here then you'll get errors like 'cannot find
perlcriticrc' when the hook runs.

=item reject_on_error

If the configuration file cannot be found for some/all the files, or if a
runtime error occurs, reject the commit.

=item repos

Repository path being committed; defaults to C<< $ARGV[0] >>

=item tidyall_class

Subclass to use instead of L<Code::TidyAll|Code::TidyAll>

=item tidyall_options

Hashref of options to pass to the L<Code::TidyAll|Code::TidyAll> constructor

=item txn

Commit transaction; defaults to C<< $ARGV[1] >>

=back

=back

=head1 LOGGING

This module uses L<Log::Any|Log::Any> to log its activity, including all files
that were checked, an inability to find the configuration file, and any runtime
errors that occur. You can create a simple date-stamped log file with

    use Log::Any::Adapter (File => "/path/to/hooks/logs/tidyall.log");

or do something fancier with one of the other L<Log::Any
adapters|Log::Any::Adapter>.

Having a log file is especially useful with pre-commit hooks since there is no
way for the hook to send back output on a successful commit.

=head1 ACKNOWLEDGMENTS

Thanks to Alexander Simakov, author of
L<perlcritic-checker|http://search.cpan.org/~xdr/perlcritic-checker-1.2.6/>,
for some of the ideas here such as emergency_comment_prefix.

=head1 SEE ALSO

L<Code::TidyAll|Code::TidyAll>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
