package Code::TidyAll::Plugin::JSON;
$Code::TidyAll::Plugin::JSON::VERSION = '0.21';
use strict;
use warnings;

use JSON ();
use Moo;

extends 'Code::TidyAll::Plugin';

has 'ascii' => ( is => 'ro', default => sub { 0 } );

sub transform_source {
    my $self   = shift;
    my $source = shift;

    my $json = JSON->new->utf8->relaxed->pretty->canonical;

    $json = $json->ascii if $self->ascii;

    return $json->encode( $json->decode($source) );
}

1;

# ABSTRACT: Use the JSON module to tidy JSON documents with tidyall

__END__

=pod

=head1 VERSION

version 0.21

=head1 SYNOPSIS

   In configuration:

   [JSON]
   select = **/*.json
   ascii = 1

=head1 DESCRIPTION

Uses L<JSON> to format JSON files. Files are put into a canonical format with
the keys of objects sorted.

=head1 CONFIGURATION

=over

=item ascii

Escape non-ASCII characters. The output file will be valid ASCII.

=back

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
