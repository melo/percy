package Percy::Storage;

# ABSTRACT: Percy interface with the storage engine
# VERSION
# AUTHORITY

use Percy::Class;

has 'schema' => (required => 1);

##########
# Builders

sub connect {
  my $class = ref($_[0]) || $_[0];

  die "FATAL: redefine the connect() method in '$class',";
}

sub build_doc {
  my ($self, $oid, $type, $pk, $data) = @_;
  my %r;

  if (ref($oid)) {
    $pk   = delete $oid->{pk};
    $type = delete $oid->{type};
    $data = delete $oid->{data};
    $oid  = delete $oid->{oid};
  }

  my $spec;
  if (!ref($data)) {
    $spec = $self->_type_spec_for($type);

    try { $data = $spec->decode_from_db($self, $data) }
    catch { die "FATAL: failed decode_from_db() for $type/$pk - $_" };
  }

  $r{oid}  = $oid;
  $r{type} = $type;
  $r{pk}   = $pk;
  $r{d}    = $data;

  return (\%r, $spec) if wantarray;
  return \%r;
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


__PACKAGE__->meta->make_immutable;
1;
