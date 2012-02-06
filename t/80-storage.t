#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Test::Fatal;
use Percy::Utils;

my $s   = test_percy_schema();
my $uid = Percy::Utils::generate_uuid();
my $oid;

subtest 'tx' => sub {
  my $db = $s->db;

  ## Rollback
  like(
    exception {
      $db->tx(
        sub {
          $oid = insert_row($_[1], $uid);
          die "Will rollback,";
        }
      );
    },
    qr/^Will rollback,/,
    'Got exception'
  );
  my $found = select_row($db->dbh, $oid);
  is($found, undef, 'Transaction was rollback');

  ## Commited
  $db->tx(sub { insert_row($_[1], $uid) });
  $found = select_row($db->dbh, $oid);
  is($found, $uid, 'Transaction was commited properly');
};


subtest 'tx nested' => sub {
  my $db = $s->db;

  my ($oid1, $oid2) = @_;
  my $uid1 = Percy::Utils::generate_uuid();
  my $uid2 = Percy::Utils::generate_uuid();
  like(
    exception {
      $db->tx(
        sub {
          $oid1 = insert_row($_[1], $uid1);

          $db->tx(sub { $oid2 = insert_row($_[1], $uid2) });

          die 'will die here';
        }
      );
    },
    qr{will die here},
    'Nested transaction doesnt die'
  );

  is(select_row($db->dbh, $oid1), undef, 'First oid was not found');
  is(select_row($db->dbh, $oid2), undef, '... neither was the second one');
};


subtest 'reconnect' => sub {
  my $db = $s->db;
  my $found;

  $found = select_row($db->dbh, $oid);
  is($found, $uid, 'Got a row without problems');

  is(exception { $db->_dbh(undef) },
    undef, 'Remove the DBI handle, no exceptions');

  $found = select_row($db->dbh, $oid);
  is($found, $uid, 'Select worked, so reconnect worked');

  is(exception { $db->dbh->disconnect }, undef, 'Disconnected DBI handle');

  $found = select_row($db->dbh, $oid);
  is($found, $uid, 'Select worked, so reconnect worked again');
};


done_testing();


## Helper sub's
sub insert_row {
  my ($dbh, $uid) = @_;

  $dbh->do('
    INSERT INTO obj_storage (oid,  pk, type, data)
                     VALUES (NULL, ?,  ?,    "42")
  ', undef, $uid, 'my_type');
  return $dbh->last_insert_id(undef, undef, undef, undef);
}

sub select_row {
  my ($dbh, $oid) = @_;

  my ($found) = $dbh->selectrow_array('
    SELECT pk
      FROM obj_storage
     WHERE oid=?
  ', undef, $oid);

  return $found;
}
