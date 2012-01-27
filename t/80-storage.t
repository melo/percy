#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Test::Fatal;
use Percy::Utils;

my $s = test_percy_schema();

subtest 'tx' => sub {
  my $db  = $s->db;
  my $uid = Percy::Utils::generate_uuid();
  my $oid;

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
  my $found = select_row($db->dbh, $oid);
  is($found, $uid, 'Transaction was commited properly');
};


done_testing();


## Helper sub's
sub insert_row {
  my ($dbh, $uid) = @_;

  $dbh->do('
    INSERT INTO oid_map (id,   pk, type)
                 VALUES (NULL, ?,  ?   )
  ', undef, $uid, 'my_type');
  return $dbh->last_insert_id(undef, undef, undef, undef);
}

sub select_row {
  my ($dbh, $oid) = @_;

  my ($found) = $dbh->selectrow_array('
    SELECT pk
      FROM oid_map
     WHERE id=?
  ', undef, $oid);

  return $found;
}
