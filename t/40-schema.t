#!perl

use Test::More;
use Test::Fatal;
use lib 't/lib';
use MySchema;

subtest 'instances' => sub {
  my $i1 = MySchema->schema;
  my $i2 = MySchema->schema;

  is("$i1", "$i2", 'Multiple calls to ->schema return same instance');
};


subtest 'type registry' => sub {
  my $si = MySchema->schema;

  my $t1;
  is(exception { $t1 = $si->type_spec('my_type') },
    undef, "With missing type, type_spec() doesn't die");
  is($t1, undef, "... and returns undef");

  my $t2;
  is(exception { $t2 = $si->type_spec(my_type => {}) },
    undef, "type_spec() doesn't die when adding a new one");
  isa_ok($t2, 'Percy::Schema::Type', '... returns object of the proper type');
  is($t2->type, 'my_type', '... with the expected type name');

  my $t3;
  is(exception { $t3 = $si->type_spec('my_type') },
    undef, 'With a existing type, type_spec() lives');
  is($t3->type, 'my_type', '... expected type attr');
  is("$t2", "$t3", '... with the same object we got when adding the type');
};


subtest 'db' => sub {
  my $si = MySchema->schema;

  my $db1 = $si->db;
  isa_ok($db1, 'Percy::Storage::DBI');

  my $db2 = $si->db;
  is($db1, $db2, 'db() returns the same instance');

  is($si, $db1->schema,
    'DB objects have a reference to the schema who created them');
};


done_testing();
