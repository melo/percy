package MySchema;

use Percy::Object;
use File::Temp ();
use File::Spec::Functions 'catfile';
use DBI;
use namespace::clean;

extends 'Percy::Schema';


## Add a 'x' type with default values
MySchema->schema->type_spec(x => {});


## Make sure every test Percy schema is created on a different temporary
## directory
{
  my $temp_dir = File::Temp->newdir;

  sub connect_info {
    my ($self) = @_;

    return {
      connect => sub {
        my $dbi = $ENV{PERCY_DSN}
          || 'dbi:SQLite:dbname=' . catfile($temp_dir, 'percy.sqlite');
        return DBI->connect(
          $dbi,
          ($ENV{PERCY_USER} || ''),
          ($ENV{PERCY_PASS} || ''),
          {RaiseError => 1, AutoCommit => 1}
        );
      },
    };
  }
}


## Allow us to change the behaviour of default_type_spec()
{
  my $next_default_type;
  sub default_type_spec { return $next_default_type }
  sub set_default_type_spec { $next_default_type = $_[1] }
}


1;
