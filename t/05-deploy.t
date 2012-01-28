#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Test::Fatal;

my $s = test_percy_schema();

my $rows;
is(
  exception {
    ($rows) = $s->db->dbh->selectrow_array('
      SELECT COUNT(*) FROM obj_storage
    ');
  },
  undef,
  "Found obj_storage table"
);
is($rows, 0, '... with the expected number of rows, 0');


done_testing();
