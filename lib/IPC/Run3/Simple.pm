package IPC::Run3::Simple;

# ABSTRACT: Simple utility module to make the easy to use IPC::Run3 even more easy to use.

use strict;
use warnings;

use Carp;
use IPC::Run3 ();
use Exporter 'import';

# VERSION

our @EXPORT = qw( run3 );

our @EXPORT_OK = qw(

  chomp_err chomp_out croak_on_err default_stderr default_stdin default_stdout
  tee_systemcall

);

our %EXPORT_TAGS = ( 'all' => [ @EXPORT, @EXPORT_OK ] );

our $CHOMP_ERR       = 1;
our $CHOMP_OUT       = 1;
our $CROAK_ON_ERR    = 0;
our $DEFAULT_STDIN   = undef;
our $DEFAULT_STDOUT  = undef;
our $DEFAULT_STDERR  = undef;
our $TIME_SYSTEMCALL = 1;
our $TEE_SYSTEMCALL  = 0;

=method chomp_err

  If a false value is passed, run3 will not chomp any error if it's stored in
  a scalar or array ref. Default is to chomp any error.

=method chomp_out

  If a false value is passed, run3 will not chomp the result if it's stored in
  a scalar or array ref. Default is to chomp any result.

=method croak_on_err

  If a false value is passed, run3 will return instead of croaking on error.
  Default is to croak on error.

=method default_stdin

  Set the default stdin to be used.

=method default_stdout

  Set the default stdout be used.

=method default_stderr

  Set the default stderr to be used.

=method tee_systemcall

  Turn on or off teeing of system call.

=cut

# '!! +shift' forces the value to be either undef or 1;

sub chomp_err       { $CHOMP_ERR       = !! +shift }
sub chomp_out       { $CHOMP_OUT       = !! +shift }
sub croak_on_err    { $CROAK_ON_ERR    = !! +shift }
sub default_stderr  { $DEFAULT_STDERR  = shift }
sub default_stdin   { $DEFAULT_STDIN   = shift }
sub default_stdout  { $DEFAULT_STDOUT  = shift }

# Is Capture::Tiny available?

if ( eval { require Capture::Tiny } ) {

  Capture::Tiny->import( 'tee' );
  eval "sub tee_systemcall { \$TEE_SYSTEMCALL = !! +shift }";
  croak "Unable to create tee_systemcall sub: $@" if $@;

} else {

  eval "sub tee_systemcall { \$TEE_SYSTEMCALL = 0 }";
  croak "Unable to create tee_systemcall sub: $@" if $@;

}

# Is Time::HiRes available?

if ( eval { require Time::HiRes } ) {

  Time::HiRes->import(qw( gettimeofday tv_interval ));

} else {

  eval "sub gettimeofday { time, 0 }";
  croak "Unable to create gettimeofday sub: $@" if $@;

  eval q{sub tv_interval {
    my ( $t0, $t1 ) = @_;
    $t1 = [ gettimeofday() ] unless defined $t1;
    return sprintf '%.6f', $t1->[0] - $t0->[0];
  }};
  croak "Unable to create tv_interval sub: $@" if $@;

}

=method run3

This method is exported into the calling namespace.

Expects either a reference to an array or a reference to a hash.

If a reference to an array is passed it is assumed to be a list of the command
and option(s) to be run. A list containing the results, errors, exit code and
execution time (in that order) will be returned. See SYNOPSIS for an example.

If a reference to a hash is passed in, the following information is expected:

 See IPC::Run3 documentation for possible values for each of these keys.

 'cmd'     Required
 'stdin'   Optional
 'stdout'  Optional
 'stderr'  Optional
 'options' Optional

Note: If any of stdin, stdout or stderr are not passed in the hash 'undef'
will be used in their place.

In addition, the following variables can be set, either in the hash passed in
or globally via $IPC::Run3::Simple::VARIABLE.

 CROAK_ON_ERR If true, run3 will 'croak $stderr' instead of returning if
 $stderr contains anything.  Default is to return instead of croaking.

 CHOMP_OUT If true, run3 will 'chomp $$stdout' if stdout is a scalar reference
 or 'chomp @$stdout' if stdout is an array reference. Otherwise, it has no
 effect. If false, nothing will be done to the output of the call. Default is
 true.

 CHOMP_ERR If true, run3 will 'chomp $$stderr' if stderr is a scalar reference
 or 'chomp @$stderr' if stderr is an array reference. Otherwise, it has no
 effect. If false, nothing will be done to the error output of the call.
 Default is true.

 TEE_SYSTEMCALL This depends on the L<Capture::Tiny> package.  If it is not
 available this option will be silently ignored. If true, run3 will wrap the
 system call in the Capture::Tiny::tee function which will dump the output to
 STDERR and STDOUT as usual while still returning the output to the calling
 function.

=cut

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
    $stdin   = $arg->{ 'stdin' }   || $DEFAULT_STDIN;
    $stdout  = $arg->{ 'stdout' }  || $DEFAULT_STDOUT;
    $stderr  = $arg->{ 'stderr' }  || $DEFAULT_STDERR;
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

  my $t0 = [ gettimeofday() ];

  if ( $TEE_SYSTEMCALL ) {

    # If you run 'perl -M-indirect -c thispackage' you will see a warning
    # about this line.  This shouldn't be a problem because, hopefully,
    # execution will never get here if Capture::Tiny isn't available.

    ( $stdout, $stderr ) = tee { IPC::Run3::run3( $cmd, $stdin, undef, undef, $options ) };

  } else {

    IPC::Run3::run3( $cmd, $stdin, $stdout, $stderr, $options );

  }

  my $time = tv_interval( $t0 );

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

  return ( $stdout, $stderr, $syserr, $time )
    if $return_array;

}

1;

=head1 SYNOPSIS

 use IPC::Run3::Simple;

 # Dead simple, ignoring system error and getting rid of the final newline in
 # the output.

 my ( $out, $err ) = run3( [qw( ls -AGlh )] ); # syserr and timing is ignored
 die $err if $err;

 # Manipulate $out however you want.

 # Dump file listing into array, then chomp the array, ignoring any errors.

 my $args = {

  'cmd'    => [qw( ls -AGlh )],
  'stdout' => \my @files,

 };

 run3( $args );

 for my $file ( @files ) { print "filename: $file\n" }

=cut
