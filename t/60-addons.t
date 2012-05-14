#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Test::Deep;

my $s  = test_percy_schema();
my $db = $s->db;

subtest 'DBI::IDTable' => sub {
  _deploy_x_type();

  #create
  my $doc = $db->create(
    x => {
      f_zero => 'abc',
      f_one  => 'def',
      f_two  => 'ghi',
    }
  );

  my $row = _dbi_fetch('xs', x_id => $doc->{pk});
  ok($row, 'After create, got row from ID table...');
  cmp_deeply($row, { x_id => $doc->{pk}, f1 => 'def', f2 => 'GHI' }, '... with the expected content');
  is($doc->{d}{x_id}, $doc->{pk}, '... key field is updated on the document too');

  ## Update
  $doc->{d}{f_one} = 'wxyz';
  $doc->{d}{f_two} = 'qrst';
  $db->update($doc);

  $row = _dbi_fetch('xs', x_id => $doc->{pk});
  ok($row, 'After update, got row from ID table...');
  cmp_deeply($row, { x_id => $doc->{pk}, f1 => 'wxyz', f2 => 'QRST' }, '... with the expected content');

  ## Delete
  $db->delete($doc);

  $row = _dbi_fetch('xs', x_id => $doc->{pk});
  is($row, undef, 'After delete, mapping row deleted too');

  ## Update on non-existing row
  $db->_dbh->do('DELETE FROM xs WHERE x_id=?', undef, $doc->{pk});
  $row = _dbi_fetch('xs', x_id => $doc->{pk});
  ok(!$row, "Make sure mapping row for id $doc->{pk} is missing");
  $db->update($doc);
  $row = _dbi_fetch('xs', x_id => $doc->{pk});
  ok($row, 'Update with missing row on mapping table, a row is created');
  cmp_deeply($row, { x_id => $doc->{pk}, f1 => 'wxyz', f2 => 'QRST' }, '... with the expected content');
};


subtest 'DBI::IDTable just for ID' => sub {
  _deploy_z_type();

  #create
  my $doc = $db->create(
    z => {
      z_id   => 99,
      f_zero => 'abc',
      f_one  => 'def',
      f_two  => 'ghi',
    }
  );

  my $row = _dbi_fetch('zs', z_id => $doc->{pk});
  ok($row, 'After create, got row from ID table...');
  cmp_deeply($row, { z_id => $doc->{pk}, f1 => undef }, '... with the expected content');
  is($doc->{d}{z_id}, $doc->{pk}, '... key field is updated on the document');
  isnt($doc->{pk}, 99, "... didn't use the input key field, migrations not allowed for type");

  ## Update
  $doc->{d}{f_one} = 'wxyz';
  $doc->{d}{f_two} = 'qrst';
  $db->update($doc);

  $row = _dbi_fetch('zs', z_id => $doc->{pk});
  ok($row, 'After update, got row from ID table...');
  cmp_deeply($row, { z_id => $doc->{pk}, f1 => undef }, '... no changes there');

  ## Delete
  $db->delete($doc);

  $row = _dbi_fetch('zs', z_id => $doc->{pk});
  ok($row, 'After delete, mapping still has a row...');
  cmp_deeply($row, { z_id => $doc->{pk}, f1 => undef }, '... with no changes as expected');
};


subtest 'DBI::IDTable with migration' => sub {
  ## Create
  my $doc = $db->create(
    x => {
      x_id   => 42,
      f_zero => 'abc',
      f_one  => 'def',
      f_two  => 'ghi',
    }
  );

  my $row = _dbi_fetch('xs', x_id => $doc->{pk});
  ok($row, 'After create, got row from ID table...');
  cmp_deeply($row, { x_id => $doc->{pk}, f1 => 'def', f2 => 'GHI' }, '... with the expected content');
  is($doc->{d}{x_id}, $doc->{pk}, '... key field is updated on the document');
  is($doc->{pk},      42,         '... this is a migration, used the input key field');
};


done_testing();


#######
# Utils

sub _deploy_x_type {
  $s->type_spec(
    x => {
      id_table => {
        name   => 'xs',
        key    => 'x_id',
        fields => {
          f1 => 'f_one',
          f2 => sub { uc($_[0]{d}{f_two}) },
        },
        migrate_ok => 1,
      },
    }
  );

  my $sql_stmts = $db->_generate_table_stmts(
    { name   => 'xs',
      fields => [
        { name              => 'x_id',
          type              => 'INTEGER NOT NULL',
          is_auto_increment => 1,
        },
        { name => 'f1',
          type => 'VARCHAR(64) NOT NULL',
        },
        { name => 'f2',
          type => 'VARCHAR(64) NOT NULL',
        },
      ],
      pk => ['x_id'],
    }
  );
  $db->_deploy_exec_sql_stmts(@$sql_stmts);
}

sub _deploy_z_type {
  $s->type_spec(z => { id_table => { name => 'zs', key => 'z_id', id_only => 1 } });

  my $sql_stmts = $db->_generate_table_stmts(
    { name   => 'zs',
      fields => [
        { name              => 'z_id',
          type              => 'INTEGER NOT NULL',
          is_auto_increment => 1,
        },
        { name => 'f1',
          type => 'VARCHAR(64)',
        },
      ],
      pk => ['z_id'],
    }
  );
  $db->_deploy_exec_sql_stmts(@$sql_stmts);
}

sub _dbi_fetch {
  my ($tbl, $fld, $id) = @_;

  return $db->_dbh->selectrow_hashref("SELECT * FROM $tbl WHERE $fld=?", undef, $id);
}
