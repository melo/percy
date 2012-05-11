package Percy::Storage::DBI::SQLite;

# ABSTRACT: SQLite storage for Percy
# VERSION
# AUTHORITY

use Percy::Class;

extends 'Percy::Storage::DBI';


sub _generate_table_stmts {
  my ($self, $table) = @_;
  my @sql_stmts;

  ## Table
  my $skip_pk;
  my $tn  = $table->{name};
  my $tbl = "CREATE TABLE IF NOT EXISTS $tn (\n";
  for my $f (@{ $table->{fields} }) {
    $tbl .= ",\n" if $skip_pk;
    $tbl .= "  $f->{name}  $f->{type}";
    if ($f->{is_auto_increment}) {
      $tbl .= "\n      CONSTRAINT ${tn}_pk PRIMARY KEY AUTOINCREMENT";
      $skip_pk++;
    }
    $tbl .= ",\n" unless $skip_pk;
  }

  if (!$skip_pk) {
    $tbl .= "\n  CONSTRAINT ${tn}_pk PRIMARY KEY (" . join(', ', @{ $table->{pk} }) . ")\n";
  }
  $tbl .= ')';
  push @sql_stmts, $tbl;

  ## Indexes
  while (my ($in, $if) = each %{ $table->{indexes} || {} }) {
    push @sql_stmts,
      "CREATE INDEX IF NOT EXISTS ${tn}_${in}_idx" . " ON $tn (" . join(', ', @$if) . ")";
  }

  ## Unique keys
  while (my ($un, $uf) = each %{ $table->{unique} || {} }) {
    push @sql_stmts,
      "CREATE UNIQUE INDEX IF NOT EXISTS ${tn}_${un}_un" . " ON $tn (" . join(', ', @$uf) . ")";
  }

  return \@sql_stmts;
}

__PACKAGE__->meta->make_immutable;
1;
