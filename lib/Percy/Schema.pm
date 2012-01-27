package Percy::Schema;

# ABSTRACT: Percy interface with the storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use Percy::Schema::Type;
use namespace::clean;

has 'types' => (is => 'ro', default => sub { {} });
has 'db' => (is => 'ro', builder => '_build_db');


## Singleton management
{
  my %instances;

  sub schema {
    my ($class) = @_;
    $class = ref($class) if ref($class);

    return $instances{$class} ||= $class->new;
  }
}


## DB connection
sub _build_db {
  my ($self) = @_;
  my $info = $self->connect_info;

  my $s_class = $info->{type};
  my $conn    = $info->{connect}->($self);

  if (!$s_class) {
    ## FIXME: Move storage class discovery to a Module::Pluggable setup
    if ($conn->isa('DBI::db')) {
      $s_class = 'DBI';
    }
  }

  die "FATAL: storage calss unknown, use 'type' attr on connect_info(),"
    unless $s_class;

  $s_class = "Percy::Storage::$s_class" unless $s_class =~ s/^[+]//;
  Class::Load::load_class($s_class);

  return $s_class->connect($self, $conn);
}

sub connect_info {
  my $class = ref($_[0]) || $_[0];

  die "FATAL: redefine the connect_info() method in '$class',";
}


## Type specification management
sub type_spec {
  my ($self, $type, $spec) = @_;
  my $types = $self->types;

  return $types->{$type} = Percy::Schema::Type->new(%$spec, type => $type)
    if $spec;

  return unless exists $types->{$type};
  return $types->{$type};
}


1;
