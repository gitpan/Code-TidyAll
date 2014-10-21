package Code::TidyAll::t::Plugin::JSHint;
{
  $Code::TidyAll::t::Plugin::JSHint::VERSION = '0.17';
}
use Code::TidyAll::Util qw(write_file);
use Test::Class::Most parent => 'Code::TidyAll::t::Plugin';

sub test_filename { 'foo.js' }

sub test_main : Tests {
    my $self = shift;

    my $rc_file = $self->{root_dir} . "/jshint.json";

    $self->tidyall(
        source    => 'var my_object = {};',
        expect_ok => 1,
        desc      => 'ok - camelcase',
    );
    $self->tidyall(
        source    => 'while (day)\n  shuffle();',
        expect_ok => 1,
        desc      => 'ok no brace',
    );
    $self->tidyall(
        source       => 'var my_object = new Object();',
        expect_error => qr/object literal notation/,
        desc         => 'error - object literal',
    );
    $self->tidyall(
        source       => 'var my_object = {};',
        conf         => { options => 'camelcase' },
        expect_error => qr/not in camel case/,
        desc         => 'error - camel case - options=camelcase',
    );
    $self->tidyall(
        source       => 'var my_object = {};',
        conf         => { options => 'camelcase curly' },
        expect_error => qr/not in camel case/,
        desc         => 'error - camel case - options=camelcase,curly',
    );
    $self->tidyall(
        source       => 'while (day)\n  shuffle();',
        conf         => { options => 'camelcase curly' },
        expect_error => qr/Expected \'{/,
        desc         => 'error - curly - options=camelcase,curly',
    );
    write_file( $rc_file, '{"camelcase": true}' );
    $self->tidyall(
        source       => 'var my_object = {};',
        conf         => { argv => "--config $rc_file" },
        expect_error => qr/not in camel case/,
        desc         => 'error - camelcase - conf file',
    );
    $self->tidyall(
        source       => 'var my_object = {};',
        conf         => { argv => "--badoption" },
        expect_error => qr/Unknown option/,
        desc         => 'error - bad option'
    );
}

1;
