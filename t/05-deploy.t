#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Test::Fatal;

my $s = test_percy_schema();

for my $table (qw( oid_storage oid_map )) {
  my $rows;
  is(
    exception {
      ($rows) = $s->db->dbh->selectrow_array('
        SELECT COUNT(*) FROM oid_storage
      ');
    },
    undef,
    "Found $table table"
  );
  is($rows, 0, '... with the expected number of rows, 0');
}

done_testing();
