package Code::TidyAll::Plugin::MasonTidy;
BEGIN {
  $Code::TidyAll::Plugin::MasonTidy::VERSION = '0.11';
}
use Capture::Tiny qw(capture_merged);
use Mason::Tidy;
use Moo;
use Text::ParseWords qw(shellwords);
extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'masontidy' }

sub transform_source {
    my ( $self, $source ) = @_;

    my %params;
    my $argv_list = [ shellwords( $self->argv ) ];
    my $opts_good;
    my $output = capture_merged { $opts_good = Mason::Tidy->get_options( $argv_list, \%params ) };
    die $output if !$opts_good;
    die sprintf( "unrecognized arguments '%s'", join( " ", @$argv_list ) ) if @$argv_list;
    my $mt   = Mason::Tidy->new(%params);
    my $dest = $mt->tidy($source);
    return $dest;
}

1;



=pod

=head1 NAME

Code::TidyAll::Plugin::MasonTidy - use masontidy with tidyall

=head1 VERSION

version 0.11

=head1 SYNOPSIS

   In tidyall.ini:

   [MasonTidy]
   select = comps/**/*.{mc,mi}
   argv = --indent-perl-block 0 --perltidy-argv "-noll -l=78"

=head1 DESCRIPTION

Runs L<masontidy|masontidy>, a tidier for L<HTML::Mason|HTML::Mason> and
L<Mason 2|Mason> components.

=head1 INSTALLATION

Install L<masontidy|masontidy> from CPAN.

    cpanm masontidy

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to masontidy

=item cmd

Full path to masontidy

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

