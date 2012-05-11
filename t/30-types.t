#!perl

use Test::More;
use Test::Fatal;
use Test::Deep;
use Percy::Schema::Type;

subtest 'defaults' => sub {
  my $t = Percy::Schema::Type->new(type => 'my_type');

  is($t->type, 'my_type', 'type attr works');
  like($t->generate_id, qr{^[-A-F0-9]{36}$}, 'generate_id() looks like a UUID');
  is($t->encode_to_db(undef, { d => { a => 1 } }), '{"a":1}', 'encode_to_db() defaults to JSON');
  cmp_deeply($t->decode_from_db(undef, '{"a":1}'), { a => 1 }, 'decode_from_db() defaults to JSON');
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

  is($t->encode_to_db(undef, { d => 'aaa' }), '616161', 'encode_to_db_cb works...');
  is($t->decode_from_db(undef, '616161'), 'aaa', 'and so does decode_from_db_cb');
};


subtest 'db callbacks' => sub {
  for my $w (qw( before after )) {
    for my $e (qw( create change update delete fetch )) {
      my $t;
      my $meth = "${w}_${e}";
      my $attr = "${meth}_cb";

      is(exception { $t = Percy::Schema::Type->new(type => 'x') },
        undef, "Type created without '$attr'");
      is($t->$meth(), undef, "... the default does nothing");

      is(
        exception {
          $t = Percy::Schema::Type->new(
            type => 'x',
            $attr => sub { uc($attr) },
          );
        },
        undef,
        "Type created with '$attr'"
      );
      is($t->$meth(), uc($attr), "... works now");
    }
  }
};


subtest 'sets' => sub {
  my $t = Percy::Schema::Type->new(
    type => 'set_type',
    sets => { 'xpto' => { type => 'ypto' } },
  );

  cmp_deeply($t->sets, { xpto => { type => 'ypto' } }, 'Set was configured correctly',);
};


subtest 'bad boys' => sub {
  like(
    exception { Percy::Schema::Type->new },
    qr/^\QAttribute (type) is required at constructor Percy::Schema::Type::new\E/,
    'no type, will die',
  );
};


done_testing();
