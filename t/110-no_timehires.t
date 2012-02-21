
use Test::Most;

BEGIN {

  eval 'use Test::Without::Module q{Time::HiRes}';

  plan skip_all => 'Test::Without::Module not installed'
    if $@;

}

BEGIN { use_ok( 'IPC::Run3::Simple' ) }

my $sleep_time = 2;

my ( $nohires_stdout, $nohires_stderr, $nohires_syserr, $nohires_time ) = run3( [ 'sleep', $sleep_time ] );
ok( $nohires_syserr == 0, 'sleep did not cause system error (no Time::HiRes)' );
is( $nohires_stderr,  undef,       'sleep did not report error on stderr (no Time::HiRes)' );
is( $$nohires_stdout, '',          'sleep did not dump anythin stdout (no Time::HiRes)' );
is( $nohires_time,    $sleep_time, "sleep took $sleep_time seconds to run (no Time::HiRes)" );

done_testing();
