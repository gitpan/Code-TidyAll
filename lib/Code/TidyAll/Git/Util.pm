package Code::TidyAll::Git::Util;
{
  $Code::TidyAll::Git::Util::VERSION = '0.17';
}
use Cwd qw(realpath);
use Code::TidyAll::Util qw(pushd uniq);
use IPC::System::Simple qw(capturex);
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(git_uncommitted_files);

sub git_uncommitted_files {
    my ($dir) = @_;

    $dir = realpath($dir);
    my $pushd  = pushd($dir);
    my $output = capturex( "git", "status" );
    my @files  = ( $output =~ /(?:new file|modified):\s+(.*)/g );
    @files = uniq( map { "$dir/$_" } @files );
    return @files;
}

1;
