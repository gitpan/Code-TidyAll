package Code::TidyAll::Plugin::JSBeautify;
BEGIN {
  $Code::TidyAll::Plugin::JSBeautify::VERSION = '0.09';
}
use IPC::System::Simple qw(run);
use Moo;
extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'js-beautify' }

sub transform_file {
    my ( $self, $file ) = @_;

    run( sprintf( "%s --replace %s %s", $self->cmd, $self->argv, $file ) );
}

1;



=pod

=head1 NAME

Code::TidyAll::Plugin::JSBeautify - use js-beautify with tidyall

=head1 VERSION

version 0.09

=head1 SYNOPSIS

   In tidyall.ini:

   [JSBeautify]
   select = static/**/*.js
   argv = --indent-size 2 --brace-style expand

=head1 DESCRIPTION

Runs L<js-beautify|https://npmjs.org/package/js-beautify>, a Javascript tidier.

=head1 INSTALLATION

Install L<npm|https://npmjs.org/>, then run

    npm install js-beautify -g

Do not confuse this with the C<jsbeautify> package (without the dash).

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to js-beautfy

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

