#!perl

use strict;
use warnings;
use lib 't/lib';

$ENV{PERCY_DSN} = 'dbi:mysql:database=test';

require HowCrudOfYou;
