package Code::TidyAll::Plugin::PerlTidy;
BEGIN {
  $Code::TidyAll::Plugin::PerlTidy::VERSION = '0.10';
}
use Perl::Tidy;
use Moo;
extends 'Code::TidyAll::Plugin';

sub transform_source {
    my ( $self, $source ) = @_;

    my $errorfile;
    no strict 'refs';
    Perl::Tidy::perltidy(
        argv        => $self->argv,
        source      => \$source,
        destination => \my $destination,
        errorfile   => \$errorfile
    );
    die $errorfile if $errorfile;
    return $destination;
}

1;



=pod

=head1 NAME

Code::TidyAll::Plugin::PerlTidy - use perltidy with tidyall

=head1 VERSION

version 0.10

=head1 SYNOPSIS

   # In tidyall.ini:

   ; Configure in-line
   ;
   [PerlTidy]
   argv = --noll
   select = lib/**/*.pm

   ; or refer to a .perltidyrc in the same directory
   ;
   [PerlTidy]
   argv = --profile=$ROOT/.perltidyrc
   select = lib/**/*.pm

=head1 DESCRIPTION

Runs L<perltidy|perltidy>, a Perl tidier.

=head1 INSTALLATION

Install perltidy from CPAN.

    cpanm perltidy

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to perltidy

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

