package Percy::Storage::DBI;

# ABSTRACT: Percy interface for a DBI storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use Class::Load ();
use Try::Tiny;
use namespace::clean;

extends 'Percy::Storage';

has '_dbh' => (is => 'rw');

## DB Operations
sub fetch {
  my ($self, $type, $pk) = @_;
  my $dbh = $self->dbh;

  my $r;
  if (defined $pk) {
    $r = {pk => $pk, type => $type, f => \&_dbi_obj_for_type_pk};
  }
  else {
    $type = $type->{oid} if ref($type);
    $r = {oid => $type, f => \&_dbi_obj_for_oid};
    $type = undef;
  }

  my $spec;
  if ($type) {
    $spec = _type_spec_for($self, $type);
    $spec->before_fetch($self, $r);
  }

  my @data = (delete $r->{f})->($dbh, $r);
  return unless @data;

  $spec = _type_spec_for($self, $data[1]);

  $r->{oid}  = $data[0];
  $r->{type} = $data[1];
  $r->{pk}   = $data[2];
  $r->{d}    = $spec->decode_from_db($self, $data[3]);

  $spec->after_fetch($self, $r);

  return $r;
}

sub create {
  my ($self, $type, $data, $pk) = @_;
  my $spec = _type_spec_for($self, $type);

  my $r;
  $self->tx(
    sub {
      my ($me, $dbh) = @_;

      $r = {
        d    => $data,
        pk   => $pk,
        oid  => undef,
        type => $type,
      };

      $pk = $r->{pk} = $spec->generate_id($self, $r)
        unless defined $pk;
      die "FATAL: failed to generate an PK for type '$type',"
        unless defined $pk;

      $spec->before_change($self, $r);
      $spec->before_create($self, $r);

      my $oid = $r->{oid} =
        _dbi_create_obj($dbh, $r, $spec->encode_to_db($self, $r));

      $spec->after_create($self, $r);
      $spec->after_change($self, $r);
    }
  );

  return $r;
}


## DBI shortcuts
sub _dbi_create_obj {
  my ($dbh, $r, $data) = @_;

  $dbh->do('
      INSERT INTO obj_storage
                 (pk, type, data)
          VALUES (?,  ?,    ?   )
  ', undef, $r->{pk}, $r->{type}, $data);
  return $dbh->last_insert_id(undef, undef, undef, undef);
}

sub _dbi_obj_for_type_pk {
  my ($dbh, $r) = @_;

  return $dbh->selectrow_array('
      SELECT oid, type, pk, data
        FROM obj_storage
       WHERE pk=?
         AND type=?
  ', undef, $r->{pk}, $r->{type});
}

sub _dbi_obj_for_oid {
  my ($dbh, $r) = @_;

  return $dbh->selectrow_array('
      SELECT oid, type, pk, data
        FROM obj_storage
       WHERE oid=?
  ', undef, $r->{oid});
}


## Shortcuts to the Schema type registry
sub _type_spec_for {
  my ($self, $type) = @_;

  my $spec = $self->schema->type_spec($type);
  die "FATAL: type '$type' not registered," unless defined $spec;

  return $spec;
}


## Builder
sub connect {
  my ($class, $schema, $dbh) = @_;

  my $type = $dbh->{Driver}{Name};
  my $driver_class = join('::', $class, $type);
  $class = $driver_class if Class::Load::try_load_class($driver_class);

  return $class->new(_dbh => $dbh, schema => $schema);
}


## DBI handle access
sub dbh {
  my ($self) = @_;
  my $dbh = $self->_dbh;

  $dbh = undef unless $dbh && $dbh->ping;

  unless (defined $dbh) {
    $dbh = $self->schema->connect_info->{connect}->($self);
    $self->_dbh($dbh);
  }

  return $dbh;
}


## Transactions
sub tx {
  my ($self, $cb, @rest) = @_;
  my $dbh = $self->dbh;

  unless ($dbh->ping) {
    $self->_dbh(undef);
    $dbh = $self->dbh;
  }

  $self->_tx_begin;
  try {
    $cb->($self, $dbh, @rest);
    $self->_tx_commit;
  }
  catch {
    $self->_tx_rollback;
    die $_;
  };

  return;
}

sub _tx_begin    { $_[0]->dbh->begin_work }
sub _tx_commit   { $_[0]->dbh->commit }
sub _tx_rollback { $_[0]->dbh->rollback }


1;
