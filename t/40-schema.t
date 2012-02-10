#!perl

use Test::More;
use Test::Fatal;
use Test::Deep;
use lib 't/lib';
use MyTests;
use MySchema;

subtest 'instances' => sub {
  my $i1 = MySchema->schema;
  my $i2 = MySchema->schema;

  is("$i1", "$i2", 'Multiple calls to ->schema return same instance');
};


subtest 'type registry' => sub {
  my $si = MySchema->schema;

  my $t1;
  is(exception { $t1 = $si->type_spec('my_type') },
    undef, "With missing type, type_spec() doesn't die");
  is($t1, undef, "... and returns undef");

  MySchema->set_default_type_spec({a => 1});
  is(exception { $t1 = $si->type_spec('my_type') },
    undef, "With missing type, type_spec() doesn't die");
  cmp_deeply($t1, {a => 1}, "... and returns the new default type_spec");

  my $t2;
  is(exception { $t2 = $si->type_spec(my_type => {}) },
    undef, "type_spec() doesn't die when adding a new one");
  isa_ok($t2, 'Percy::Schema::Type', '... returns object of the proper type');
  is($t2->type, 'my_type', '... with the expected type name');

  my $t3;
  is(exception { $t3 = $si->type_spec('my_type') },
    undef, 'With a existing type, type_spec() lives');
  is($t3->type, 'my_type', '... expected type attr');
  is("$t2", "$t3", '... with the same object we got when adding the type');
};


subtest 'sets' => sub {
  my $si = test_percy_schema();
  my $db = $si->db;

  is(exception { $si->type_spec('mt' => {sets => {sn => {slave => 'sl'}}}) },
    undef, 'Added type with set');
  is(exception { $si->type_spec(sl => {}) },
    undef, '... and slave type, no sets');

  cmp_deeply(
    $si->sets,
    { mt_sn_set => {
        set_name => 'mt_sn_set',
        slave    => 'sl',
        master   => 'mt',
      },
      masta_slaves_set => {
        set_name => "masta_slaves_set",
        slave    => "slava",
        master   => 'masta',
      },
    },
    '... set registry updated',
  );

  cmp_deeply(
    $si->set_spec({type => 'mt'}, 'sn'),
    $si->set_spec('mt_sn_set'),
    'set_spec() accepts both object/set and set_name'
  );
  cmp_deeply(
    $si->set_spec('mt_sn_set'),
    {slave => 'sl', master => 'mt', set_name => 'mt_sn_set'},
    '... and return the set spec information properly'
  );

  $db->deploy;
  my ($master, $slave);
  is(exception { $master = $db->create(mt => {m => 1}) },
    undef, 'Created object for type mt');
  is(exception { $slave = $db->add_to_set($master, 'sn', {slv => 42}) },
    undef, '... added slave to set');

  my $slave_copy = $db->fetch($slave);
  ok($slave_copy, 'Got copy of slave object');
  cmp_deeply(
    $slave_copy->{d},
    { slv => 42,
      $si->set_name($master, 'sn'),
      {pk => $master->{pk}, type => $master->{type}}
    },
    '... created slave has link to parent'
  );

  my $set_elems;
  is(exception { $set_elems = $db->fetch_set($master, 'sn') },
    undef, 'Called fetch_set() without problems');
  is(scalar(@$set_elems), 1, '... got some elements back');
  cmp_deeply($set_elems, [$slave], '... expected elements returned');

  my $slave2;
  is(exception { $slave2 = $db->add_to_set($master, 'sn', {slv => 84}) },
    undef, '... added another slave to set');

  is(exception { $set_elems = $db->fetch_set($master, 'sn') },
    undef, 'Called fetch_set() without problems');
  is(scalar(@$set_elems), 2, '... got two elements back');
  cmp_deeply(
    $set_elems,
    bag($slave, $slave2),
    '... expected elements returned'
  );

  my $rows;
  is(exception { $rows = $db->delete_from_set($master, 'sn', $slave) },
    undef, 'delete_from_set() doesnt die');
  is(0 + $rows, 1, '... expected number of set elements deleted');

  is(exception { $set_elems = $db->fetch_set($master, 'sn') },
    undef, 'Called fetch_set() without problems');
  is(scalar(@$set_elems), 1, '... got a single element back');
  cmp_deeply($set_elems, [$slave2], '... expected elements returned');

  is(exception { $rows = $db->delete_from_set($master, 'sn', $slave) },
    undef, 'delete_from_set() with slave not in set lives');
  is(0 + $rows, 0, '... expected number of set elements deleted');
};


subtest 'db' => sub {
  my $si = MySchema->schema;

  my $db1 = $si->db;
  isa_ok($db1, 'Percy::Storage::DBI');

  my $db2 = $si->db;
  is($db1, $db2, 'db() returns the same instance');

  is($si, $db1->schema,
    'DB objects have a reference to the schema who created them');
};


done_testing();
