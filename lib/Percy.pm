package Percy;

# ABSTRACT: Small persistency layer for data structures
# VERSION
# AUTHORITY

use Percy::Object;
use Percy::Storage;
use namespace::clean;


## FIXME: connection stufff should be moved to Storage, eventually
has 'dbh' => (is => 'ro');


## Storage operations
sub deploy { return Percy::Storage->deploy(@_) }

1;
