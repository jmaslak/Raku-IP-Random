use v6.c;
# unit class IP::Random:ver<0.0.2>;

module IP::Random:ver<0.0.5>:auth<cpan:JMASLAK> {

    our constant named_exclude = {
        '0.0.0.0/8'             => ( 'default', 'rfc1122', ),
        '10.0.0.0/8'            => ( 'default', 'rfc1918', ),
        '100.64.0.0/10'         => ( 'default', 'rfc6598', ),
        '127.0.0.0/8'           => ( 'default', 'rfc1122', ),
        '169.254.0.0/16'        => ( 'default', 'rfc3927', ),
        '172.16.0.0/12'         => ( 'default', 'rfc1918', ),
        '192.0.0.0/24'          => ( 'default', 'rfc5736', ),
        '192.0.2.0/24'          => ( 'default', 'rfc5737', ),
        '192.88.99.0/24'        => ( 'default', 'rfc3068', ),
        '192.168.0.0/16'        => ( 'default', 'rfc1918', ),
        '198.18.0.0/15'         => ( 'default', 'rfc2544', ),
        '198.51.100.0/24'       => ( 'default', 'rfc5737', ),
        '203.0.113.0/24'        => ( 'default', 'rfc5737', ),
        '224.0.0.0/4'           => ( 'default', 'rfc3171', ),
        '240.0.0.0/4'           => ( 'default', 'rfc1112', ),
        '255.255.255.255/32'    => ( 'default', 'rfc919',  ),
    };

    our sub default_ipv4_exclude() {
        keys named_exclude;
    }

    our sub exclude_ipv4_list($type) {
        map { $_.key }, grep { $_.value.grep($type) }, named_exclude;
    }

    our sub random_ipv4(:@exclude = ('default',) ) {
        my %excluded;
        for @exclude -> $ex {
            for named_exclude -> $potential {
                if $potential.value.grep($ex) {
                    %excluded{ $potential.key } = $potential.value;
                }
            }
        }

        loop {
            my $addr = int-to-ipv4 (^(2**32)).pick;

            my @cidrs = ipv4-containing-cidrs($addr);
            if @cidrs.grep( { %excluded{$_}:exists } ).elems == 0 {
                return $addr;
            }
        }
    }

    my sub ipv4-to-int($ascii) {
        my int $ipval = 0;
        for $ascii.split('.') -> Int(Str) $part {
            $ipval = $ipval +< 8 + $part;
        }

        return $ipval;
    }

    my sub int-to-ipv4(Int:D $IP) {
        my int $ip = $IP;

        my @output;
        @output.push($ip +> 24       );
        @output.push($ip +> 16 +& 255);
        @output.push($ip +>  8 +& 255);
        @output.push($ip       +& 255);

        return @output.join('.')
    }

    my sub ipv4-containing-cidrs($ascii_ipv4) {
        my $ipval = ipv4-to-int($ascii_ipv4);

        my @cidrs = $ascii_ipv4 ~ '/32';
        for (1..31).reverse -> $len {
            $ipval = $ipval +& ( ( (2**32)-1) +^ ((2**(32-$len))-1) ) ;

            my $cidr = int-to-ipv4($ipval) ~ '/' ~ $len;
            push @cidrs, $cidr;
        }
        push @cidrs, '0.0.0.0/0';

        return @cidrs;
    }

};

=begin pod

=head1 NAME

IP::Random - Generate random IP Addresses

=head1 SYNOPSIS

  use IP::Random;

  my $ipv4 = IP::Random::random_ipv4;

=head1 DESCRIPTION

This provides a random IP (IPv4 only currently) address, with some
extensability to exclude undesired IPv4 addresses (I.E. don't return IP
addresses that are in the multicast or RFC1918 ranges).

By default, the IP returned is a valid, publicly routable IP address, but
this behavior can be adjusted.

=head1 FUNCTIONS

=head2 default_ipv4_exclude

Returns the default exclude list for IPv4, as a list of CIDR strings.

Additional CIDRs may be added to future versions, but in no case will standard
Unicast publicly routable IPs be added.  See L<named_exclude> to determine
what IP ranges will be included in this list.

=head2 exclude_ipv4_list($type)

When passed a C<$type>, such as C<'rfc1918'>, will return a list of CIDRs
that match that type.  See L<named_exclude> for the valid types.

=head2 random_ipv4( :$exclude )

    say random_ipv4;
    say random_ipv4( exclude => ('rfc1112', 'rfc1122') );

This returns a random IPv4 address.  If called with no parameters, it will
exclude any addresses in the default exclude list.

If called with the exclude optional parameter, which is passed as a list,
it will use the exclude types (see L<named_exclude> for the types) to
exclude from generation.

=head1 CONSTANTS

=head2 named_exclude

    %excludes = IP::RANDOM::named_exclude

A hash of all the named IP exludes that this C<IP::Random> is aware of.
The key is the excluded IP address.  The value is a list of tags that
this module is aware of.  For instance, C<192.168.0.0/16> would be a key
with the values of C<( 'rfc1918', 'default' )>.

This list contains:

=begin item
C<0.0.0.0/8>

Tags: default, rfc1122

"This" Network (RFC1122, Section 3.2.1.3).
=end item
=begin item
C<10.0.0.0/8>

Tags: default, rfc1918

Private-Use Networks (RFC1918).
=end item
=begin item
C<100.64.0.0/10>

Shared Address Space (RFC6598)

=end item
=begin item
C<127.0.0.0/8>

Tags: default, rfc1122

Loopback (RFC1122, Section 3.2.1.3)
=end item
=begin item
C<169.254.0.0/16>

Link Local (RFC 3927)
=end item
=begin item
C<172.16.0.0/12>

Tags: default, rfc1918

Private-Use Networks (RFC1918)
=end item
=begin item
C<192.0.0.0/24>

IETF Protocol Assignments (RFC5736)
=end item
=begin item
C<192.0.2.0/24>

TEST-NET-1 (RFC5737)
=end item
=begin item
C<192.88.99.0/24>

6-to-4 Anycast (RFC3068)
=end item
=begin item
C<192.168.0.0/16>

Tags: default, rfc1918

Private-Use Networks (RFC1918)
=end item
=begin item
C<198.18.0.0/15>

Network Interconnect Device Benchmark Testing (RFC2544)
=end item
=begin item
C<198.51.100.0/24>

TEST-NET-2 (RFC5737)
=end item
=begin item
C<203.0.113.0/24>

TEST-NET-3 (RFC5737)
=end item
=begin item
C<224.0.0.0/4>

Multicast (RFC3171)
=end item
=begin item
C<240.0.0.0/4>

Reserved for Future Use (RFC 1112, Section 4)
=end item

=head1 AUTHOR

Joelle Maslak <jmaslak@antelope.net>

=head1 CONTRIBUTORS

Elizabeth Mattijsen <liz@wenzperl.nl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 Joelle Maslak

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
