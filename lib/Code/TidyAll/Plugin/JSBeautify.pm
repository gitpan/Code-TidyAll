package Code::TidyAll::Plugin::JSBeautify;
$Code::TidyAll::Plugin::JSBeautify::VERSION = '0.21';
use Capture::Tiny qw(capture_merged);
use Code::TidyAll::Util qw(write_file);
use Moo;
use Try::Tiny;
extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'js-beautify' }

sub transform_file {
    my ( $self, $file ) = @_;

    try {
        my $cmd = join( " ", $self->cmd, $self->argv, $file );
        my $output = capture_merged { system($cmd) };
        write_file( $file, $output );
    }
    catch {
        die sprintf( "%s exited with error - possibly bad arg list '%s'", $self->cmd, $self->argv );
    };
}

1;

# ABSTRACT: Use js-beautify with tidyall

__END__

=pod

=head1 VERSION

version 0.21

=head1 SYNOPSIS

   In configuration:

   [JSBeautify]
   select = static/**/*.js
   argv = --indent-size 2 --brace-style expand

=head1 DESCRIPTION

Runs L<js-beautify|https://npmjs.org/package/js-beautify>, a JavaScript tidier.

=head1 INSTALLATION

Install L<npm|https://npmjs.org/>, then run

    npm install js-beautify -g

Do not confuse this with the C<jsbeautify> package (without the dash).

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to js-beautify

=item cmd

Full path to js-beautify

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
