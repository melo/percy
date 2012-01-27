package Percy::Schema;

# ABSTRACT: Percy interface with the storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use Percy::Schema::Type;
use namespace::clean;

has 'types' => (is => 'ro', default => sub { {} });

## Singleton management
{
  my %instances;

  sub schema {
    my ($class) = @_;
    $class = ref($class) if ref($class);

    return $instances{$class} ||= $class->new;
  }
}


## Type specification management
sub type_spec {
  my ($self, $type, $spec) = @_;
  my $types = $self->types;

  return $types->{$type} = Percy::Schema::Type->new(%$spec, type => $type)
    if $spec;

  return unless exists $types->{$type};
  return $types->{$type};
}


1;
