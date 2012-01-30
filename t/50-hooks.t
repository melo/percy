#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Test::Fatal;
use Test::Deep;

my $s = test_percy_schema();

my %cb_rec;
$s->type_spec(
  'hooks' => {
    after_fetch_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{after_fetch} = $cb_rec{calls};
    },
    before_fetch_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{before_fetch} = $cb_rec{calls};
    },

    after_change_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{after_change}    = $cb_rec{calls};
    },
    before_change_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{before_change}    = $cb_rec{calls};
    },

    after_create_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{after_create} = $cb_rec{calls};
    },
    before_create_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{before_create} = $cb_rec{calls};
    },

    after_update_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{after_update} = $cb_rec{calls};
    },
    before_update_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{before_update} = $cb_rec{calls};
    },

    after_delete_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{after_delete} = $cb_rec{calls};
    },
    before_delete_cb => sub {
      $cb_rec{calls}++;
      $cb_rec{before_delete} = $cb_rec{calls};
    },
  },
);

my $e = exception {
  my $db = $s->db;
  my ($r, $f);

  $r = $db->create('hooks' => {n => 42});
  ok($r, 'Created a hooks object ok');
  cmp_deeply(
    \%cb_rec,
    { calls            => 4,
      before_change    => 1,
      before_create    => 2,
      after_create     => 3,
      after_change     => 4,
    },
    '... callbacks called as expected'
  );

  $f = $db->fetch($r);
  ok($f, 'Fetch a hooks object ok');
  cmp_deeply(
    \%cb_rec,
    { calls            => 6,
      before_change    => 1,
      before_create    => 2,
      after_create     => 3,
      after_change     => 4,
      before_fetch     => 5,
      after_fetch      => 6,
    },
    '... callbacks called as expected'
  );

  $f = $db->fetch($r->{oid});
  ok($f, 'Fetch a hooks object (using OID) ok');
  cmp_deeply(
    \%cb_rec,
    { calls            => 7,
      before_change    => 1,
      before_create    => 2,
      after_create     => 3,
      after_change     => 4,
      before_fetch     => 5,
      after_fetch      => 7,
    },
    '... callbacks called as expected'
  );

  $r->{d}{n} = 84;
  $f = $db->update($r);
  is($f, 1, 'Update a hooks object ok');
  cmp_deeply(
    \%cb_rec,
    { calls            => 11,
      before_change    => 8,
      before_create    => 2,
      after_create     => 3,
      after_change     => 11,
      before_fetch     => 5,
      after_fetch      => 7,
      before_update    => 9,
      after_update     => 10,
    },
    '... callbacks called as expected'
  );

  $f = $db->delete($r);
  is($f, 1, 'Delete a hooks object ok');
  cmp_deeply(
    \%cb_rec,
    { calls            => 15,
      before_change    => 12,
      before_create    => 2,
      after_create     => 3,
      after_change     => 15,
      before_fetch     => 5,
      after_fetch      => 7,
      before_update    => 9,
      after_update     => 10,
      before_delete    => 13,
      after_delete     => 14,
    },
    '... callbacks called as expected'
  );
};
is($e, undef, 'All of this without an exception');


done_testing();
