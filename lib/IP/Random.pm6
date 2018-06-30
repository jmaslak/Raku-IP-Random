use v6.c;
# unit class IP::Random:ver<0.0.2>;

module IP::Random:ver<0.0.7>:auth<cpan:JMASLAK> {

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

    our sub random_ipv4(:@exclude = ('default',), Int:D :$count = 0 ) {
        # We build the "excluded" hash used later to determine what we
        # want to exclude based on the  "exclude" named parameter.
        #
        # Keys are excluded CIDR, values are a list of IPv4 network base
        # address and prefix length.  I.E.:
        #   '0.0.0.0/0' => ( '0.0.0.0', 8 )
        #
        my %excluded;
        for @exclude -> $ex {
            if ($ex ~~ m/^ [ <[0..9]>**1..3 ]**4 % \.  ( \/ <[0..9]>**1..2 )?  $/) {
                # CIDR or bare IP

                my ($ipv4, $mask) = ipv4-cidr-to-int($ex);
                %excluded{ "$ipv4/$mask" } = ( $ipv4, $mask );
            } else {
                # Named exclude
                my Bool $found;
                for named_exclude -> $potential {
                    if $potential.value.grep($ex) {
                        $found = True;
                        my ($ipv4, $mask) = ipv4-cidr-to-int($potential.key);
                        %excluded{ "$ipv4/$mask" } = ( $ipv4, $mask );
                    }
                }
                if !$found {
                    die "Could not find exclude type: $ex";
                }
            }
        }

        my @excluded_ranges = _ipv4_exclude_ranges(%excluded);
        my $exclude_size    = _ipv4_coverage_count(@excluded_ranges);
        my $include_size    = 2**32 - $exclude_size;

        # If we have more than 128 IPs requested, split this into 16
        # individual batches to run, executing each of them in a race,
        # for better performance.  However if there are less than 128
        # IPs there isn't much performance advantage.
        #
        # 128 was chosen somewhat arbitrarily, so don't look for deep
        # meaning there.
        #
        if ($count > 128) {
            # The parallel path
            my $batch = Int($count/16);
            my $final = $count - 15*$batch;
            return flat (^16).race(batch=>1).map(
                { _random_ipv4_batch(@excluded_ranges, $include_size, $_ ?? $batch !! $final) }
            );
        } else {
            # The sequential block
            return _random_ipv4_batch(@excluded_ranges, $include_size, $count);
        }
    }

    # Builds a list of IP addresses to exclude, consolidating CIDRs into
    # ranges as appropriate.
    our sub _ipv4_exclude_ranges(%excluded) {
        my @ranges =
            map { ($^a[0], $^a[0] - 1 + 2**(32 - $^a[1])) },
            unique
            sort { $^a[0] <=> $^b[0] },
            values %excluded;

        my @last;
        my @output;
        while (@ranges) {
            my @current = (shift @ranges).flat;

            if (@last) {
                # Overlap/extension
                if (@last[1] >= (@current[0]-1)) {
                    # @last[1] = max(@last[1], @current[1]);
                    @last[1] = @last[1] > @current[1] ?? @last[1] !! @current[1];
                } else {
                    push @output, (@last[0], @last[1]);
                    @last = @current;
                }
            } else {
                # No overlap possibility, no "last"
                @last = @current;
            }
        }

        if (@last) {
            push @output, (@last[0], @last[1]);
        }

        return @output;
    }

    # Compute coverage, takes range object (array of array refs, each
    # array ref contains start and end IP
    our sub _ipv4_coverage_count(@ranges) {
        my $sum;
        for @ranges -> $range {
            $sum += 1 + $range[1] - $range[0];
        }

        return $sum;
    }

    # This handles a batch of random IPs.
    #
    # See comments in random_ipv4() about the %excluded parameter.
    our sub _random_ipv4_batch(@excluded_ranges, $include_size, Int:D $count) {
        my @out;
        my $c = $count;

_RIBLOOP:
        loop {
            my int $IP = (^$include_size).pick;

            my $offset = 0;
            for @excluded_ranges -> $exc {
                if $IP >= $exc[0] {
                    # We need to skip this range
                    $IP += 1 + $exc[1] - $exc[0];
                } elsif $IP <  $exc[0] {
                    last;
                }
            }

            my $addr = int-to-ipv4($IP);
            if (!$count) {
                return $addr;
            } else {
                @out.push($addr);
                $c--;
                if (!$c) {
                    return @out;
                }

                next _RIBLOOP;
            }
        }
    }

    my sub ipv4-to-int($ascii) {
        my int $ipval = 0;
        for $ascii.split('.') -> Int(Str) $part {

            if ($part < 0) || ($part > 255) {
                die "IP Address format is invalid";
            }

            $ipval = $ipval +< 8 + $part;
        }

        return $ipval;
    }

    my sub ipv4-cidr-to-int($ascii) {
            my ($exclude_ip, $exclude_mask) = $ascii.split('/');
            $exclude_mask //= 32;

            if $exclude_mask > 32 {
                die "Network prefix length is too long: $exclude_mask";
            }

            my int $ipv4 = ipv4-to-int( $exclude_ip );
            my int $mask = Int($exclude_mask);

            if ($ipv4 +< $exclude_mask) +& 0xffffffff {
                die "Network base address doesn't make sense for netmask: $ascii";
            }

            return ($ipv4, $mask);
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

};

=begin pod

=head1 NAME

IP::Random - Generate random IP Addresses

=head1 SYNOPSIS

  use IP::Random;

  my $ipv4 = IP::Random::random_ipv4;
  my @ips  = IP::Random::random_ipv4( count => 100 );

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

=head2 random_ipv4( :@exclude, :$count )

    say random_ipv4;
    say random_ipv4( exclude => ('rfc1112', 'rfc1122') );
    say random_ipv4( exclude => ('default', '24.0.0.0/8') );
    say join( ',',
        random_ipv4( exclude => ('rfc1112', 'rfc1122'), count => 2048 ) );

This returns a random IPv4 address.  If called with no parameters, it will
exclude any addresses in the default exclude list.

If called with the exclude optional parameter, which is passed as a list,
it will use the exclude types (see L<named_exclude> for the types) to
exclude from generation.  In addition, individual CIDRs may also be passed
to exclude those CIDRs.  If neither CIDRs or exclude types are passed, it
will use the C<default> tag to exclude the default excludes. Should you
want to exclude nothing, pass an empty list.  If you want to exclude
something in addition to the default list, you must pass the C<default> tag
explictly.

The count optional parameter will cause c<random_ipv4> to return a list of
random IPv4 addresses (equal to the value of C<count>).  If C<count> is
greater than 128, this will be done across multiple CPU cores.  Batching in
this way will yield significantly higher performance than repeated calls to
the C<random_ipv4()> routine.

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
