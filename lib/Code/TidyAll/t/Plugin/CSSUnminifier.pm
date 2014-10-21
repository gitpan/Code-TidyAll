package Code::TidyAll::t::Plugin::CSSUnminifier;
{
  $Code::TidyAll::t::Plugin::CSSUnminifier::VERSION = '0.17';
}
use Test::Class::Most parent => 'Code::TidyAll::t::Plugin';

sub test_main : Tests {
    my $self = shift;

    my $source = 'body {\nfont-family:helvetica;\nfont-size:15pt;\n}';
    $self->tidyall(
        source      => $source,
        expect_tidy => 'body {\n    font-family: helvetica;\n    font-size: 15pt;\n}\n'
    );
    $self->tidyall(
        source      => $source,
        conf        => { argv => '-w=2' },
        expect_tidy => 'body {\n  font-family: helvetica;\n  font-size: 15pt;\n}\n'
    );
}

1;
