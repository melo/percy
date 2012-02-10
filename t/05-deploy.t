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
    $sql, qr{
    obj_storage\s+\(
      \s+oid\s+INTEGER\s+NOT\s+NULL
      \s+CONSTRAINT\s+obj_storage_pk\s+PRIMARY\s+KEY\s+AUTOINCREMENT,
      \s+pk\s+VARCHAR\(64\)\s+NOT\s+NULL,
      \s+type\s+VARCHAR\(64\)\s+NOT\s+NULL,
      \s+data\s+BLOB\s+NOT\s+NULL
  }smx, '... schema as expected'
  );
  like(
    $sql,
    qr{obj_storage_pk_type_un .+? \(pk,\s+type\)},
    '... unique index for pk/type pair ok'
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

  ## Ordered sets tables
  my @test_cases = (
    { name  => 'sorted_sets_by_number_set',
      field => 'f_integer',
      type  => 'INTEGER',
    },
    { name  => 'sorted_sets_by_string_set',
      field => 'f_string',
      type  => 'VARCHAR(100)',
    },
    { name  => 'sorted_sets_by_date_set',
      field => 'f_date',
      type  => 'DATE',
    },
    { name  => 'sorted_sets_by_datetime_set',
      field => 'f_datetime',
      type  => 'DATETIME',
    },
  );

  for my $tc (@test_cases) {
    like(
      $sql,
      qr{CREATE TABLE IF NOT EXISTS \Q$tc->{name}\E},
      'sorted_sets_by_number_set is present'
    );
    like(
      $sql, qr{
        \Q$tc->{name}\E\s+\(
          \s+m_oid\s+INTEGER\s+NOT\s+NULL,
          \s+s_oid\s+INTEGER\s+NOT\s+NULL,
          \s+\Q$tc->{field}\E\s+\Q$tc->{type}\E\s+NOT\s+NULL,
          \s+CONSTRAINT\s+\Q$tc->{name}\E_pk
          \s+PRIMARY\s+KEY\s+\(m_oid,\s+s_oid\)\s*
        \)
      }smx, '... schema as expected'
    );
    like(
      $sql,
      qr{\Q$tc->{name}\E_idx .+? \(m_oid,\s+\Q$tc->{field}\E\)},
      '... index for sorted operations ok'
    );
  }
};


done_testing();
