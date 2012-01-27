#!perl

use Test::More;
use lib 't/lib';
use MySchema;

subtest 'instances' => sub {
  my $i1 = MySchema->schema;
  my $i2 = MySchema->schema;

  is("$i1", "$i2", 'Multiple calls to ->schema return same instance');
};


done_testing();
