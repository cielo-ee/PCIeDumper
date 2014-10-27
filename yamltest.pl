#!/usr/bin/perl

use strict;
use warnings;
use YAML::XS qw/LoadFile/;
use Data::Dumper;
    
my $config = LoadFile('config.yaml');

print Dumper($config);