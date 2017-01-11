#!/usr/bin/perl

use strict;

use Getopt::Long;

my $debug = 0;
my $verbose = 0;
my $exec = 1;
my $force = 0;
my $update = 0;
my $die = 0;

my $skipd;
my $skipf;

sub error {
    my ($msg) = @_;

    print STDERR $msg, "\n";
    die if $die;
}

sub prop {
    my ($dir) = @_;

    opendir DIR, $dir or error "opendir $dir: $!";
    my @entries = readdir DIR;
    closedir DIR;

    # no . and .. for recursion, and ignore symlink
    my @dirs = grep -d "$dir/$_" && ! -l "$dir/$_", @entries;
    @dirs = grep !/^\.$/, @dirs;
    @dirs = grep !/^\.\.$/, @dirs;

    # argv specified skip dir for rec
    $skipd and @dirs = grep !/$skipd/, @dirs;

    # deepth first
    foreach (@dirs) {
	prop("$dir/$_");
    }

    # do not consider date of ..
    @entries = grep !/^\.\.$/, @entries;

    # argv specified skip file and dir for date
    $skipf and @entries = grep !/$skipf/, @entries;
    $skipd and @entries = grep !/$skipd/, @entries;

    # ignore symlink
    @entries = grep ! -l "$dir/$_", @entries;

    # non empty dir
    if (@entries > 1) {
	my @tmp;
	
	$debug and print "# $dir\n";

	# get all dates
	my @dates = map { (stat("$dir/$_"))[9] } @entries;

	# remember entries by date
	@tmp = @dates;
	my %entries_dates = map { $_ => shift @tmp } @entries;

	# and dates by entry
	my %dates_entries = map { $_ => shift @entries } @dates;

	# sort by date
	@dates = sort { $a <=> $b } @dates;

	# if force update or no subdir and most recent is self forget it
	if ($force || (!@dirs && $dates_entries{$dates[$#dates]} eq '.')) {
	    pop @dates;
	}

	if ($debug) {
	    @tmp = map { $_, $dates_entries{$_} } @dates;
	    print "# @tmp\n";
	    @tmp = map { $_, $entries_dates{$_} } keys %entries_dates;
	    print "# @tmp\n";
	}

	# now get most recent and prepare touch
	my $newer = $dates_entries{pop @dates};
	my @touch = ('touch', '-r', "$dir/$newer", $dir);

	$debug and print "# @touch\n";

	if ($update) {
	    # dont touch from ourselves or already newer or symlink
	    if ("$newer" ne '.' && $entries_dates{'.'} < $entries_dates{$newer} && ! -l "$dir/$newer") {
		$verbose and print "$dir/$newer\n";
		$exec and system @touch and die "@touch";
	    }
	} else {
	    # dont touch from ourselves or same date or symlink
	    if ("$newer" ne '.' && $entries_dates{'.'} != $entries_dates{$newer} && ! -l "$dir/$newer") {
		$verbose and print "$dir/$newer\n";
		$exec and system @touch and die "@touch";
	    }
	}
    }
}

my $dummy;

sub main {
    GetOptions(
	       "debug" => \$debug,
	       "exec!" => \$exec,
	       "update" => \$update,
	       "force" => \$force,
	       "verbose" => \$verbose,
	       "skipd=s" => \$skipd,
	       "skipf=s" => \$skipf,
	       "ydummy" => \$dummy
	       )
	or die "bad options\n";

    foreach (@ARGV) {
	prop($_);
    }
}

main();
