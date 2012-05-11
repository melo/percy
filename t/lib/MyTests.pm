package MyTests;

use Percy::Class;
use MySchema;

## Export our builder function
sub import {
  warnings->import;
  strict->import;

  my $target = caller();

  no strict 'refs';
  *{$target . '::test_percy_schema'} = \&_build_test_percy_schema;
}

sub _build_test_percy_schema {
  my $schema = MySchema->schema;
  $schema->db->deploy;

  return $schema;
}


__PACKAGE__->meta->make_immutable;
1;
