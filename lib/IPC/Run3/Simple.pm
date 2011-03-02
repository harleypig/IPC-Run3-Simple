package IPC::Run3::Simple;

# ABSTRACT: Simple utility module to make the easy to use IPC::Run3 even more easy to use.

use strict;
use warnings;

use Carp;
use IPC::Run3;
use Exporter;

use base 'Exporter';

our @EXPORT = qw( run3 );
our %EXPORT_TAGS = ( 'all' => \@EXPORT );

our $CHOMP_ERR  = 0;
our $CHOMP_OUT  = 0;
our $DIE_ON_ERR = 0;

# VERSION

=method run3

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

 DIE_ON_ERR If true, run3 will 'croak $stderr' instead of returning if $stderr
 contains anything.  Default is false.

 CHOMP_OUT If true, run3 will 'chomp $$stdout' if stdout is a scalar reference
 or 'chomp @$stdout' if stdout is an array reference. Otherwise, it has no
 effect. Default is false.

 CHOMP_ERR If true, run3 will 'chomp $$stderr' if stderr is a scalar reference
 or 'chomp @$stderr' if stderr is an array reference. Otherwise, it has no
 effect.  Default is false.

=cut

no warnings 'redefine';
sub run3 {

  my $arg = shift;
  my $ref = ref $arg;

  my $return_array = 0;

  my ( $cmd, $stdin, $stdout, $stderr, $options, $out, $err );

  if ( $ref eq 'ARRAY' ) {

    $return_array++;
    $cmd     = $arg;
    $stdin   = undef;
    $stdout  = \$out;
    $stderr  = \$err;
    $options = {};

  } elsif ( $ref eq 'HASH' ) {

    croak "'cmd' required and must be a reference to an array"
      unless exists $arg->{ 'cmd' } && ref $arg->{ 'cmd' } eq 'ARRAY';

    $cmd     = $arg->{ 'cmd' };
    $stdin   = $arg->{ 'stdin' }   || undef;
    $stdout  = $arg->{ 'stdout' }  || undef;
    $stderr  = $arg->{ 'stderr' }  || undef;
    $options = $arg->{ 'options' } || {};

  } else {

    croak "Expecting either an array ref or a hash ref";

  }

  IPC::Run3::run3( $cmd, $stdin, $stdout, $stderr, $options );

  my $syserr = $?;

  croak $stderr
    if $DIE_ON_ERR && $$stderr ne '';

  chomp $$stdout
    if $CHOMP_OUT && ref $stdout eq 'SCALAR';

  chomp @$stdout
    if $CHOMP_OUT && ref $stdout eq 'ARRAY';

  chomp $$stderr
    if $CHOMP_ERR && ref $stdout eq 'SCALAR';

  chomp @$stderr
    if $CHOMP_ERR && ref $stdout eq 'ARRAY';

  return ( $out, $err, $syserr )
    if $return_array;

}
use warnings 'redefine';

1;

=head1 SYNOPSIS

 use IPC::Run3::Simple;

 # Dead simple, ignoring system error and getting rid of the final newline in
 # the output.

 $IPC::Run3::Simple::CHOMP_OUT = 1;
 my ( $out, $err ) = run3( [qw( ls -AGlh )] );
 die $err if $err;

 # Manipulate $out however you want.

 # Dump file listing into array, then chomp the array, ignoring any errors.

 $IPC::Run3::Simple::CHOMP_OUT = 1;
 my $args = {

  'cmd'    => [qw( ls -AGlh )],
  'stdout' => \my @files,

 };

 for my $file ( @files ) { print "filename: $file\n" }

=cut
