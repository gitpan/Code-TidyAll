package Code::TidyAll::Test::Plugin::UpperText;
BEGIN {
  $Code::TidyAll::Test::Plugin::UpperText::VERSION = '0.01';
}
use base qw(Code::TidyAll::Plugin);
use strict;
use warnings;

sub process_source {
    my ( $self, $source ) = @_;
    if ( $source =~ /^[A-Z]*$/i ) {
        return uc($source);
    }
    else {
        die "non-alpha content found";
    }
}

1;
