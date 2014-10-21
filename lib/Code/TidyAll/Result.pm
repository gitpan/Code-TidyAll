package Code::TidyAll::Result;
{
  $Code::TidyAll::Result::VERSION = '0.17';
}
use Moo;

has 'error'        => ( is => 'ro' );
has 'new_contents' => ( is => 'ro' );
has 'path'         => ( is => 'ro' );
has 'state'        => ( is => 'ro' );

sub ok { return $_[0]->state ne 'error' }

1;

__END__

=pod

=head1 NAME

Code::TidyAll::Result - Result returned from processing a file/source

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    my $ct = Code::TidyAll->new(...);
    my $result = $ct->process_file($file);
    if ($result->error) {
       ...
    }

=head1 DESCRIPTION

Represents the result of
L<Code::TidyAll::process_file|Code::TidyAll/process_file> and
L<Code::TidyAll::process_file|Code::TidyAll/process_source>. A list of these is
returned from L<Code::TidyAll::process_paths|Code::TidyAll/process_paths>.

=head1 METHODS

=over

=item path

The path that was processed, relative to the root (e.g. "lib/Foo.pm")

=item state

A string, one of

=over

=item C<no_match> - No plugins matched this file

=item C<cached> - Cache hit (file had not changed since last processed)

=item C<error> - An error occurred while applying one of the plugins

=item C<checked> - File was successfully checked and did not change

=item C<tidied> - File was successfully checked and changed

=back

=item new_contents

Contains the new contents if state is 'tidied'

=item error

Contains the error message if state is 'error'

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
