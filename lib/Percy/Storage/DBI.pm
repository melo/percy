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


1;
