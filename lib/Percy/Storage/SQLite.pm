package Percy::Storage::SQLite;

# ABSTRACT: SQLite storage for Percy
# VERSION
# AUTHORITY

use Percy::Object;
use namespace::clean;


sub _deploy_tables {
  my ($self, $percy) = @_;
  my $dbh = $percy->dbh;

  $dbh->begin_work;
  $dbh->do('
    CREATE TABLE oid_storage (
      id         INTEGER  NOT NULL
          CONSTRAINT oid_storage_pk PRIMARY KEY AUTOINCREMENT,
      created_at INTEGER     NOT NULL,
      updated_at INTEGER     NOT NULL,
      type       VARCHAR(64) NOT NULL,
      data       BLOB        NOT NULL
    )
  ');

  $dbh->do('
    CREATE TABLE oid_map (
      pk         VARCHAR(64) NOT NULL,
      type       VARCHAR(64) NOT NULL,
      id         INTEGER NOT NULL,

      CONSTRAINT oid_map_pk PRIMARY KEY (pk, type)
    )
  ');
  $dbh->commit;
}

1;
