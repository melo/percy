package Percy::Storage::DBI;

# ABSTRACT: Percy interface for a DBI storage
# VERSION
# AUTHORITY

use Percy::Object;
use Class::Load ();
use Try::Tiny;
use namespace::clean;

extends 'Percy::Storage';

has 'dbh' => (is => 'rw', default => sub { shift->schema->connect() });


## Builder
sub connect {
  my ($class, $schema, $dbh) = @_;

  my $type = $dbh->{Driver}{Name};
  my $driver_class = join('::', $class, $type);
  $class = $driver_class if Class::Load::try_load_class($driver_class);

  return $class->new(dbh => $dbh, schema => $schema);
}


## Transactions
sub tx {
  my ($self, $cb, @rest) = @_;
  my $dbh = $self->dbh;

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
