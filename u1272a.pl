#! /usr/bin/perl
#
# Proof of concept for Mac <-> Agilent U1272A communications
#
# Copyright (c) 2011 M J Oldfield <m@mjo.tc>
#
# Version 0.1 2011-06-17 M J Oldfield
#

use strict;
use warnings;

package My::U1272;

use Time::HiRes qw(time);

sub new
  {
    my ($class, $trace, $b19200) = @_;

    my $port = $class->get_portname;

    my $dev = Device::SerialPort->new($port)
      or die "Unable to open $port, ";

    print "Opened $port :)\n";

    $dev->databits(8);
    $dev->baudrate($b19200 ? 19200 : 9600);
    $dev->parity("none");
    $dev->stopbits(1);
    
    $dev->read_char_time(5);

    $dev->write_settings;
    
    return bless { dev => $dev, trace => $trace, t0 => time() }, $class;
  }

sub get_portname
  {
    my ($port, @others) = glob "/dev/ttyUSB*";

    die "No device found,  " unless $port;
    die "Multiple devices, " if @others;

    return $port;
  }

sub trace
  {
    my $s = shift;
    return unless $s->{trace};

    my $t = sprintf "%0.3f ", time() - $s->{t0};
    print $t, @_, "\n";
  }

# Execute a simple command and read back the result, assuming that there's one line
# terminated by "\n". Chop the line terminators off the response
#
# Assuming that $ignore_err isn't true, if we get an error ('*E') back ask why
sub cmd
  {
    my ($s, $cmd, $ignore_err) = @_;
    
    my $dev = $s->{dev};

    $dev->write($cmd . "\n");
    $s->trace(">: $cmd");

    my $response = '';
    while(1)
      {
	my ($count, $txt) = $dev->read(1);
	next unless $count;
	
	$response .= $txt;
	last if $txt eq "\n";
      }

    $response =~ s/[\n\r]+$//;

    $s->trace("<: $response");

    if ($response eq "*E" && !$ignore_err)
      {
	my $err = $s->cmd('SYST:ERR?');
	print "Error detected: $err\n";
      }

    return $response;
  }

# A bunch of SCPI commands which the meter understands
sub identity { shift->cmd('*IDN?')       }
sub battery  { shift->cmd('SYST:BATT?'); }
sub config   { shift->cmd('CONF?');      }
sub reading  { shift->cmd('FETC?');      }
sub reading2 { shift->cmd('FETC? @2');   }

# Read the log
sub get_log
  {
    my ($s, $log) = @_;

    my $cmd = "LOG:$log %d";

    my @log;

    print "Grabbing $log log:";
    my $i = 1;
    while(1)
      {
	if    ($i % 1000 == 1) { printf "\n  %4d: ", $i - 1; }
	elsif ($i %  100 == 1) { printf ".";              }

	my $res = $s->cmd(sprintf($cmd,$i), 1);
	last if $res eq '*E';

	# This is, quite frankly, a guess at the decoding!
	my ($pre, $data, $post) = ($res =~ /^"(\d{2})(\d{5})(\d{6})"$/)
	  or die "Can't parse reading $i : $res\n";

	push(@log, [ $i, $data, $pre, $post ]);

	$i++;
      }

    print "\nFinished\n";

    return \@log;
  }
    

package main;

use Getopt::Long;
use YAML qw(Dump DumpFile);

use Device::SerialPort;
use Pod::Usage;

$| = 1; # unbuffer stdout

my %Opt;
GetOptions(\%Opt, "help!", "info!", "trace!", "19200!", "get_log=s", "cmd=s");

pod2usage(-verbose => 2)
    if $Opt{help} || $Opt{info};

my $dev = My::U1272->new($Opt{trace}, $Opt{19200});

if (my $cmd = $Opt{cmd})
  {
    my $res = $dev->cmd($cmd);
    print "$res\n";
  }
elsif (my $log = $Opt{get_log})
  {
    my $file = lc($log) . ".txt";
    
    die "Dumpfile $file already exists and I refuse to overwrite it.\n"
      if -f $file;

    my $data = $dev->get_log($log);

    open(my $fh, '>', $file) or die "Couldn't open $file: $!\n";
    print {$fh} map { sprintf("%5d %6d %6d %6d\n", @$_) } @$data;

    my $n = @$data;
    print "$n data from $log log written to $file\n";
  }
else
  {
    my %data;
    foreach my $k (qw(identity battery config reading reading2))
      {
	no strict 'refs';
	$data{$k} = $dev->$k;
      }
    
    print Dump(\%data);
  }

__END__

=head1 NAME
 
u1272a - A toy application which talks to a U1272A
 
=head1 USAGE

    $ u1272a

    $ u1272a --trace

    $ u1272a --trace --cmd='*IDN?'

    $ u1272a --get_log=AUTO

 =head1 DESCRIPTION

A toy application which talks to an Agilent U1272A DMM over Agilent's
IR interface cable.

This is really just a proof of concept, so you shouldn't rely on its
reliability or functionality.

=head1 OPTIONS

By default the program just queries a bunch of data and prints it. You can change:

=over

=item --help, --info

Display this page.

=item --trace

Print the low-level communications with the meter.

=item --19200

Talk to the meter at 19200 baud (the default is 9600).

=item --cmd=foo

Execute the foo command and print the (one-line) result.

=item --log=AUTO|HAND

Retrieve logged data from the meter. This barely works: it's slow
(roughly one minute per thousand points), and I don't really
understand the format.

=back
 
=head1 CONFIGURATION AND ENVIRONMENT

The software assumes that there's precisely one device of the form
/dev/tty.PL* and that said device is the meter you're trying to prod.

We also assume that the meter is set to 9600 baud, 8-bit, no-parity,
and 1 stop-bit (the meter's default settings). If you want to try the
giddy speeds of 19200 baud use the --19200 option.

The meter settings can be changed in the meter's setup mode: see
Agilent's User Manual.


=head1 DEPENDENCIES

All the serial stuff is done via Device::SerialPort.

It seems moderately likely that I'm not using that module optimally.

=head1 BUGS AND LIMITATIONS

This program is a quick hack: it is not production quality code. In
most cases no parsing of the data from the meter is done; logged data
are parsed, but the algorithm is just a guess.

The serial port interface should be about three times faster.

Please report problems to the author.

Patches are welcome.
 
=head1 AUTHOR

M J Oldfield, m@mjo.tc
 
=head1 LICENCE AND COPYRIGHT
 
Copyright (c) 2011, M J Oldfield
 
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 


