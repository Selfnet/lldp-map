#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;

use Walker;

my $map = Walker->new();
$map->walk('vaih-core');
$map->walk('stuwost1');
$map->save('map.dot');
