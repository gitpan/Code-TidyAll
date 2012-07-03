package Code::TidyAll::Plugin::PerlCritic;
BEGIN {
  $Code::TidyAll::Plugin::PerlCritic::VERSION = '0.02';
}
use Perl::Critic::Command qw();
use Capture::Tiny qw(capture_merged);
use strict;
use warnings;
use base qw(Code::TidyAll::Plugin);

sub validate_file {
    my ( $self, $file ) = @_;
    my $options = $self->options;

    # Determine arguments
    #
    my @argv = split( /\s/, $options->{argv} || '' );
    push( @argv, $file );

    # Run perlcritic
    #
    local @ARGV = @argv;
    my $output = capture_merged { Perl::Critic::Command::run() };
    die $output if $output !~ /^.* source OK\n/;
}

1;



=pod

=head1 NAME

Code::TidyAll::Plugin::PerlCritic - use perlcritic with tidyall

=head1 VERSION

version 0.02

=head1 SYNOPSIS

   # In tidyall.ini:

   # Configure in-line
   #
   [PerlCritic]
   argv = --severity 5 --exclude=nowarnings
   select = lib/**/*.pm

   # or refer to a .perlcriticrc in the same directory
   #
   [PerlCritic]
   argv = --profile $ROOT/.perlcriticrc
   select = lib/**/*.pm

=head1 OPTIONS

=over

=item argv

Arguments to pass to perlcritic.

=back

=head1 SEE ALSO

L<Code::TidyAll|Code::TidyAll>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

