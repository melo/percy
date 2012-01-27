package MyTests;

use Percy::Object;
use MySchema;
use namespace::clean;

## Export our builder function
sub import {
  my $target = caller();

  no strict 'refs';
  *{$target . '::test_percy_schema'} = \&_build_test_percy_schema;
}

sub _build_test_percy_schema {
  my $schema = MySchema->schema;
  $schema->db->deploy;

  return $schema;
}


1;
