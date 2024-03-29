package Code::TidyAll::Plugin::MasonTidy;
$Code::TidyAll::Plugin::MasonTidy::VERSION = '0.24';
use Mason::Tidy;
use Mason::Tidy::App;
use Moo;
use Text::ParseWords qw(shellwords);
extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'masontidy' }

sub transform_source {
    my ( $self, $source ) = @_;

    local @ARGV = shellwords( $self->argv );
    local $ENV{MASONTIDY_OPT};
    my $dest = Mason::Tidy::App->run($source);
    return $dest;
}

1;

# ABSTRACT: Use masontidy with tidyall

__END__

=pod

=head1 VERSION

version 0.24

=head1 SYNOPSIS

   In configuration:

   [MasonTidy]
   select = comps/**/*.{mc,mi}
   argv = --indent-perl-block 0 --perltidy-argv "-noll -l=78"

=head1 DESCRIPTION

Runs L<masontidy>, a tidier for L<HTML::Mason> and L<Mason 2|Mason>
components.

=head1 INSTALLATION

Install L<masontidy> from CPAN.

    cpanm masontidy

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to masontidy

=item cmd

Full path to masontidy

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
