package Percy::Storage::DBI::mysql;

# ABSTRACT: MySQL storage for Percy
# VERSION
# AUTHORITY

use Percy::Object;
use namespace::clean;

extends 'Percy::Storage::DBI';


sub deploy {
  my ($self) = @_;
  my $dbh = $self->dbh;

  $dbh->do('
    CREATE TABLE IF NOT EXISTS obj_storage (
      oid         INTEGER NOT NULL AUTO_INCREMENT,

      pk         VARBINARY(64) NOT NULL,
      type       VARBINARY(64) NOT NULL,

      data       BLOB        NOT NULL,

      CONSTRAINT obj_storage_pk PRIMARY KEY (oid),
      CONSTRAINT obj_storage_pk_type_un UNIQUE (pk, type)
    ) ENGINE = InnoDB
  ');
}

1;
