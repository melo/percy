#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Test::Fatal;
use Test::Deep;

my @test_cases = ([{a => 1}, '{"a":1}', 'very simple structure'],);

my $s  = test_percy_schema();
my $db = $s->db;
my $t  = $s->type_spec(simple => {});

for my $tc (@test_cases) {
  my ($in, $out, $d) = @$tc;

  my $o;
  is(exception { $o = $t->encode_to_db($db, {d => $in}) },
    undef, "encode_to_db() lives for $d");
  is($o, $out, '... output as expected');

  is(exception { $o = $t->decode_from_db($db, $out) },
    undef, "... decode_from_db() lives from output");
  cmp_deeply($o, $in, '... and back to the input we go');
}


done_testing();
