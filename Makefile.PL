use inc::Module::Install;
name 'Amon2-Setup-Flavor-Wata';
all_from 'lib/Amon2/Setup/Flavor/Wata.pm';

# requires '';
requires 'Amon2'       => 0;
requires 'File::Slurp' => 0;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
