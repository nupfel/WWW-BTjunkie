#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::BTjunkie' ) || print "Bail out!\n";
}

diag( "Testing WWW::BTjunkie $WWW::BTjunkie::VERSION, Perl $], $^X" );
