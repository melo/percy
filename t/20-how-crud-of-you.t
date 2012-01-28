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


done_testing();
