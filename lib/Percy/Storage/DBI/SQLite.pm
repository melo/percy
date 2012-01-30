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
    CREATE TABLE obj_storage (
      oid        INTEGER  NOT NULL
          CONSTRAINT obj_storage_pk PRIMARY KEY AUTOINCREMENT,

      pk         VARCHAR(64) NOT NULL,
      type       VARCHAR(64) NOT NULL,

      data       BLOB        NOT NULL,

      CONSTRAINT obj_storage_pk_type_un UNIQUE (pk, type)
    )
  ');
  $dbh->commit;
}

1;
