package Percy::Storage;

# ABSTRACT: Percy interface with the storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use namespace::clean;

has 'schema' => (is => 'ro', required => 1);

sub connect {
  my $class = ref($_[0]) || $_[0];

  die "FATAL: redefine the connect() method in '$class',";
}

## Deploy
sub deploy {
  my $self = shift;

  $self->_deploy_obj_storage_table(@_);
}

sub _deploy_obj_storage_table {
  my $class = ref($_[0]) || $_[0];

  die "FATAL: redefine the _deploy_obj_storage_table() method in '$class',";
}

1;
