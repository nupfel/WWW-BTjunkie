use inc::Module::Install;

name     'WWW-BTjunkie';
all_from 'lib/WWW/BTjunkie.pm';
author   q{Tobias Kirschstein <mail@lev.geek.nz>};
license  'perl';

requires 'Any::Moose';
requires 'Web::Scraper::LibXML';
requires 'URI';

build_requires 'Test::More';

auto_install;

WriteAll;

