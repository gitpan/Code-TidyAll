package Code::TidyAll::Test::Plugin::ReverseFoo;
BEGIN {
  $Code::TidyAll::Test::Plugin::ReverseFoo::VERSION = '0.04';
}
use Code::TidyAll::Util qw(read_file write_file);
use base qw(Code::TidyAll::Plugin);
use strict;
use warnings;

sub transform_file {
    my ( $self, $file ) = @_;
    write_file( $file, scalar( reverse( read_file($file) ) ) );
}

1;
