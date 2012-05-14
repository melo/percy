package Percy::Schema::AddOns::DBI::IDTable;

use Percy::Role;

before '_tweak_type_spec' => sub {
  my ($self, $spec) = @_;
  return unless exists $spec->{id_table};

  my $it   = delete $spec->{id_table};
  my $key  = $it->{key};
  my $tbl  = $it->{name};
  my $flds = $it->{fields};

  my @fns   = keys %$flds;
  my @bnd   = values %$flds;
  my $ins_s = "INSERT INTO $tbl (" . join(', ', @fns) . ') VALUES (' . join(', ', ('?') x @bnd) . ")";
  my $upd_s = "UPDATE $tbl SET " . join(', ', map {"$_=?"} @fns) . " WHERE $key=?";
  my $del_s = "DELETE FROM $tbl WHERE $key=?";

  $spec->{generate_id_cb} = sub {
    my ($type, $db, $r) = @_;

    my $dbh = $db->_dbh;
    $dbh->do($ins_s, undef, map { ref($_) ? $_->($r) : $r->{d}{$_} } @bnd);
    return $dbh->last_insert_id(undef, undef, undef, undef);
  };

  my $ucbs = $spec->{after_update_cb} ||= [];
  unshift @$ucbs, sub {
    my ($type, $db, $r) = @_;

    $db->_dbh->do($upd_s, undef, (map { ref($_) ? $_->($r) : $r->{d}{$_} } @bnd), $r->{pk});
  };

  my $dcbs = $spec->{after_delete_cb} ||= [];
  unshift @$dcbs, sub {
    my ($type, $db, $r) = @_;

    $db->_dbh->do($del_s, undef, $r->{pk});
  };
};


1;
