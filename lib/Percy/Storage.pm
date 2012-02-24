package Percy::Storage;

# ABSTRACT: Percy interface with the storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use namespace::clean;

has 'schema' => (is => 'ro', required => 1);

##########
# Builders

sub connect {
  my $class = ref($_[0]) || $_[0];

  die "FATAL: redefine the connect() method in '$class',";
}


################
# Deployment API

sub deploy {
  my $class = ref($_[0]) || $_[0];

  die "FATAL: redefine the deploy() method in '$class',";
}


#################
# Type access API

sub _type_spec_for {
  my ($self, $type) = @_;
  Carp::confess("FATAL: undefined type") unless defined $type;

  my $spec = $self->schema->type_spec($type);
  Carp::confess "FATAL: type '$type' not registered," unless defined $spec;

  return $spec;
}


1;
