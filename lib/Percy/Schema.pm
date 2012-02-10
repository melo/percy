package Percy::Schema;

# ABSTRACT: Percy interface with the storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use Percy::Schema::Type;
use namespace::clean;

has 'types' => (is => 'ro', default => sub { {} });
has 'sets'  => (is => 'ro', default => sub { {} });
has 'db'    => (is => 'ro', builder => '_build_db');


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


## Set management
sub set_name {
  my ($self, $type, $set) = @_;
  $type = $type->{type} if ref $type;

  return join('_', $type, $set, 'set');
}

sub set_spec {
  my ($self, $master, $set) = @_;
  my $set_name = $master;
  $set_name = $self->set_name($master, $set) if defined $set;

  my $sets = $self->sets;
  return unless exists $sets->{$set_name};
  return $sets->{$set_name};
}


## Type specification management
sub type_spec {
  my ($self, $type, $spec) = @_;
  my $types = $self->types;
  my $sets  = $self->sets;

  if ($spec) {
    my $t = Percy::Schema::Type->new(%$spec, type => $type);
    my $type_sets = $t->sets;

    for my $sn (keys %$type_sets) {
      my $si = $type_sets->{$sn};
      my $fsn = $self->set_name($type, $sn);
      $si->{master}   = $type;
      $si->{set_name} = $fsn;
      $sets->{$fsn}   = $si;

      if (my $sb = $si->{sorted_by}) {
        my $f = $sb->{field};
        $sb->{field} = sub { return $_[1]{d}{$f} }
          unless ref $f;
      }
    }

    return $types->{$type} = $t;
  }

  return $self->default_type_spec($type) unless exists $types->{$type};
  return $types->{$type};
}

sub default_type_spec { }


1;
