package Code::TidyAll::t::Util;
BEGIN {
  $Code::TidyAll::t::Util::VERSION = '0.12';
}
use Code::TidyAll::Util qw(dirname tempdir_simple);
use IPC::System::Simple qw(capturex);
use Test::Class::Most parent => 'Code::TidyAll::Test::Class';

sub test_tempdir_simple : Tests {
    return "author testing only" unless ( $ENV{AUTHOR_TESTING} );

    my $dir = capturex(
        "$^X", "-I",
        "lib", "-MCode::TidyAll::Util",
        "-e",  "print Code::TidyAll::Util::tempdir_simple "
    );
    ok( -d dirname($dir), "parent exists" );
    ok( !-d $dir,         "dir does not exist" );
}

1;