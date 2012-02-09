#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Test::Fatal;
use File::Temp 'tempfile';

my $s = test_percy_schema();

subtest 'deploy to live DB' => sub {
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

  is(
    exception {
      ($rows) = $s->db->dbh->selectrow_array('
        SELECT COUNT(*) FROM masta_slaves_set
      ');
    },
    undef,
    "Found masta_slaves_set table"
  );
  is($rows, 0, '... with the expected number of rows, 0');
};


subtest 'check SQL tables' => sub {
  my ($fh, $fn) = tempfile();
  local $ENV{PERCY_DEPLOY_SQL_DUMP} = "=$fn";

  $s->db->deploy;
  my $sql = do { local $/; <$fh> };

  like(
    $sql,
    qr{CREATE TABLE IF NOT EXISTS obj_storage},
    'obj_storage is present'
  );

  like(
    $sql,
    qr{CREATE TABLE IF NOT EXISTS masta_slaves_set},
    'masta_slaves_set is present'
  );
  like(
    $sql, qr{
      masta_slaves_set\s+\(
        \s+m_oid\s+INTEGER\s+NOT\s+NULL,
        \s+s_oid\s+INTEGER\s+NOT\s+NULL,
        \s+CONSTRAINT\s+masta_slaves_set_pk
        \s+PRIMARY\s+KEY\s+\(m_oid,\s+s_oid\)
      \s+\)
    }smx, '... schema as expected'
  );
};


done_testing();
