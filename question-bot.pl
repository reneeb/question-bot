#!/usr/bin/perl

use v5.24;

use strict;
use warnings;
use utf8;

use Etherpad;
use Getopt::Long qw/:config auto_abbrev bundling/;
use IO::Async::Loop;
use List::Util qw(first);
use Mojo::File qw(curfile);
use Net::Async::Matrix;
use Term::ANSIColor;
use URI::Encode qw/uri_encode/;
use YAML::Tiny;

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
    my $question_prefix = $config->{bot}->{question_prefix} || 'q:';

    my $talk = { id => -1 };

    my $loop = IO::Async::Loop->new;

    my $matrix = Net::Async::Matrix->new(
        server => $config->{matrix}->{server},
        on_room_message => sub {
            my ($room, $member, $content, $event) = @_;

            my $msg = $content->{body};
            print colored(sprintf("<%s> %s", $member->displayname, $msg), 'yellow'), "\n";

            my $talk_timestamp = first { time > $_ } reverse sort keys $talks->%*;
            my $current_talk   = $talks->{$talk_timestamp};

            # if current_talk is different to talk, then send a message to matrix
            # with the URL of the current pad TODO
            if ( $current_talk->{id} != $talk->{id} ) {
                print colored( "sending pad URL to matrix", 'yellow' );

                $talk = $current_talk;
                $room->send_message(
                    sprintf "Fragen zum aktuellen Vortrag werden unter %s gesammelt", $talk->{url}
                );
            }

            eval {
                my @messages = _handle_message( $question_prefix, $member, $msg );
                $etherpad->append_text( $talk->{slug}, "$_\n" ) for @messages;
            };

            warn $@ if $@;
        },
    );

    $loop->add( $matrix );

    $matrix->login(
        user_id  => $config->{matrix}->{user},
        password => $config->{matrix}->{password},
    )->get;

    my $room = $matrix->join_room( $config->{matrix}->{room} )->get;

    $loop->run;
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

