package Code::TidyAll::Test::Plugin::RepeatFoo;
BEGIN {
  $Code::TidyAll::Test::Plugin::RepeatFoo::VERSION = '0.05';
}
use Code::TidyAll::Util qw(read_file write_file);
use base qw(Code::TidyAll::Plugin);
use strict;
use warnings;

sub transform_source {
    my ( $self, $source ) = @_;
    my $times = $self->options->{times} || die "no times specified";
    return $source x $times;
}

1;
