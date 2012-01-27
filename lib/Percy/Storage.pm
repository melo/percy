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

sub deploy {
  my $class = ref($_[0]) || $_[0];

  die "FATAL: redefine the deploy() method in '$class',";
}

1;
