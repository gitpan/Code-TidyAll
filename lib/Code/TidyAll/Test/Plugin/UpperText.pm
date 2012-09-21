package Code::TidyAll::Test::Plugin::UpperText;
BEGIN {
  $Code::TidyAll::Test::Plugin::UpperText::VERSION = '0.11';
}
use Moo;
extends 'Code::TidyAll::Plugin';

sub transform_source {
    my ( $self, $source ) = @_;
    if ( $source =~ /^[A-Z]*$/i ) {
        return uc($source);
    }
    else {
        die "non-alpha content found";
    }
}

1;
