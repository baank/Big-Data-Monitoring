#!/usr/bin/perl
#  Copyright 2012 TripAdvisor, LLC
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
# @purpose check the si/so columns of vmstat report. They indicate if a 
#          machine is swapping a lot.  On the warehouse hadoop nodes that
#          usually indicates big hadoop jobs, and we want to know about that...
#
# Option:
#  -w count for warning (0)
#  -c count for critical (10)
###############################################################################

use strict;
use warnings;

###############################################################################
# nagios variables

my $CRITICAL = 2;
my $WARNING = 1;
my $OK = 0;

my $test = 'SWAPPING';

sub critical { print "$test CRITICAL: @_\n"; exit $CRITICAL }
sub warning { print "$test WARNING: @_\n"; exit $WARNING }
sub ok { print "$test OK: @_\n"; exit $OK }

###############################################################################
# Main program

my $bFoundSi=0;
my $bFoundSo=0;
my $nLastSi=0;
my $nLastSo=0;

# default options
my $warning = 0;
my $critical = 10;

open (IN, "vmstat 1 3 |") || &critical("cannot run vmstat: $!");
while(<IN>)
{
    chop;

    /^procs/ && next;

    my @fields = split();

    # procs -----------memory---------- ---swap-- -----io---- --system-- -----cpu------
    #  r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
    #  1  0    260 170312 248452 30528944    0    0   300   542    2    4  5  1 93  1  0

    # make sure format doesn't change
    if ($fields[6] eq "si") {
	$bFoundSi = 1;
    };
    if ($fields[7] eq "so") {
	$bFoundSo = 1;
    };

    $nLastSi = $fields[6];
    $nLastSo = $fields[7];
}
close(IN);

if (! $bFoundSi || ! $bFoundSo) 
{
    &critical("vmstat format issues: found-si=$bFoundSi, found-so=$bFoundSo");
}

if ($nLastSi > $critical || $nLastSo > $critical)
{
    &critical("swapped-out $nLastSo, swapped-in $nLastSi");
}
    
if ($nLastSi > $warning || $nLastSo > $warning)
{
    &warning("swapped-out $nLastSo, swapped-in $nLastSi");
}

&ok("No pages swapped out or in");


