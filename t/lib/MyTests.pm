package MyTests;

use strict;
use warnings;
use Percy;
use File::Temp ();
use File::Spec::Functions 'catfile';
use DBI;

sub import {
  my $target = caller();

  warnings->import();
  strict->import();

  {
    no strict 'refs';
    *{$target . '::test_percy_db'} = \&test_percy_db;
  }
}

{
  my $temp_dir;

  sub test_percy_db {
    $temp_dir = File::Temp->newdir unless $temp_dir;

    my $dbi = 'dbi:SQLite:dbname=' . catfile($temp_dir, 'percy.sqlite');
    my $dbh = DBI->connect($dbi, '', '', {RaiseError => 1, AutoCommit => 1});

    my $percy = Percy->new(dbh => $dbh);
    $percy->deploy;

    return $percy;
  }
}

1;
