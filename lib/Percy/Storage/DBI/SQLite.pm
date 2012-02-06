package Percy::Storage::DBI::SQLite;

# ABSTRACT: SQLite storage for Percy
# VERSION
# AUTHORITY

use Percy::Object;
use namespace::clean;

extends 'Percy::Storage::DBI';


sub _deploy_obj_storage_table {
  my ($self) = @_;
  my $dbh = $self->dbh;

  $dbh->do('
    CREATE TABLE IF NOT EXISTS obj_storage (
      oid        INTEGER  NOT NULL
          CONSTRAINT obj_storage_pk PRIMARY KEY AUTOINCREMENT,

      pk         VARCHAR(64) NOT NULL,
      type       VARCHAR(64) NOT NULL,

      data       BLOB        NOT NULL,

      CONSTRAINT obj_storage_pk_type_un UNIQUE (pk, type)
    )
  ');
}

sub _deploy_set_table {
  my ($self, $set_spec) = @_;
  my $dbh = $self->dbh;

  my $sn = $set_spec->{set_name};
  $dbh->do("
    CREATE TABLE IF NOT EXISTS $sn (
      m_oid        INTEGER NOT NULL,
      s_oid        INTEGER NOT NULL,

      CONSTRAINT ${sn}_pk PRIMARY KEY (m_oid, s_oid)
    )
  ");
}


1;
