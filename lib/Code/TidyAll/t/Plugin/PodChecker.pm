package Code::TidyAll::t::Plugin::PodChecker;
{
  $Code::TidyAll::t::Plugin::PodChecker::VERSION = '0.17';
}
use Test::Class::Most parent => 'Code::TidyAll::t::Plugin';

sub test_main : Tests {
    my $self = shift;

    $self->tidyall(
        source    => '=head1 DESCRIPTION\n\nHello',
        expect_ok => 1,
        desc      => 'ok',
    );
    $self->tidyall(
        source       => '=head1 METHODS\n\n=over',
        expect_error => qr/without closing =back/,
        desc         => 'error',
    );
    $self->tidyall(
        source    => '=head1 DESCRIPTION\n\n=head1 METHODS\n\n',
        expect_ok => 1,
        desc      => 'ok - empty section, no warnings',
    );
    $self->tidyall(
        source       => '=head1 DESCRIPTION\n\n=head1 METHODS\n\n',
        conf         => { warnings => 1 },
        expect_error => qr/empty section in previous paragraph/,
        desc         => 'error - empty section, warnings=1',
    );
    $self->tidyall(
        source    => '=head1 DESCRIPTION\n\nblah blah\n\n=head1 DESCRIPTION\n\nblah blah',
        conf      => { warnings => 1 },
        expect_ok => 1,
        desc      => 'ok - duplicate section, warnings=1',
    );
    $self->tidyall(
        source       => '=head1 DESCRIPTION\n\nblah blah\n\n=head1 DESCRIPTION\n\nblah blah',
        conf         => { warnings => 2 },
        expect_error => qr/multiple occurrence/,
        desc         => 'error - duplicate section, warnings=2',
    );
}

1;

__END__

=pod

=head1 VERSION

version 0.17

=head1 SEE ALSO

L<Code::TidyAll|Code::TidyAll>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
