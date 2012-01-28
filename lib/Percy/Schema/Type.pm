package Percy::Schema::Type;

use Percy::Object;
use Percy::Utils qw( generate_uuid );
use JSON::XS qw( encode_json decode_json );
use namespace::clean -except => 'new';

## Setup type defaults - we basically force all attributes to their
## defaults values
sub BUILD {
  my ($self) = @_;

  $self->$_() for qw(generate_id_cb encode_to_db_cb decode_from_db_cb);
}


## Basic object attributes
has 'type' => (is => 'ro', required => 1);


## ID generation
has 'generate_id_cb' => (
  is      => 'ro',
  default => sub {
    sub { generate_uuid() }
  },
);

sub generate_id { return $_[0]{generate_id_cb}(@_) }


## Encode/decode data to/from DB
has 'encode_to_db_cb' => (
  is      => 'ro',
  default => sub {
    sub { encode_json($_[2]{d}) }
  },
);

has 'decode_from_db_cb' => (
  is      => 'ro',
  default => sub {
    sub { decode_json($_[2]) }
  },
);

sub encode_to_db   { return $_[0]{encode_to_db_cb}(@_) }
sub decode_from_db { return $_[0]{decode_from_db_cb}(@_) }


1;
