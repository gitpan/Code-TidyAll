package Code::TidyAll::Plugin::JSHint;
{
  $Code::TidyAll::Plugin::JSHint::VERSION = '0.17';
}
use Code::TidyAll::Util qw(tempdir_simple write_file);
use Capture::Tiny qw(capture_merged);
use Moo;
extends 'Code::TidyAll::Plugin';

sub validate_params {
    my ( $self, $params ) = @_;

    delete( $params->{options} );
    return $self->SUPER::validate_params($params);
}

sub _build_cmd { 'jshint' }

sub BUILDARGS {
    my ( $class, %params ) = @_;

    if ( my $options_string = $params{options} ) {
        my @options   = split( /\s+/, $options_string );
        my $conf_dir  = tempdir_simple();
        my $conf_file = "$conf_dir/jshint.json";
        write_file( $conf_file, '{ ' . join( ",\n", map { "\"$_\": true" } @options ) . ' }' );
        $params{argv} ||= "";
        $params{argv} .= " --config $conf_file";
    }
    return \%params;
}

sub validate_file {
    my ( $self, $file ) = @_;

    my $cmd = sprintf( "%s %s %s", $self->cmd, $self->argv, $file );
    my $output = capture_merged { system($cmd) };
    if ( $output =~ /\S/ ) {
        $output =~ s/^$file:\s*//gm;
        die "$output\n";
    }
}

1;

__END__

=pod

=head1 NAME

Code::TidyAll::Plugin::JSHint - use jshint with tidyall

=head1 VERSION

version 0.17

=head1 SYNOPSIS

   In configuration:

   ; With default settings
   ;
   [JSHint]
   select = static/**/*.js

   ; Specify options inline
   ;
   [JSHint]
   select = static/**/*.js
   options = bitwise camelcase latedef

   ; or refer to a jshint.json config file in the same directory
   ;
   [JSHint]
   select = static/**/*.js
   argv = --config $ROOT/jshint.json

   where jshint.json looks like

   {
      "bitwise": true,
      "camelcase": true,
      "latedef": true
   }

=head1 DESCRIPTION

Runs L<jshint|http://www.jshint.com/>, a JavaScript validator, and dies if any
problems were found.

=head1 INSTALLATION

See installation options at L<jshint|http://www.jshint.com/platforms/>. One
easy method is to install L<npm|https://npmjs.org/>, then run

    npm install jshint -g

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to jshint

=item cmd

Full path to jshint

=item options

A whitespace separated string of options, as documented
L<here|http://www.jshint.com/docs/>. These will be written to a temporary
config file and passed as --config to argv.

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
