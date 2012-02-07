package Percy::Storage;

# ABSTRACT: Percy interface with the storage engine
# VERSION
# AUTHORITY

use Percy::Object;
use namespace::clean;

has 'schema' => (is => 'ro', required => 1);

sub connect {
  my $class = ref($_[0]) || $_[0];

  die "FATAL: redefine the connect() method in '$class',";
}

## Deploy
sub deploy {
  my $self = shift;

  $self->_deploy_obj_storage_table(@_);
  $self->deploy_set_tables(@_);
}

sub deploy_set_tables {
  my $self = shift;
  my $sets = $self->schema->sets;

  for my $set_spec (values %$sets) {
    $self->_deploy_set_table($set_spec, @_);
  }
}

sub _deploy_obj_storage_table {
  my $class = ref($_[0]) || $_[0];

  die "FATAL: redefine the _deploy_obj_storage_table() method in '$class',";
}

sub _deploy_set_table {
  my ($self, $set_spec) = @_;

  my $sn = $set_spec->{set_name};
  $self->_deploy_table("
    CREATE TABLE IF NOT EXISTS $sn (
      m_oid        INTEGER NOT NULL,
      s_oid        INTEGER NOT NULL,

      CONSTRAINT ${sn}_pk PRIMARY KEY (m_oid, s_oid)
    )
  ");
}

sub _deploy_table {
  my ($self, $sql) = @_;

  if (my $spec = $ENV{PERCY_DEPLOY_SQL_DUMP}) {
    if (my ($fn) = $spec =~ m/^=(.+)$/) {
      open(my $fh, '>>', $fn)
        or die "FATAL: Could not open deploy SQL dump file '$fn': $!,";
      print $fh $sql . ";\n\n";
      close($fh);
    }
    else {
      print STDERR "[$$] Percy deploy() SQL:\n$sql\n\n";
    }
  }
  else {
    $self->dbh->do($sql);
  }
}


1;
