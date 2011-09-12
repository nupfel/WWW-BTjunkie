#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::BTjunkie' ) || print "Bail out!\n";
}

diag( "Testing Net::BTjunkie $Net::BTjunkie::VERSION, Perl $], $^X" );
