package Percy::Schema;

# ABSTRACT: Percy interface with the storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use namespace::clean;

## Singleton management
{
  my %instances;

  sub schema {
    my ($class) = @_;
    $class = ref($class) if ref($class);

    return $instances{$class} ||= $class->new;
  }
}


1;
