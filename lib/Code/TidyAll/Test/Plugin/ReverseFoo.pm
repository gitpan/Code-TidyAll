package Code::TidyAll::Test::Plugin::ReverseFoo;
BEGIN {
  $Code::TidyAll::Test::Plugin::ReverseFoo::VERSION = '0.08';
}
use Code::TidyAll::Util qw(read_file write_file);
use Moo;
extends 'Code::TidyAll::Plugin';

sub transform_file {
    my ( $self, $file ) = @_;
    write_file( $file, scalar( reverse( read_file($file) ) ) );
}

1;
