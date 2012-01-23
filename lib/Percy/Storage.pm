package Percy::Storage;

# ABSTRACT: Percy interface with the storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use Class::Load 'try_load_class';
use namespace::clean;


sub deploy {
  my ($class, $percy, @rest) = @_;
  my $type = $percy->dbh->{Driver}{Name};

  my $driver_class = join('::', $class, $type);
  $class = $driver_class if try_load_class($driver_class);

  $class->_deploy_tables($percy, @rest);
}

sub _deploy_tables {
  my ($class) = @_;

  die "No default _deploy_tables() for class $class,";
}

1;
