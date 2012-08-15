package Code::TidyAll::Plugin::PodTidy;
BEGIN {
  $Code::TidyAll::Plugin::PodTidy::VERSION = '0.04';
}
use Capture::Tiny qw(capture_merged);
use Hash::MoreUtils qw(slice_exists);
use Pod::Tidy;
use strict;
use warnings;
use base qw(Code::TidyAll::Plugin);

sub transform_file {
    my ( $self, $file ) = @_;
    my $options = $self->options;

    my %params = slice_exists( $self->options, qw(columns) );
    my $output = capture_merged {
        Pod::Tidy::tidy_files(
            %params,
            files    => [$file],
            inplace  => 1,
            nobackup => 1,
            verbose  => 1,
        );
    };
    die $output if $output =~ /\S/ && $output !~ /does not contain Pod/;
}

1;



=pod

=head1 NAME

Code::TidyAll::Plugin::PodTidy - use podtidy with tidyall

=head1 VERSION

version 0.04

=head1 SYNOPSIS

   # In tidyall.ini:

   [PodTidy]
   argv = --column=90
   select = lib/**/*.{pm,pod}

=head1 OPTIONS

=over

=item argv

Arguments to pass to podtidy.

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

