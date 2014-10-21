package Code::TidyAll::Util;
{
  $Code::TidyAll::Util::VERSION = '0.17';
}
use Cwd qw(realpath);
use Data::Dumper;
use File::Basename;
use File::Path;
use File::Spec::Functions qw(abs2rel rel2abs);
use File::Temp qw(tempdir);
use Guard;
use List::MoreUtils qw(uniq);
use Try::Tiny;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK =
  qw(abs2rel basename can_load dirname dump_one_line mkpath pushd read_dir read_file realpath rel2abs tempdir_simple trim uniq write_file);

sub can_load {

    # Load $class_name if possible. Return 1 if successful, 0 if it could not be
    # found, and rethrow load error (other than not found).
    #
    my ($class_name) = @_;

    my $result;
    try {
        eval "require $class_name";    ## no critic
        die $@ if $@;
        $result = 1;
    }
    catch {
        if ( /Can\'t locate .* in \@INC/ && !/Compilation failed/ ) {
            $result = 0;
        }
        else {
            die $_;
        }
    };
    return $result;
}

sub tempdir_simple {
    my $template = shift || 'Code-TidyAll-XXXX';
    return realpath( tempdir( $template, TMPDIR => 1, CLEANUP => 1 ) );
}

sub dump_one_line {
    my ($value) = @_;

    return Data::Dumper->new( [$value] )->Indent(0)->Sortkeys(1)->Quotekeys(0)->Terse(1)->Dump();
}

sub pushd {
    my ($dir) = @_;

    my $cwd = realpath();
    chdir($dir);
    return guard { chdir($cwd) };
}

sub trim {
    my ($str) = @_;
    for ($str) { s/^\s+//; s/\s+$// }
    return $str;
}

sub read_dir {
    my ($dir) = @_;
    opendir( my $dirh, $dir ) or die "could not open $dir: $!";
    my @dir_entries = grep { $_ ne "." && $_ ne ".." } readdir($dirh);
    return @dir_entries;
}

sub read_file {
    my ($file) = @_;
    open( my $fh, "<", $file ) or die "could not open $file: $!";
    my $contents = do { local $/; <$fh> };
    return $contents;
}

sub write_file {
    my ( $file, $contents ) = @_;
    open( my $fh, ">", $file ) or die "could not open $file: $!";
    print $fh $contents;
}

1;
