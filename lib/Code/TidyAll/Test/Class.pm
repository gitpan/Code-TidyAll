package Code::TidyAll::Test::Class;
BEGIN {
  $Code::TidyAll::Test::Class::VERSION = '0.11';
}
use Test::Class::Most;
use strict;
use warnings;

__PACKAGE__->SKIP_CLASS("abstract base class");

1;
