package MySchema;

use Percy::Object;
use File::Temp ();
use File::Spec::Functions 'catfile';
use DBI;
use namespace::clean;

extends 'Percy::Schema';


## Make sure every test Percy schema is created on a different temporary
## directory
{
  my $temp_dir = File::Temp->newdir;

  sub connect_info {
    my ($self) = @_;

    return {
      connect => sub {
        my $dbi = 'dbi:SQLite:dbname=' . catfile($temp_dir, 'percy.sqlite');
        return DBI->connect($dbi, '', '', {RaiseError => 1, AutoCommit => 1});
      },
    };
  }
}

1;
