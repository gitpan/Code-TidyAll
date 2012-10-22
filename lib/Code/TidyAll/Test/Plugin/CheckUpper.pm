package Code::TidyAll::Test::Plugin::CheckUpper;
BEGIN {
  $Code::TidyAll::Test::Plugin::CheckUpper::VERSION = '0.16';
}
use Moo;
extends 'Code::TidyAll::Plugin';

sub validate_source {
    my ( $self, $source ) = @_;
    die "lowercase found" if $source =~ /[a-z]/;
}

1;
