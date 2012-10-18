package Percy::Schema::AddOns::DBI::MapTable;

use Percy::Role;

before '_tweak_type_spec' => sub {
  my ($self, $spec) = @_;
  return unless exists $spec->{map_table};

  my $it   = delete $spec->{map_table};
  my $key  = $it->{key};
  my $tbl  = $it->{name};
  my $flds = $it->{fields};

  $flds = {} unless $flds;
  if (ref($flds) eq 'ARRAY') {
    my %fields;
    while (@$flds) {
      my $name = shift @$flds;
      my $spec = $name;
      $spec = shift @$flds if @$flds && ref($flds->[0]);
      $fields{$name} = $spec;
    }
    $flds = \%fields;
  }
  $flds->{$key} = $key;

  my $fa = sub {
    my ($r, $spec) = @_;
    return ref($spec) ? $spec->($r) : $r->{d}{$spec};
  };

  my @fns = keys %$flds;
  my @bnd = values %$flds;
  my $chg_s =
      "INSERT INTO $tbl ("
    . join(', ', @fns) . ')'
    . ' VALUES ('
    . join(', ', ('?') x @fns) . ')'
    . ' ON DUPLICATE KEY UPDATE '
    . join(', ', map {"$_=?"} @fns);
  my $del_s = "DELETE FROM $tbl WHERE $key=?";

  $spec->{generate_id_cb} = sub { return $_[2]{d}{$key} };

  for my $hook (qw( create update )) {
    my $list = $spec->{"after_${hook}_cb"} ||= [];
    push @$list, sub {
      my ($type, $db, $r) = @_;
      my @i_bnd = map { $fa->($r, $_) } @bnd;
      return $db->_dbh->do($chg_s, undef, @i_bnd, @i_bnd);
    };
  }

  my $dcbs = $spec->{after_delete_cb} ||= [];
  unshift @$dcbs, sub {
    my ($type, $db, $r) = @_;
    $db->_dbh->do($del_s, undef, $_[2]{pk});
  };
};


1;
