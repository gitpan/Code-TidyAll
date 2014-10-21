package Code::TidyAll::Result;
BEGIN {
  $Code::TidyAll::Result::VERSION = '0.02';
}
use strict;
use warnings;

use Object::Tiny qw(msg state);

sub error { return $_[0]->state eq 'error' }
sub ok { return $_[0]->state ne 'error' }

1;



=pod

=head1 NAME

Code::TidyAll::Result - Result returned from Code::TidyAll::process_file

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $ct = Code::TidyAll->new(...);
    my $result = $ct->process_file($file);
    if ($result->error) {
       ...
    }

=head1 DESCRIPTION

Represents the result of
L<Code::TidyAll::process_file|Code::TidyAll/process_file>. A list of these is
returned from L<Code::TidyAll::process_files|Code::TidyAll/process_files>.

=head1 METHODS

=over

=item state

A string, one of

=over

=item C<no_match> - No plugins matched this file

=item C<cached> - Cache hit (file had not changed since last processed)

=item C<error> - An error occurred while applying one of the plugins

=item C<checked> - File was successfully checked and did not change

=item C<tidied> - File was successfully checked and changed

=back

=item error

Returns true iff state is 'error'

=item ok

Returns true iff state is not 'error'

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

