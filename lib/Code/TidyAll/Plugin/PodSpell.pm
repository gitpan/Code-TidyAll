package Code::TidyAll::Plugin::PodSpell;
{
  $Code::TidyAll::Plugin::PodSpell::VERSION = '0.17';
}
use Code::TidyAll::Util qw(basename uniq);
use Capture::Tiny qw();
use IPC::System::Simple qw();
use IPC::Run3;
use Pod::Spell;
use Moo;
use Text::ParseWords qw(shellwords);
extends 'Code::TidyAll::Plugin';

has 'ispell_argv' => ( is => 'ro', default => sub { '' } );
has 'ispell_cmd'  => ( is => 'ro', default => sub { 'ispell' } );
has 'suggest'     => ( is => 'ro' );

sub validate_file {
    my ( $self, $file ) = @_;

    my ( $text, $error ) = Capture::Tiny::capture { Pod::Spell->new->parse_from_file($file) };
    die $error if $error;

    my ($output);
    my @cmd = ( $self->ispell_cmd, shellwords( $self->ispell_argv ), "-a" );
    run3( \@cmd, \$text, \$output, \$error );
    die $error if $error;

    my ( @errors, %seen );
    foreach my $line ( split( "\n", $output ) ) {
        if ( my ( $original, $remaining ) = ( $line =~ /^[\&\?\#] (\S+)\s+(.*)/ ) ) {
            if ( !$seen{$original}++ ) {
                my ($suggestions) = ( $remaining =~ /: (.*)/ );
                if ( $suggestions && $self->suggest ) {
                    push( @errors, sprintf( "%s (suggestions: %s)", $original, $suggestions ) );
                }
                else {
                    push( @errors, $original );
                }
            }
        }
    }
    die sprintf( "unrecognized words:\n%s\n", join( "\n", sort @errors ) ) if @errors;
}

1;

__END__

=pod

=head1 NAME

Code::TidyAll::Plugin::PodSpell - use Pod::Spell + ispell with tidyall

=head1 VERSION

version 0.17

=head1 SYNOPSIS

   In configuration:

   [PodSpell]
   select = lib/**/*.{pm,pod}
   ispell_argv = -p $ROOT/.ispell_english
   suggest = 1

=head1 DESCRIPTION

Uses L<Pod::Spell> in combination with
L<ispell|http://fmg-www.cs.ucla.edu/geoff/ispell.html> to spell-check POD. Any
seemingly misspelled words will be output one per line.

You can specify additional valid words by:

=over

=item *

Adding them to your personal ispell dictionary, e.g. ~/.ispell_english

=item *

Adding them to an ispell dictionary in the project root, then including this in
the configuration:

    ispell_argv = -p $ROOT/.ispell_english

=back

The dictionary file should contain one word per line.

=head1 INSTALLATION

Install ispell from your package manager or from the link above.

=head1 CONFIGURATION

=over

=item ispell_argv

Arguments to pass to ispell. "-a" will always be passed, in order to parse the
results.

=item ispell_cmd

Full path to ispell

=item suggest

If true, show suggestions next to misspelled words. Default is false.

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
