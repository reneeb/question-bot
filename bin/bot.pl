#!perl

use v5.24;

use strict;
use warnings;
use utf8;

use Etherpad;
use Getopt::Long qw/:config auto_abbrev bundling/;
use List::Util qw(first);
use Mojo::File qw(curfile);
use Term::ANSIColor;
use URI::Encode qw/uri_encode/;
use YAML::Tiny;

use lib curfile->dirname->sibling('lib')->to_string;
use Mojolicious::Matterbridge;

use feature 'signatures';
no warnings 'experimental::signatures';

GetOptions(
    'config=s' => \my $config_path,
    'talks=s'  => \my $talks_path,
);

$config_path //= curfile->dirname->child(qw/.. cfg bot.yml/);
$talks_path  //= curfile->dirname->child(qw/.. cfg talks.yml/);

_run( $config_path, $talks_path );

sub _run ( $config_path, $talks_path ) {
    my $config = YAML::Tiny->read($config_path)->[0];
    my $talks  = YAML::Tiny->read($talks_path)->[0];

    my $etherpad = _connect_to_etherpad( $config );

    my $client = Mojolicious::Matterbridge->new(
        url => 'http://localhost:4242/api/',
    );

    my $question_prefix = $config->{bot}->{question_prefix} || 'q:';

    my $talk = { id => -1 };

    $client->on('message' => sub( $c, $message ) {
        print colored(sprintf("<%s> %s", $message->username, $message->text), 'yellow'), "\n";

        my $talk_timestamp = first { time > $_ } reverse sort keys $talks->%*;
        my $current_talk   = $talks->{$talk_timestamp};

        # if current_talk is different to talk, then send a message to matrix
        # with the URL of the current pad TODO
        if ( $current_talk->{id} != $talk->{id} ) {
            $talk = $current_talk;
            $client->send(sprintf "Fragen zum aktuellen Vortrag werden unter %s gesammelt", $talk->{url});
        }

        eval {
            my @messages = _handle_message( $question_prefix, $message );
            $etherpad->append_text( $talk->{slug}, "$_\n" ) for @messages;
        };
        warn $@ if $@;
    });

    $client->connect();

    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

sub _connect_to_etherpad ( $config ) {
    my $etherpad_url     = $config->{etherpad}->{url} || 'http://localhost:3712';
    my $etherpad_apikey  = $config->{etherpad}->{apikey}
        || die 'Apikey for Etherpad must be specified in config.';

    my $etherpad = Etherpad->new(
        url    => $etherpad_url,
        apikey => $etherpad_apikey,
    );

    if (!$etherpad->check_token()) {
        die "API Token is not valid";
    }

    return $etherpad;
}

sub handle_message( $prefix, $msg ) {
    my @questions;


    # Retrieve question
    if( $msg->text =~ m{^(?: $question_prefix\s | $question_prefix) (.*)$}xi ) {
        my $question = $1;
        # Append ? to question if not already present
        $question .= '?' unless $question =~ m{\?$}x;

        push @questions, sprintf "<%s> %s", $msg->username, $question;
    } else {
        #print sprintf "Ignoring '%s'\n", $msg->text;
    };

    return $pad_id, @questions;
}

