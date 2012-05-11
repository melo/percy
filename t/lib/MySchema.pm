package MySchema;

use Percy::Class;
use File::Temp ();
use File::Spec::Functions 'catfile';
use DBI;

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
          { RaiseError => 1, AutoCommit => 1 }
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


## Allow us to change the behaviour of _tweak_type_spec()
{
  my $tweaker;
  sub _tweak_type_spec { $tweaker->(@_) if $tweaker }
  sub set_tweak_type_spec { $tweaker = $_[1] }
}


## Some types to play with

MySchema->schema->type_spec(masta => { sets => { slaves => { slave => 'slava' } } });
MySchema->schema->type_spec(slava => {});


## Added some types with sorted sets
MySchema->schema->type_spec(
  sorted_sets => {
    sets => {
      by_number => {
        slave     => 'slava',
        sorted_by => { field => 'number', type => 'Integer' },
      },
      by_string => {
        slave     => 'slava',
        sorted_by => { field => 'string', type => 'String' },
      },
      by_date => {
        slave     => 'slava',
        sorted_by => { field => 'date', type => 'Date' },
      },
      by_datetime => {
        slave     => 'slava',
        sorted_by => { field => 'datetime', type => 'DateTime' },
      },
    },
  },
);


__PACKAGE__->meta->make_immutable;
1;
