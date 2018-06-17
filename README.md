[![Build Status](https://travis-ci.org/jmaslak/Perl6-IP-Random.svg?branch=master)](https://travis-ci.org/jmaslak/Perl6-IP-Random)

NAME
====

IP::Random - Generate random IP Addresses

SYNOPSIS
========

    use IP::Random;

    my $ipv4 = IP::Random::random_ipv4();

DESCRIPTION
===========

This provides a random IP (IPv4 only currently) address, with some extensability to exclude undesired IPv4 addresses (I.E. don't return IP addresses that are in the multicast or RFC1918 ranges).

By default, the IP returned is a valid, publicly routable IP address, but this behavior can be adjusted.

FUNCTIONS
=========

default_ipv4_exclude()
----------------------

Returns the default exclude list for IPv4, as a list of CIDR strings.

Additional CIDRs may be added to future versions, but in no case will standard Unicast publicly routable IPs be added. See [named_exclude](named_exclude) to determine what IP ranges will be included in this list.

exclude_ipv4_list($type)
------------------------

When passed a `$type`, such as `'rfc1918'`, will return a list of CIDRs that match that type. See [named_exclude](named_exclude) for the valid types.

random_ipv4( :$exclude )
------------------------

    say random_ipv4();
    say random_ipv4( exclude => ('rfc1112', 'rfc1122') );

This returns a random IPv4 address. If called with no parameters, it will exclude any addresses in the default exclude list.

If called with the exclude optional parameter, which is passed as a list, it will use the exclude types (see [named_exclude](named_exclude) for the types) to exclude from generation.

CONSTANTS
=========

named_exclude
-------------

    %excludes = IP::RANDOM::named_exclude

A hash of all the named IP exludes that this `IP::Random` is aware of. The key is the excluded IP address. The value is a list of tags that this module is aware of. For instance, `192.168.0.0/16` would be a key with the values of `( 'rfc1918', 'default' )`.

This list contains:

over
====

4

  * 0.0.0.0/8

Tags: default, rfc1122

"This" Network (RFC1122, Section 3.2.1.3).

  * 10.0.0.0/8

Tags: default, rfc1918

Private-Use Networks (RFC1918).

  * 100.64.0.0/10

Shared Address Space (RFC6598)

  * 127.0.0.0/8

Tags: default, rfc1122

Loopback (RFC1122, Section 3.2.1.3)

  * 169.254.0.0/16

Link Local (RFC 3927)

  * 172.16.0.0/12

Tags: default, rfc1918

Private-Use Networks (RFC1918)

  * 192.0.0.0/24

IETF Protocol Assignments (RFC5736)

  * 192.0.2.0/24

TEST-NET-1 (RFC5737)

  * 192.88.99.0/24

6-to-4 Anycast (RFC3068)

  * 192.168.0.0/16

Tags: default, rfc1918

Private-Use Networks (RFC1918)

  * 198.18.0.0/15

Network Interconnect Device Benchmark Testing (RFC2544)

  * 198.51.100.0/24

TEST-NET-2 (RFC5737)

  * 203.0.113.0/24

TEST-NET-3 (RFC5737)

  * 224.0.0.0/4

Multicast (RFC3171)

  * 240.0.0.0/4

Reserved for Future Use (RFC 1112, Section 4)

back
====



AUTHOR
======

Joelle Maslak <jmaslak@antelope.net>

COPYRIGHT AND LICENSE
=====================

Copyright (C) 2018 Joelle Maslak

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

