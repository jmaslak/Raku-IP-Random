use v6.c;
use Test;

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use IP::Random;

dies-ok { IP::Random::random_ipv4(exclude => [ 'foo' ]) }, "Invalid exclude type";

done-testing;

