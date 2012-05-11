#!perl

use lib 't/lib';
use MyTests;
use Test::More;

my @classes = qw( Percy::Schema Percy::Schema::Type Percy::Schema::Storage );

subtest 'namespace::clean worked' => sub {
  for my $class (@classes) {
    ok(!$class->can('try'),     "Class $class has no try method...");
    ok(!$class->can('has'),     "... nor a has method");
    ok(!$class->can('extends'), "... nor a extends method");
  }
};


done_testing();
