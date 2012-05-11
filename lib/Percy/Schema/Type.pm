package Percy::Schema::Type;

# ABSTRACT: Percy schema types
# VERSION
# AUTHORITY

use Percy::Class;
use Percy::Utils qw( generate_uuid calc_set_name );
use JSON::XS qw( encode_json decode_json );

## Post-build work
sub BUILD { shift->_cleanup_sets }


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

sub _cleanup_sets {
  my ($self)    = @_;
  my $type      = $self->type;
  my $type_sets = $self->sets;

  for my $sn (keys %$type_sets) {
    my $si = $type_sets->{$sn};
    my $fsn = calc_set_name($type, $sn);
    $si->{master}   = $type;
    $si->{set_name} = $fsn;

    if (my $sb = $si->{sorted_by}) {
      my $f = $sb->{field};
      $sb->{field} = sub { return $_[1]{d}{$f} }
        unless ref $f;
    }
  }
}


## DB callbacks
{
  my @db_callbacks;

  my $meta = __PACKAGE__->meta;
  for my $w (qw(before after)) {
    for my $e (qw(change create update delete fetch)) {
      my $meth = "${w}_${e}";
      my $attr = "${meth}_cb";

      $meta->add_attribute($attr => (default => sub { [] }));
      $meta->add_method($meth => sub { $_->(@_) for @{ $_[0]->$attr }; return });
      $meta->add_method("add_$attr" => sub { push @{ shift->$attr }, @_ });

      push @db_callbacks, $attr;
    }
  }

  around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = @_ == 1 ? $_[0] : {@_};

    for my $cb (@db_callbacks) {
      $args->{$cb} = [$args->{$cb}] if exists $args->{$cb} && ref($args->{$cb}) ne 'ARRAY';
    }

    return $class->$orig($args);
  };

  $meta->make_immutable;
}

1;
