package Code::TidyAll::t::Plugin::JSLint;
{
  $Code::TidyAll::t::Plugin::JSLint::VERSION = '0.17';
}
use Code::TidyAll::Util qw(write_file);
use Test::Class::Most parent => 'Code::TidyAll::t::Plugin';

sub test_filename { 'foo.js' }

sub test_main : Tests {
    my $self = shift;

    $self->tidyall(
        source    => 'var my_object = {};',
        expect_ok => 1,
        desc      => 'ok',
    );
    $self->tidyall(
        source       => 'while (true) {\nvar i = 5;\n}',
        expect_error => qr/Expected 'var' at column 5/,
        desc         => 'error - bad indentation'
    );
    $self->tidyall(
        source    => 'while (true) {\nvar i = 5;\n}',
        conf      => { argv => '--white' },
        expect_ok => 1,
        desc      => 'ok - bad indentation, --white'
    );
    $self->tidyall(
        source       => 'var my_object = {};',
        conf         => { argv => '--badoption' },
        expect_error => qr/Usage/,
        desc         => 'error - bad option'
    );
}

1;
