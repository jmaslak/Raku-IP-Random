use v6.c;
use Test;

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use IP::Random;

my constant TRIALS = 2048;

my @ips = IP::Random::random_ipv4(count => TRIALS);

my @octets = map { 0 }, ^256;
for @ips -> $ip {
    for $ip.split('.') -> $oct {
        @octets[$oct]++;
    }
}

subtest 'randomness', {
    for ^256 -> $oct {
        my $min = ($oct == 0 || $oct == 10 || $oct > 224) ?? 2 !! 4;
        ok(@octets[$oct] <=   64, "$oct randomness 1 (@octets[$oct])");
        ok(@octets[$oct] >= $min, "$oct randomness 2 (@octets[$oct])");
    }
    done-testing;
}

subtest 'not invalid', {
    is @ips.grep( { $_ ~~ m/^0\./ } ).elems, 0, 'IPs starting with 0.';
    is @ips.grep( { $_ ~~ m/^10\./ } ).elems, 0, 'IPs starting with 10.';
    is @ips.grep( { $_ ~~ m/^240\./ } ).elems, 0, 'IPs starting with 240.';
    done-testing;
}

subtest 'only RFC1112', {
    my @ips = IP::Random::random_ipv4(exclude => [ 'rfc1112' ], count => TRIALS);

    ok @ips.grep( { $_ ~~ m/^0\./ } ).elems  > 0, 'IPs starting with 0.';
    ok @ips.grep( { $_ ~~ m/^10\./ } ).elems > 0, 'IPs starting with 10.';
    is @ips.grep( { $_ ~~ m/^240\./ } ).elems, 0, 'IPs starting with 240.';

    done-testing;
}

subtest 'RFC1112 and RFC 1122', {
    my @ips = IP::Random::random_ipv4(exclude => [ 'rfc1112', 'rfc1122' ], count => TRIALS);

    is @ips.grep( { $_ ~~ m/^0\./ } ).elems,   0, 'IPs starting with 0.';
    ok @ips.grep( { $_ ~~ m/^10\./ } ).elems > 0, 'IPs starting with 10.';
    is @ips.grep( { $_ ~~ m/^240\./ } ).elems, 0, 'IPs starting with 240.';

    done-testing;
}

done-testing;

