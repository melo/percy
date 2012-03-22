package Percy::Storage::DBI::mysql;

# ABSTRACT: MySQL storage for Percy
# VERSION
# AUTHORITY

use Percy::Object;
use namespace::clean;

extends 'Percy::Storage::DBI';


sub _generate_table_stmts {
  my ($self, $table) = @_;
  my @sql_stmts;
  my $pks = $table->{pk} || [];

  ## Table
  my $tn  = $table->{name};
  my $tbl = "CREATE TABLE IF NOT EXISTS $tn (\n";

  my @fields;
  for my $f (@{ $table->{fields} }) {
    push @fields, "  $f->{name}  $f->{type}";
    $fields[-1] .= " PRIMARY KEY AUTO_INCREMENT" if $f->{is_auto_increment};
  }
  $tbl .= join(",\n", @fields);

  if (@$pks > 1) {
    $tbl .= ",\n\n  CONSTRAINT ${tn}_pk PRIMARY KEY (" . join(', ', @{ $table->{pk} }) . ")";
  }

  ## Indexes
  while (my ($in, $if) = each %{ $table->{indexes} || {} }) {
    $tbl .= ",\n  INDEX ${tn}_${in}_idx (" . join(', ', @$if) . ")";
  }

  ## Unique keys
  while (my ($un, $uf) = each %{ $table->{unique} || {} }) {
    $tbl .= ",\n  CONSTRAINT ${tn}_${un}_un UNIQUE (" . join(', ', @$uf) . ")";
  }
  $tbl .= "\n) ENGINE = InnoDB\n";

  return [$tbl];
}

1;
