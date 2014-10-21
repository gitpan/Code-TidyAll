package Code::TidyAll::t::Plugin::PerlTidy;
{
  $Code::TidyAll::t::Plugin::PerlTidy::VERSION = '0.17';
}
use Test::Class::Most parent => 'Code::TidyAll::t::Plugin';

sub test_main : Tests {
    my $self = shift;

    my $source = 'if (  $foo) {\nmy   $bar =  $baz;\n}\n';
    $self->tidyall(
        source      => $source,
        expect_tidy => 'if ($foo) {\n    my $bar = $baz;\n}\n'
    );
    $self->tidyall(
        conf        => { argv => '-bl' },
        source      => $source,
        expect_tidy => 'if ($foo)\n{\n    my $bar = $baz;\n}\n'
    );
    $self->tidyall(
        source    => 'if ($foo) {\n    my $bar = $baz;\n}\n',
        expect_ok => 1
    );
    $self->tidyall(
        source       => 'if ($foo) {\n    my $bar = $baz;\n',
        expect_error => qr/Final nesting depth/
    );
    $self->tidyall(
        conf         => { argv => '--badoption' },
        source       => $source,
        expect_error => qr/Unknown option: badoption/
    );
}

1;
