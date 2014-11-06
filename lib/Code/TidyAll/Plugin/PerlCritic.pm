package Code::TidyAll::Plugin::PerlCritic;
$Code::TidyAll::Plugin::PerlCritic::VERSION = '0.23';
use Capture::Tiny qw(capture_merged);
use Moo;
extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'perlcritic' }

sub validate_file {
    my ( $self, $file ) = @_;

    my $cmd = sprintf( "%s %s %s", $self->cmd, $self->argv, $file );
    my $output = capture_merged { system($cmd) };
    die "$output\n" if $output !~ /^.* source OK\n/;
}

1;

# ABSTRACT: Use perlcritic with tidyall

__END__

=pod

=head1 VERSION

version 0.23

=head1 SYNOPSIS

   In configuration:

   ; Configure in-line
   ;
   [PerlCritic]
   select = lib/**/*.pm
   argv = --severity 5 --exclude=nowarnings

   ; or refer to a .perlcriticrc in the same directory
   ;
   [PerlCritic]
   select = lib/**/*.pm
   argv = --profile $ROOT/.perlcriticrc

=head1 DESCRIPTION

Runs L<perlcritic>, a Perl validator, and dies if any problems were
found.

=head1 INSTALLATION

Install perlcritic from CPAN.

    cpanm perlcritic

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to perlcritic

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
