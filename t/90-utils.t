#!perl

use lib 't/lib';
use MyTests;
use Test::More;
use Percy::Utils qw(generate_uuid);

subtest 'generate_uuid' => sub {
  my $uuid = generate_uuid();
  like(
    $uuid,
    qr{^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$},
    'Proper UUID format',
  );
};

done_testing();
