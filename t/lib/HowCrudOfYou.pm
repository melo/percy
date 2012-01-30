package HowCrudOfYou;

use MyTests;
use Test::More;
use Test::Fatal;
use Test::Deep;

my $s  = test_percy_schema();
my $db = $s->db;

subtest 'create()' => sub {
  use utf8;
  my $data = {a => 1, x => 'My name is Olé'};
  my ($r, $f);

  is(exception { $r = $db->create(x => $data) },
    undef, 'DB create(), without ID, lives');
  cmp_deeply(
    $r,
    { d    => $data,
      oid  => re(qr{^\d+$}),
      pk   => re(qr{^[-A-F0-9]{36}$}),
      type => 'x',
    },
    '... got back a record data structure',
  );

  is(exception { $f = $db->fetch($r->{oid}) },
    undef, 'DB fetch, with OID, lives');
  cmp_deeply($f, $r, '... got the expected record');

  my $id = Percy::Utils::generate_uuid();
  $data = {b => 2};
  is(exception { $r = $db->create(x => $data => $id) },
    undef, 'DB create() with ID lives');

  is(exception { $f = $db->fetch(x => $id) },
    undef, 'DB fetch, with PK/Type, lives');
  cmp_deeply($f, $r, '... got the expected record');
};


subtest 'fetch()' => sub {
  my $data = {a => 1};
  my $r = create_record($data);
  my $f;

  is(exception { $f = $db->fetch($r->{oid}) },
    undef, 'DB fetch, with OID, lives');
  cmp_deeply($f, $r, '... got the expected record');

  is(exception { $f = $db->fetch($r) }, undef,
    'DB fetch, with record, lives');
  cmp_deeply($f, $r, '... got the expected record');

  is(exception { $f = $db->fetch(x => $r->{pk}) },
    undef, 'DB fetch, with PK/Type, lives');
  cmp_deeply($f, $r, '... got the expected record');
};


subtest 'update()' => sub {
  use utf8;
  my $data = {c => time(), d => 'Olé, Olé'};
  my $f;

  ## Prepare a record to play with
  my $r = create_record($data);

  ## Single record
  $r->{d}{cc} = 42;
  is(exception { $f = $db->update($r) },
    undef, 'DB update, with record, lives');
  is(0 + $f, 1, '... one row updated');
  is(exception { $f = $db->fetch($r) }, undef, 'DB fetch, with OID, lives');
  cmp_deeply($f, $r, '... got the expected record');

  ## Single oid
  $r->{d} = {x => 'y'};
  is(exception { $f = $db->update($r->{oid} => $r->{d}) },
    undef, 'DB update, with oid, lives');
  is(0 + $f, 1, '... one row updated');
  is(exception { $f = $db->fetch($r) }, undef, 'DB fetch lives');
  cmp_deeply($f, $r, '... got the expected record');

  ## type,pk
  $r->{d} = {z => 'a'};
  is(exception { $f = $db->update($r->{type} => $r->{pk} => $r->{d}) },
    undef, 'DB update, with type/pk, lives');
  is(0 + $f, 1, '... one row updated');
  is(exception { $f = $db->fetch($r) }, undef, 'DB fetch lives');
  cmp_deeply($f, $r, '... got the expected record');

  ## Update for unknown entry
  is(exception { $f = $db->update(-1 => $data) },
    undef, 'DB update with a unknown oid lives');
  is($f, undef, '... undef returned because no type could be found');

  is(exception { $f = $db->update({oid => -1, d => $data}) },
    undef, 'DB update with a unknown record lives');
  is($f, undef, '... undef returned because no type could be found');

  is(exception { $f = $db->update(x => -1 => $data) },
    undef, 'DB update with a unknown type/pk lives');
  isnt($f, undef, '... undef was not returned so update query was run');
  is(0 + $f, 0, '... and 0 rows were returned as expected');
};


subtest 'delete()' => sub {
  my ($r, $f);

  ## Record
  $r = create_record({a => 42, c => 43});
  is(exception { $f = $db->delete($r) },
    undef, 'DB delete, with record, lives');
  is(0 + $f, 1, '... one row deleted');
  is(exception { $f = $db->fetch($r) }, undef,
    'DB fetch, with record, lives');
  is($f, undef, '... record does not exist anymore');

  ## Single oid
  $r = create_record({a => 42, c => 43});
  is(exception { $f = $db->delete($r->{oid}) },
    undef, 'DB delete, with record, lives');
  is(0 + $f, 1, '... one row deleted');
  is(exception { $f = $db->fetch($r) }, undef, 'DB fetch, with OID, lives');
  is($f, undef, '... record does not exist anymore');

  ## type,pk
  $r = create_record({a => 42, c => 43});
  is(exception { $f = $db->delete($r->{type} => $r->{pk}) },
    undef, 'DB delete, with record, lives');
  is(0 + $f, 1, '... one row deleted');
  is(exception { $f = $db->fetch($r) },
    undef, 'DB fetch, with Type/Pk, lives');
  is($f, undef, '... record does not exist anymore');

  ## Delete for unknown entry with OID
  is(exception { $f = $db->delete(-1) },
    undef, 'DB delete with a unknown oid lives');
  is($f, undef, '... undef returned because no type could be found');

  is(exception { $f = $db->delete({oid => -1}) },
    undef, 'DB delete with a unknown record lives');
  is($f, undef, '... undef returned because no type could be found');

  is(exception { $f = $db->delete(x => -1) },
    undef, 'DB delete with a unknown type/pk lives');
  isnt($f, undef, '... undef was not returned so delete query was run');
  is(0 + $f, 0, '... and 0 rows were returned as expected');
};


done_testing();


## Create a record to play
sub create_record {
  my ($data) = @_;
  my ($r, $f);

  is(exception { $r = $db->create(x => $data) }, undef, 'DB create() lives');
  is(exception { $f = $db->fetch($r->{oid}) }, undef, 'DB fetch() lives');
  cmp_deeply($f, $r, '... got our play record');

  return $r;
}

1;
