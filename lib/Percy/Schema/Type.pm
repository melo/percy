package Percy::Schema::Type;

# ABSTRACT: Percy schema types
# VERSION
# AUTHORITY

use Percy::Class;
use Percy::Utils qw( generate_uuid );
use JSON::XS qw( encode_json decode_json );


## Basic object attributes
has 'type' => (required => 1);


## ID generation
has 'generate_id_cb' => (
  default => sub {
    sub { generate_uuid() }
  },
);

sub generate_id { return $_[0]{generate_id_cb}(@_) }


## Encode/decode data to/from DB
has 'encode_to_db_cb' => (
  default => sub {
    sub { encode_json($_[2]{d}) }
  },
);

has 'decode_from_db_cb' => (
  default => sub {
    sub { decode_json($_[2]) }
  },
);

sub encode_to_db   { return $_[0]{encode_to_db_cb}(@_) }
sub decode_from_db { return $_[0]{decode_from_db_cb}(@_) }


## Sets
has 'sets' => (default => sub { {} });


## DB callbacks
my $meta = __PACKAGE__->meta;
for my $w (qw(before after)) {
  for my $e (qw(change create update delete fetch)) {
    my $meth = "${w}_${e}";
    my $attr = "${meth}_cb";

    $meta->add_attribute(
      $attr => (
        default => sub {
          sub { }
        }
      )
    );
    $meta->add_method($meth => sub { return $_[0]->$attr->(@_) });
  }
}
$meta->make_immutable;

1;
