package Percy::Storage::DBI;

# ABSTRACT: Percy interface for a DBI storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use Class::Load ();
use Try::Tiny;
use Guard 'guard';
use namespace::clean;

extends 'Percy::Storage';

has '_dbh' => (is => 'rw');

## DB Operations
sub fetch {
  my $self = shift;
  my $r = _parse_args('fetch', @_, 'no_data');

  my $spec;
  if (my $type = $r->{type}) {
    $spec = _type_spec_for($self, $type);
    $spec->before_fetch($self, $r);
  }

  my $dbh = $self->dbh;
  my @data = _dbi_fetch_obj($dbh, $r);
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

      $spec->before_change($self, $r, 'create');
      $spec->before_create($self, $r);

      my $oid = $r->{oid} =
        _dbi_create_obj($dbh, $r, $spec->encode_to_db($self, $r));

      $spec->after_create($self, $r);
      $spec->after_change($self, $r, 'create');
    }
  );

  return $r;
}

sub update {
  my $self = shift;
  my $r = _parse_args('update', @_);

  my $rows;
  $self->tx(
    sub {
      my ($me, $dbh) = @_;

      my $type = _type_fetch($dbh, $r);
      return unless defined $type;

      my $spec = _type_spec_for($self, $type);

      $spec->before_change($self, $r, 'update');
      $spec->before_update($self, $r);

      $rows = _dbi_update_obj($dbh, $r, $spec->encode_to_db($self, $r));

      $spec->after_update($self, $r);
      $spec->after_change($self, $r, 'update');
    }
  );

  return $rows;
}

sub delete {
  my $self = shift;
  my $r = _parse_args('delete', @_, 'no data');

  my $rows;
  $self->tx(
    sub {
      my ($me, $dbh) = @_;

      my $type = _type_fetch($dbh, $r);
      return unless defined $type;

      my $spec = _type_spec_for($self, $type);

      $spec->before_change($self, $r, 'delete');
      $spec->before_delete($self, $r);

      $rows = _dbi_delete_obj($dbh, $r);

      $spec->after_delete($self, $r);
      $spec->after_change($self, $r, 'delete');
    }
  );

  return $rows;
}


## Set operations
sub add_to_set {
  my ($self, $master, $set, $slave) = @_;
  my $schema   = $self->schema;
  my $set_spec = $schema->set_spec($master, $set);
  my $set_name = $set_spec->{set_name};

  $slave->{$set_name} = {
    pk   => $master->{pk},
    type => $master->{type},
  };

  $self->tx(
    sub {
      my ($si, $dbh) = @_;

      $slave = $self->create($set_spec->{slave} => $slave);

      $dbh->do("
        INSERT INTO $set_name (m_oid, s_oid) VALUES (?, ?)
      ", undef, $master->{oid}, $slave->{oid});
    }
  );

  return $slave;
}


## Parser for parameters
sub _parse_args {
  my ($meth, $a1, $a2, $a3) = @_;

  die "FATAL: invalid arguments to $meth()," unless defined($a1);

  # method($type => $pk => $data)
  return {type => $a1, pk => $a2, d => $a3}
    if defined($a2) && defined($a3);

  # method($r)
  return $a1 if ref($a1);

  # method($oid => $data)
  return {oid => $a1, d => $a2} if defined($a2);

  die "FATAL: Could not parse arguments for '$meth',";
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

sub _dbi_update_obj {
  my ($dbh, $conds, $data) = @_;
  my ($sql, @bind) = _dbi_obj_where('
      UPDATE obj_storage SET data=?
  ', $conds);

  return $dbh->do($sql, undef, $data, @bind);
}

sub _dbi_delete_obj {
  my ($dbh, $conds) = @_;
  my ($sql, @bind)  = _dbi_obj_where('
      DELETE FROM obj_storage
  ', $conds);

  return $dbh->do($sql, undef, @bind);
}

sub _dbi_fetch_obj {
  my ($dbh, $conds) = @_;
  my ($sql, @bind)  = _dbi_obj_where('
      SELECT oid, type, pk, data
        FROM obj_storage
  ', $conds);

  return $dbh->selectrow_array($sql, undef, @bind);
}

sub _dbi_fetch_obj_meta {
  my ($dbh, $conds) = @_;
  my ($sql, @bind)  = _dbi_obj_where('
      SELECT oid, type, pk
        FROM obj_storage
  ', $conds);

  return $dbh->selectrow_array($sql, undef, @bind);
}

sub _dbi_obj_where {
  my ($sql, $r) = @_;

  return ("$sql WHERE oid=?", $r->{oid}) if defined $r->{oid};
  return ("$sql WHERE type=? AND pk=?", $r->{type}, $r->{pk})
    if defined $r->{type} && defined $r->{pk};
  die "FATAL: insufficient conditions to identify a specific object,";
}

sub _type_fetch {
  my ($dbh, $r) = @_;

  my $type = $r->{type};
  unless (defined $type) {
    my @data = _dbi_fetch_obj_meta($dbh, $r);
    return unless @data;

    $r->{oid} = $data[0];
    $type = $r->{type} = $data[1];
    $r->{pk} = $data[2];
  }

  return $type;
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

  my $tx = ++$self->{_tx};
  my $g = guard { --$self->{_tx} };
  return $cb->($self, $dbh, @rest) if $tx > 1;

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
    my $e = $_;
    $self->_tx_rollback;
    die $e;
  };

  return;
}

sub _tx_begin    { $_[0]->dbh->begin_work }
sub _tx_commit   { $_[0]->dbh->commit }
sub _tx_rollback { $_[0]->dbh->rollback }


1;
