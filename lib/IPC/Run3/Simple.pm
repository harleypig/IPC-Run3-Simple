package IPC::Run3::Simple;

# ABSTRACT: Simple utility module to make the easy to use IPC::Run3 even more easy to use.

use strict;
use warnings;

our $VERSION = '0.001';  # VERSION

use Carp;
use IPC::Run3 ();
use Exporter 'import';

our @EXPORT = qw( run3 );
our %EXPORT_TAGS = ( 'all' => \@EXPORT );

our $CHOMP_ERR      = 0;
our $CHOMP_OUT      = 0;
our $CROAK_ON_ERR   = 0;
our $DEFAULT_STDIN  = undef;
our $DEFAULT_STDOUT = undef;
our $DEFAULT_STDERR = undef;

sub chomp_err      { $CHOMP_ERR      = ! ! +shift }
sub chomp_out      { $CHOMP_OUT      = ! ! +shift }
sub croak_on_err   { $CROAK_ON_ERR   = ! ! +shift }
sub default_stdin  { $DEFAULT_STDIN  = shift }
sub default_stdout { $DEFAULT_STDOUT = shift }
sub default_stderr { $DEFAULT_STDERR = shift }

sub run3 {

  my $arg = shift;
  my $ref = ref $arg;

  my $return_array = 0;

  my ( $cmd, $stdin, $stdout, $stderr, $options, $out );

  if ( $ref eq 'ARRAY' ) {

    $return_array++;
    $cmd     = $arg;
    $stdin   = $DEFAULT_STDIN;
    $stdout  = \$out;
    $stderr  = $DEFAULT_STDERR;
    $options = {};

  } elsif ( $ref eq 'HASH' ) {

    croak "'cmd' required and must be a reference to an array"
      unless exists $arg->{ 'cmd' } && ref $arg->{ 'cmd' } eq 'ARRAY';

    $cmd     = $arg->{ 'cmd' };
    $stdin   = $arg->{ 'stdin' } || $DEFAULT_STDIN;
    $stdout  = $arg->{ 'stdout' } || $DEFAULT_STDOUT;
    $stderr  = $arg->{ 'stderr' } || $DEFAULT_STDERR;
    $options = $arg->{ 'options' } || {};

    chomp_err( $arg->{ 'CHOMP_ERR' } )
      if exists $arg->{ 'CHOMP_ERR' };

    chomp_out( $arg->{ 'CHOMP_OUT' } )
      if exists $arg->{ 'CHOMP_OUT' };

    croak_on_err( $arg->{ 'CROAK_ON_ERR' } )
      if exists $arg->{ 'CROAK_ON_ERR' };

  } else {

    croak "Expecting either an array ref or a hash ref";

  }

  IPC::Run3::run3( $cmd, $stdin, $stdout, $stderr, $options );

  my $syserr = $?;

  croak $stderr
    if $CROAK_ON_ERR && $$stderr ne '';

  chomp $$stdout
    if $CHOMP_OUT && ref $stdout eq 'SCALAR';

  chomp @$stdout
    if $CHOMP_OUT && ref $stdout eq 'ARRAY';

  chomp $$stderr
    if $CHOMP_ERR && ref $stderr eq 'SCALAR';

  chomp @$stderr
    if $CHOMP_ERR && ref $stderr eq 'ARRAY';

  return ( $stdout, $stderr, $syserr )
    if $return_array;

} ## end sub run3

1;

__END__

=pod

=head1 NAME

IPC::Run3::Simple - Simple utility module to make the easy to use IPC::Run3 even more easy to use.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use IPC::Run3::Simple;

 # Dead simple, ignoring system error and getting rid of the final newline in
 # the output.

 IPC::Run3::Simple::chomp_out( 1 );
 my ( $out, $err ) = run3( [qw( ls -AGlh )] );
 die $err if $err;

 # Manipulate $out however you want.

 # Dump file listing into array, then chomp the array, ignoring any errors.

 IPC::Run3::Simple::chomp_out( 1 );
 my $args = {

  'cmd'    => [qw( ls -AGlh )],
  'stdout' => \my @files,

 };

 for my $file ( @files ) { print "filename: $file\n" }

=head1 METHODS

=head2 chomp_err

  If a true value is passed, run3 will chomp any error if it's stored in
  a scalar or array ref.

=head2 chomp_out

  If a true value is passed, run3 will chomp the result if it's stored in
  a scalar or array ref.

=head2 croak_on_err

  If a true value is passed, run3 will croak instead of returning.

=head2 default_stdin

  Set the default stdin to be used.

=head2 default_stdout

  Set the default stdout be used.

=head2 default_stderr

  Set the default stderr to be used.

=head2 run3

This method is exported into the calling namespace.

Expects either a reference to an array or a reference to a hash.

If a reference to an array is passed in then it is assumed to be a list of the
command and option(s) to be run. A list containing the results, errors and exit
code (in that order) will be returned. See SYNOPSIS for an example.

If a reference to a hash is passed in, the following information is expected:

 See IPC::Run3 documentation for possible values for each of these keys.

 'cmd'     Required
 'stdin'   Optional
 'stdout'  Optional
 'stderr'  Optional
 'options' Optional

Note: If any of stdin, stdout or stderr are not passed in the hash 'undef' will be used in their place.

In addition, the following variables can be set, either in the hash passed in
or globally via $IPC::Run3::Simple::VARIABLE.

 CROAK_ON_ERR If true, run3 will 'croak $stderr' instead of returning if $stderr
 contains anything.  Default is false.

 CHOMP_OUT If true, run3 will 'chomp $$stdout' if stdout is a scalar reference
 or 'chomp @$stdout' if stdout is an array reference. Otherwise, it has no
 effect. Default is false.

 CHOMP_ERR If true, run3 will 'chomp $$stderr' if stderr is a scalar reference
 or 'chomp @$stderr' if stderr is an array reference. Otherwise, it has no
 effect.  Default is false.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
