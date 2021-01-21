#!/usr/bin/env perl
use v5.10;
use Getopt::Long qw/:config auto_abbrev bundling/;
use File::Basename;
use Cwd 'abs_path';

my $mtb_config = abs_path(dirname(__FILE__)) . '/../cfg/matrix-matterbridge.toml';

my $matterbridge = "matterbridge -conf $mtb_config";
my $question_bot = 'perl -I lib bin/bot.pl';
my $config_path = '';
GetOptions('config=s' => \$config_path);
$config_path = "--config $config_path" if ($config_path);
my $talk_topic = $ARGV[0];

open MTB, $matterbridge . ' |';
sleep 1;
system join ' ', $question_bot, $config_path, $talk_topic;
