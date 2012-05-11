package Percy::Storage::DBI;

# ABSTRACT: Percy interface for a DBI storage engine
# VERSION
# AUTHORITY

use Percy::Class;
use Class::Load ();
use Try::Tiny;
use Guard 'guard';
use Carp ();
use namespace::clean;

extends 'Percy::Storage';

has '_dbh' => (is => 'rw');

## DB Operations
sub fetch {
  my $self = shift;
  my $r = _parse_args($self, 'fetch', @_, {});

  my $spec;
  if (my $type = $r->{type}) {
    $spec = $self->_type_spec_for($type);
    $spec->before_fetch($self, $r);
  }

  my $dbh = $self->dbh;
  my @data = _dbi_fetch_obj($dbh, $r);
  return unless @data;

  ($r, $spec) = $self->build_doc(@data);

  $spec->after_fetch($self, $r);

  return $r;
}

sub create {
  my ($self, $type, $data, $pk) = @_;
  my $spec = $self->_type_spec_for($type);

  my $r;
  $self->tx(
    sub {
      my ($me, $dbh) = @_;

      $r = $self->build_doc(undef, $type, $pk, $data);

      $pk = $r->{pk} = $spec->generate_id($self, $r)
        unless defined $pk;
      Carp::confess("FATAL: failed to generate an PK for type '$type',")
        unless defined $pk;

      $spec->before_change($self, $r, 'create');
      $spec->before_create($self, $r);

      my $oid = $r->{oid} = _dbi_create_obj($dbh, $r, $spec->encode_to_db($self, $r));

      $spec->after_create($self, $r);
      $spec->after_change($self, $r, 'create');
    }
  );

  return $r;
}

sub update {
  my $self = shift;
  my $r = _parse_args($self, 'update', @_);

  my $rows;
  $self->tx(
    sub {
      my ($me, $dbh) = @_;

      my $type = _type_fetch($dbh, $r);
      return unless defined $type;

      my $spec = $self->_type_spec_for($type);

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
  my $r = _parse_args($self, 'delete', @_, {});

  my $rows;
  $self->tx(
    sub {
      my ($me, $dbh) = @_;

      my $type = _type_fetch($dbh, $r);
      return unless defined $type;

      my $spec = $self->_type_spec_for($type);

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
sub fetch_set {
  my ($self, $master, $set) = @_;
  my $set_spec = $self->schema->set_spec($master, $set);
  my $set_name = $set_spec->{set_name};

  my $set_elems;
  $self->tx(
    sub {
      my ($db, $dbh) = @_;
      my $sql = "
        SELECT docs.oid, docs.type, docs.pk, docs.data
          FROM $set_name sn
               JOIN obj_storage docs ON (docs.oid=sn.s_oid)
         WHERE sn.m_oid=?
      ";
      if (my $sb = $set_spec->{sorted_by}) {
        my $field = lc("f_$sb->{type}");
        $sql .= "  ORDER BY sn.$field";
      }

      $set_elems = $dbh->selectall_arrayref($sql, undef, $master->{oid});

      $_ = $self->build_doc(@$_) for @$set_elems;
    }
  );

  return $set_elems;
}

sub add_to_set {
  my ($self, $master, $set, $slave) = @_;

  $self->tx(
    sub {
      my $set_spec = $self->schema->set_spec($master, $set);
      $self->_associate_slave_to_set($_[1], $master, $set_spec, $slave);
    }
  );

  return $slave;
}

sub create_into_set {
  my ($self, $master, $set, $slave, $pk) = @_;

  $self->tx(
    sub {
      my $set_spec = $self->schema->set_spec($master, $set);

      $slave = $self->create($set_spec->{slave} => $slave => $pk);
      $self->_associate_slave_to_set($_[1], $master, $set_spec, $slave);
    }
  );

  return $slave;
}

sub _associate_slave_to_set {
  my ($self, $dbh, $master, $set_spec, $slave) = @_;
  my $set_name = $set_spec->{set_name};

  try {
    if (my $sb = $set_spec->{sorted_by}) {
      my $field = lc("f_$sb->{type}");
      $dbh->do("
          INSERT INTO $set_name (m_oid, s_oid, $field)
                         VALUES (?, ?, ?)
      ", undef, $master->{oid}, $slave->{oid},
        $sb->{field}->($self, $slave));

    }
    else {
      $dbh->do("
          INSERT INTO $set_name (m_oid, s_oid)
                         VALUES (?, ?)
      ", undef, $master->{oid}, $slave->{oid});
    }
  };

  # FIXME: catch duplicate inserts, ignore them; the rest rethrow
}

sub delete_from_set {
  my ($self, $master, $set, $slave) = @_;
  my $set_name = $self->schema->set_name($master, $set);

  my $r;
  $self->tx(
    sub {
      my ($db, $dbh) = @_;

      $r = $dbh->do("
        DELETE FROM $set_name
         WHERE m_oid=?
           AND s_oid=?",
        undef, $master->{oid}, $slave->{oid});
    }
  );

  return $r;
}


## Parser for parameters
sub _parse_args {
  my ($self, $meth, $a1, $a2, $a3) = @_;

  Carp::confess("FATAL: invalid arguments to $meth(),") unless defined($a1);

  # method($type => $pk => $data)
  return $self->build_doc(undef, $a1, $a2, $a3)
    if defined($a2) && defined($a3);

  # method($r)
  return $a1 if ref($a1);

  # method($oid => $data)
  return $self->build_doc($a1, undef, undef, $a2) if defined($a2);

  Carp::confess("FATAL: Could not parse arguments for '$meth',");
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
  Carp::confess("FATAL: insufficient conditions to identify a specific object,");
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


## Deploy
sub deploy {
  my $self = shift;

  my $stms1 = $self->_collect_obj_storage_table_stmts(@_);
  my $stms2 = $self->_collect_all_set_tables_stmts(@_);

  $self->_deploy_exec_sql_stmts(@$stms1, @$stms2);
}

sub _generate_table_stmts {
  my $class = ref($_[0]) || $_[0];

  Carp::confess("FATAL: redefine the _generate_table_stmts() method in '$class',");
}

sub _collect_obj_storage_table_stmts {
  my ($self) = @_;

  my $table = {
    name   => 'obj_storage',
    fields => [
      { name              => 'oid',
        type              => 'INTEGER NOT NULL',
        is_auto_increment => 1,
      },
      { name => 'pk',
        type => 'VARCHAR(64) NOT NULL',
      },
      { name => 'type',
        type => 'VARCHAR(64) NOT NULL',
      },
      { name => 'data',
        type => 'BLOB NOT NULL',
      },
    ],
    pk     => ['pk'],
    unique => { pk_type => [qw(pk type)] },
  };

  return $self->_generate_table_stmts($table);
}

sub _collect_all_set_tables_stmts {
  my $self = shift;
  my $sets = $self->schema->sets;

  my @stmts;
  for my $spec (sort { $a->{set_name} cmp $b->{set_name} } values %$sets) {
    my $set_stmts = $self->_collect_set_table_stmts($spec, @_);
    push @stmts, @$set_stmts;
  }

  return \@stmts;
}

sub _collect_set_table_stmts {
  my ($self, $set_spec) = @_;
  my $sn = $set_spec->{set_name};

  my $table = {
    name   => $sn,
    fields => [
      { name => 'm_oid',
        type => 'INTEGER NOT NULL',
      },
      { name => 's_oid',
        type => 'INTEGER NOT NULL',
      },
    ],
    pk => [qw(m_oid s_oid)],
  };

  if (my $order = $set_spec->{sorted_by}) {
    my $type = $order->{type} || 'Integer';
    my $field = lc("f_$order->{type}");
    $type = 'VARCHAR(100)' if $type eq 'String';
    $type = uc($type);

    push @{ $table->{fields} }, { name => $field, type => "$type NOT NULL" };
    $table->{indexes}{$sn} = ['m_oid', $field];
  }

  return $self->_generate_table_stmts($table);
}

sub _deploy_exec_sql_stmts {
  my $self = shift;

  if (my $spec = $ENV{PERCY_DEPLOY_SQL_DUMP}) {
    my $sql = join(";\n\n", map { s/\A\s+|\s+\Z//gsm; $_ } @_) . ";\n\n";

    if (my ($fn) = $spec =~ m/^=(.+)$/) {
      open(my $fh, '>>', $fn)
        or die "FATAL: Could not open deploy SQL dump file '$fn': $!,";
      print $fh $sql . ";\n\n";
      close($fh);
    }
    else {
      print STDERR "[$$] Percy deploy() SQL:\n$sql\n\n";
    }
  }
  else {
    for my $stmt (@_) {
      eval { $self->dbh->do($stmt) };
      die "FATAL: SQL deploy failed: $stmt - $@\n" if $@;
    }
  }
}


1;
