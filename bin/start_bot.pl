#!/usr/bin/env perl
use sigtrap 'handler', \&close, 'normal-signals';


defined(my $pid = fork) or die "Cannot fork: $!";
unless ($pid) { 
	exec "matterbridge -conf cfg/matrix-matterbridge.toml > /dev/null";
}

sub close {
    kill 'INT', $pid;
    die "Received Interrupt, exiting...\n";
}

sleep 1;

system "perl -I lib bin/bot.pl $ARGV[0]";
