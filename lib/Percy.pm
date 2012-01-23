package Percy;

# ABSTRACT: Small persistency layer for data structures
# VERSION
# AUTHORITY

use Percy::Object;
use Percy::Storage;
use JSON::XS qw( encode_json decode_json );
use namespace::clean;


## FIXME: connection stufff should be moved to Storage, eventually
has 'dbh' => (is => 'ro');


## Serialization
sub encode_to_db   { return encode_json($_[1]) }
sub decode_from_db { return decode_json($_[1]) }


## Storage operations
sub deploy { return Percy::Storage->deploy(@_) }

1;
