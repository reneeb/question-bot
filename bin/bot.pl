#!perl
use strict; use warnings;
use Mojolicious::Matterbridge;
use Etherpad;

use Term::ANSIColor;
use URI::Encode qw/uri_encode/;

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

# This is basically an Infobot in 40 lines of Perl


my $bot_name = "questions->etherpad";

sub handle_message( $msg ) {
    my @questions;
    # Retrieve question
    if( $msg->text =~ /^(?: q:\s | q:) (.*)$/xi ) {
        my $question = $1;
        $question .= '?' if (!$question =~ /^.* ?$/x);
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

my $etherpad_url = 'http://localhost:3712';
my $etherpad = Etherpad->new(
    url => "$etherpad_url",
    apikey => 'ad554754aa45a8ffa5e900ac4bf846fe64917bea6b0b4f403ef1c513ca95a5e5',
);

if (!$etherpad->check_token()) {
    die "API Token is not valid";
}

my $pad_id = "[Questions] $ARGV[0]";
eval { $etherpad->create_pad($pad_id, ""); };
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
