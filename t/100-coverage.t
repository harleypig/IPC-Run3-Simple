
# These tests were created to satisfy Devel::Cover reports.  They are not
# exhaustive and should not be considered as a complete test case.

use Test::Most tests => 10;
use Test::NoWarnings;

BEGIN { use_ok( 'IPC::Run3::Simple', ':all' ) }

my @subs = qw(

  run3 chomp_err chomp_out croak_on_err default_stderr default_stdin
  default_stdout tee_systemcall

);

ok( exists $main::{ $_ }, "$_ seems to have been imported" )
  for @subs;

#my $chomp_err = $IPC::Run3::Simple::CHOMP_ERR;


