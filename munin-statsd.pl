#!/usr/bin/perl -w

#
# munin-statsd.pl
#
# A Munin-Node to StatsD bridge
#
#    Author:: Brian Staszewski (<brian.staszewski@tech-corps.com>)
# Copyright:: Copyright (c) 2012 Tech-Corps, Inc.
#   License:: GNU General Public License version 2 or later
#
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software
# Foundation; either version 2 of the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

use warnings;
use strict;

use Munin::Node::Client;
use IO::Socket::INET;

# Configuration
my $schemabase		= "";
my $statsdhost		= "statsd.company.com";
my $statsdport		= 8125;
my $muninhost		= shift || "localhost";
my $muninport		= 4949;

$|++;

my $node = Munin::Node::Client->connect(host => $muninhost,
										port => $muninport);

my $version		= $node->version;
my @hostnames	= $node->nodes;
my $fqdn		= join(".", reverse(split(/\./, $hostnames[0])));
my @plugins		= $node->list();

my $statsd_sock	= new IO::Socket::INET (
	PeerAddr	=> $statsdhost.':'.$statsdport,
	Proto		=> 'udp'
) or die "Error creating socket to statsd!\n";

my $packet = "";

foreach my $plugin (@plugins) {
	my %data = $node->fetch($plugin);
  my %cnf = $node->config($plugin);

  my $cnf_section = $cnf{global}->{graph_category} || 'unknown';

	foreach my $stat (keys %data) {
    my $cnf_type = $cnf{datasource}->{$stat}->{type} || 'GAUGE';
    my $statsd_control = 'g';
    $statsd_control = 'c' if ($cnf_type =~ /(DERIVE)|(COUNTER)|(ABSOLUTE)/);
		$packet .= $schemabase."$muninhost.$cnf_section.$plugin.$stat:".$data{$stat}."|$statsd_control\n";
	}
}

$statsd_sock->send($packet);

$statsd_sock->close();
$node->quit;
