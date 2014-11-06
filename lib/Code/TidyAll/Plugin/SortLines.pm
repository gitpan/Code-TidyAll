package Code::TidyAll::Plugin::SortLines;
$Code::TidyAll::Plugin::SortLines::VERSION = '0.24';
use Moo;
extends 'Code::TidyAll::Plugin';

sub transform_source {
    my ( $self, $source ) = @_;

    return join( "\n", sort( grep { /\S/ } split( /\n/, $source ) ) ) . "\n";
}

1;

# ABSTRACT: Sort the lines in a file

__END__

=pod

=head1 VERSION

version 0.24

=head1 SYNOPSIS

   # In configuration:

   [SortLines]
   select = .ispell* **/.gitignore

=head1 DESCRIPTION

Sorts the lines of a file; whitespace lines are discarded. Useful for files
containing one entry per line, such as C<.svnignore>, C<.gitignore>, and
C<.ispell*>.

=head1 SEE ALSO

L<Code::TidyAll>

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2014 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
