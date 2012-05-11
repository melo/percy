package Percy::Utils;

# ABSTRACT: Utilities for our Percy stuff
# VERSION
# AUTHORITY

use strict;
use warnings;
use parent 'Exporter';
use Class::Load 'try_load_class';

our @EXPORT_OK = qw(
  calc_set_name
  generate_uuid
);


## Table name builders
sub calc_set_name {
  my ($type, $set) = @_;
  $type = $type->{type} if ref $type;

  return join('_', $type, $set, 'set');
}


## ID management
{
  my $id_gen_cb;

  if (try_load_class('Data::UUID::LibUUID')) {
    $id_gen_cb = sub { Data::UUID::LibUUID::new_uuid_string() };
  }
  elsif (try_load_class('Data::UUID')) {
    my $uuid_gen = Data::UUID->new;
    $id_gen_cb = sub { $uuid_gen->create_str };
  }
  else {
    die "Could not find UUID class (Data::UUID::LibUUID or Data::UUID)",;
  }

  sub generate_uuid {
    return $id_gen_cb->();
  }
}


1;
