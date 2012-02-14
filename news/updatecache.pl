#!/usr/bin/perl

use strict;
use 5.010;
use Config::JSON;
use CHI;
use Getopt::Long;

# cli options
GetOptions( "config=s" => \my $config_file, "clear" => \my $clear, "id=s" => \my $id );

# config
my $config = Config::JSON->new($config_file);

my $cache = CHI->new( driver => 'File', root_dir => '/tmp/rss2channels');

if ($clear) {
	$cache->clear;
}
elsif ($id) {
	$cache->set('latest_entry_guid', $id);
}


