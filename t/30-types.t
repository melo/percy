#!perl

use Test::More;
use Test::Fatal;
use Test::Deep;
use Percy::Schema::Type;

subtest 'defaults' => sub {
  my $t = Percy::Schema::Type->new(type => 'my_type');

  is($t->type, 'my_type', 'type attr works');
  like($t->generate_id, qr{^[-A-F0-9]{36}$},
    'generate_id() looks like a UUID');
  is($t->encode_to_db(undef, {d => {a => 1}}),
    '{"a":1}', 'encode_to_db() defaults to JSON');
  cmp_deeply($t->decode_from_db(undef, '{"a":1}'),
    {a => 1}, 'decode_from_db() defaults to JSON');
};


subtest 'generate_id callback' => sub {
  my $t = Percy::Schema::Type->new(
    type           => 'my_type',
    generate_id_cb => sub {42},
  );

  is($t->generate_id, 42, 'generate_id_cb works');
};


subtest 'encode/decode callbacks' => sub {
  my $t = Percy::Schema::Type->new(
    type              => 'my_type',
    encode_to_db_cb   => sub { unpack('H*', $_[2]{d}) },
    decode_from_db_cb => sub { pack('H*', $_[2]) },
  );

  is($t->encode_to_db(undef, {d => 'aaa'}),
    '616161', 'encode_to_db_cb works...');
  is($t->decode_from_db(undef, '616161'),
    'aaa', 'and so does decode_from_db_cb');
};


subtest 'bad boys' => sub {
  like(
    exception { Percy::Schema::Type->new },
    qr/^Died at /, 'no type, will die',
  );
};


done_testing();
