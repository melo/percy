package Percy::Class;

# ABSTRACT: Moose defaults to our classes
# VERSION
# AUTHORITY

use strict;
use warnings;
use Import::Into;
use Moose                      ();
use MooseX::HasDefaults::RO    ();
use MooseX::StrictConstructor  ();
use MooseX::AttributeShortcuts ();
use Try::Tiny                  ();
use Moose::Exporter;
use namespace::autoclean ();    # no cleanup, just load

Moose::Exporter->setup_import_methods(
  also => ['Moose', 'MooseX::AttributeShortcuts', 'MooseX::StrictConstructor'],
  trait_aliases => [['MooseX::UndefTolerant::Attribute' => 'UndefTolerant']],
);

sub init_meta {
  my $class     = shift;
  my %params    = @_;
  my $for_class = $params{for_class};

  warnings->import;
  strict->import;

  Try::Tiny->import::into($for_class);

  Moose->init_meta(@_);
  MooseX::HasDefaults::RO->import({ into => $for_class });

  namespace::autoclean->import(-cleanee => $for_class);
}

1;
