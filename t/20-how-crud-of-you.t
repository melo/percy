#!perl

use lib 't/lib';
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

  $data = {b => 2};
  is(exception { $r = $db->create(x => $data => 42) },
    undef, 'DB create() with ID lives');

  is(exception { $f = $db->fetch(x => 42) },
    undef, 'DB fetch, with PK/Type, lives');
  cmp_deeply($f, $r, '... got the expected record');
};


subtest 'fetch()' => sub {
  my $data = {a => 1};
  my $r;

  is(exception { $r = $db->create(x => $data) }, undef, 'DB create() lives');

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
  my $r;

  ## Prepare a record to play with
  is(exception { $r = $db->create(x => $data) }, undef, 'DB create() lives');
  is(exception { $f = $db->fetch($r->{oid}) }, undef, 'DB fetch() lives');
  cmp_deeply($f, $r, '... got our play record');

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
  $r->{oid} = -1;
  is(exception { $f = $db->update($r) },
    undef, 'DB update with a bad oid lives');
  is(0 + $f, 0, '... zero row updated');
};


done_testing();
