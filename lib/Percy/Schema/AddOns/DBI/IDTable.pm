package Percy::Schema::AddOns::DBI::IDTable;

use Percy::Role;

before '_tweak_type_spec' => sub {
  my ($self, $spec) = @_;
  return unless exists $spec->{id_table};

  my $it   = delete $spec->{id_table};
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

  my @fns   = keys %$flds;
  my @bnd   = values %$flds;
  my $ins_s = "INSERT INTO $tbl (" . join(', ', $key, @fns) . ') VALUES (' . join(', ', '?', ('?') x @bnd) . ")";
  my $upd_s = "UPDATE $tbl SET " . join(', ', map {"$_=?"} @fns) . " WHERE $key=?";
  my $del_s = "DELETE FROM $tbl WHERE $key=?";

  $spec->{generate_id_cb} = sub {
    my ($type, $db, $r) = @_;

    my $id = $it->{migrate_ok} ? $r->{d}{$key} : undef;

    my $dbh = $db->_dbh;
    $dbh->do($ins_s, undef, $id, map { ref($_) ? $_->($r) : $r->{d}{$_} } @bnd);

    $id = $dbh->last_insert_id(undef, undef, undef, undef) unless $id;
    $r->{d}{$key} = $id;

    return $id;
  };

  unless ($it->{id_only}) {
    my $ucbs = $spec->{after_update_cb} ||= [];
    unshift @$ucbs, sub {
      my ($type, $db, $r) = @_;

      my $dbh = $db->_dbh;
      my $rows = $dbh->do($upd_s, undef, (map { ref($_) ? $_->($r) : $r->{d}{$_} } @bnd), $r->{pk});
      if ($rows && $rows == 0) {
        $dbh->do($ins_s, undef, $r->{pk}, map { ref($_) ? $_->($r) : $r->{d}{$_} } @bnd);
      }
    };

    my $dcbs = $spec->{after_delete_cb} ||= [];
    unshift @$dcbs, sub {
      my ($type, $db, $r) = @_;

      $db->_dbh->do($del_s, undef, $r->{pk});
    };
  }
};


1;
