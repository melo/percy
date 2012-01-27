package Percy::Storage::DBI::SQLite;

# ABSTRACT: SQLite storage for Percy
# VERSION
# AUTHORITY

use Percy::Object;
use namespace::clean;

extends 'Percy::Storage::DBI';


sub deploy {
  my ($self) = @_;
  my $dbh = $self->dbh;

  $dbh->begin_work;
  $dbh->do('
    CREATE TABLE oid_storage (
      id         INTEGER  NOT NULL
          CONSTRAINT oid_storage_pk PRIMARY KEY,
      created_at INTEGER     NOT NULL,
      updated_at INTEGER     NOT NULL,
      type       VARCHAR(64) NOT NULL,
      data       BLOB        NOT NULL
    )
  ');

  $dbh->do('
    CREATE TABLE oid_map (
      id         INTEGER NOT NULL
          CONSTRAINT oid_map_pk PRIMARY KEY AUTOINCREMENT,
      pk         VARCHAR(64) NOT NULL,
      type       VARCHAR(64) NOT NULL,

      CONSTRAINT oid_map_pk_type_un UNIQUE (pk, type)
    )
  ');
  $dbh->commit;
}

1;
