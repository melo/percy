package Percy::Role;

# ABSTRACT: Moose defaults to our roles
# VERSION
# AUTHORITY

use strict;
use warnings;
use Moose::Role ();
use Moose::Exporter;
Moose::Exporter->setup_import_methods(also => ['Moose::Role']);

sub init_meta {
  my $class     = shift;
  my %params    = @_;
  my $for_class = $params{for_class};

  warnings->import;
  strict->import;

  Moose::Role->init_meta(@_);
}

1;
