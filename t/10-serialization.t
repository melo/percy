#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Test::Fatal;
use Test::Deep;

my @test_cases = ([{a => 1}, '{"a":1}', 'very simple structure'],);

my $p = test_percy_db();
for my $tc (@test_cases) {
  my ($in, $out, $d) = @$tc;

  my $s;
  is(exception { $s = $p->encode_to_db($in) }, undef,
    "serialize() lives for $d");
  is($s, $out, '... output as expected');

  is(exception { $s = $p->decode_from_db($out) },
    undef, "... deserialize() lives from output");
  cmp_deeply($s, $in, '... and back to the input we go');

}

done_testing();
