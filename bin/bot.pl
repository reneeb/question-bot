#!perl
use strict; use warnings; use utf8;
use Mojolicious::Matterbridge;
use Etherpad;

use YAML::Tiny;

use Term::ANSIColor;
use URI::Encode qw/uri_encode/;

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use File::Basename;
use Cwd 'abs_path';
use Getopt::Long qw/:config auto_abbrev bundling/;
my $config_path = abs_path(dirname(__FILE__)) . '/../cfg/bot.yml';
GetOptions('config=s' => \$config_path);

my $yaml = YAML::Tiny->read($config_path);
my $config = $yaml->[0];

my $bot_name = $config->{bot}->{name} || 'questions->etherpad';
my $question_prefix = $config->{bot}->{question_prefix} || 'q:';
my $etherpad_url = $config->{etherpad}->{url} || 'http://localhost:3712';
my $etherpad_apikey = $config->{etherpad}->{apikey} 
    || die 'Apikey for Etherpad must be specified in config.';
my $etherpad_user = $config->{etherpad}->{user} || '';
my $etherpad_pw = $config->{etherpad}->{password} || '';
my $etp_title_prefix = $config->{etherpad}->{title_prefix} || '[Questions]';

sub handle_message( $msg ) {
    my @questions;
    # Retrieve question
    if( $msg->text =~ /^(?: $question_prefix\s | $question_prefix) (.*)$/xi ) {
        my $question = $1;
        # Append ? to question if not already present
        $question .= '?' unless $question =~ /^.* \?$/x;
        push @questions, sprintf "<%s> %s", $msg->username, $question;
    } else {
        #print sprintf "Ignoring '%s'\n", $msg->text;
    };

    return @questions;
}

sub pad_url ( $base_url, $pad_id ) {
    return uri_encode($base_url . '/p/' . $pad_id);
}

my $client = Mojolicious::Matterbridge->new(
    url => 'http://localhost:4242/api/',
);

my $etherpad = Etherpad->new(
    url         => "$etherpad_url",
    apikey      => "$etherpad_apikey", 
    user        => "$etherpad_user",
    password    => "$etherpad_pw",
);

if (!$etherpad->check_token()) {
    die "API Token is not valid";
}

my $pad_id = "$etp_title_prefix $ARGV[0]";

eval { 
    local $SIG{__WARN__} = sub {}; # Don't print warning if pad already exists
    $etherpad->create_pad($pad_id, ""); 
};

print colored("Connected to Pad '$pad_id'", 'green'), "\n";
print 'Link to Pad: ', colored(pad_url($etherpad_url, $pad_id), 'bright_blue'), "\n";

$client->on('message' => sub( $c, $message ) {
        print colored(sprintf("<%s> %s", $message->username, $message->text), 'yellow'), "\n";
        eval {
            $etherpad->append_text( $pad_id, "$_\n" ) for handle_message( $message);
        };
        warn $@ if $@;
});
$client->connect();

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
