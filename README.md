# Question Bot for German Perl/Raku-Workshops

This is a Chatbot that connects to a Matrix channel and collects questions that are asked into an Etherpad. The question are marked via a special prefix string (default: `q:`).

## Installation

Run following command in the root directory:

```bash
cpanm --installdeps .
```

## Usage
Run `perl question-bot.pl` to use the bot.

Here is an example:

```bash
perl question-bot.pl --conf myconfig.yml --talks talks.yml
```

### myconfig.yml

This configuration file has all information needed for the bot itself.

```yaml
---
bot:
  question_prefix: 'F:'
matrix:
  server: matrix.org
  user: <bot-user>
  password: <bot-password>
  room: '#room-name:matrix.org'
etherpad:
  url: http://pad.your-domain.tld/
  apikey: <api_key>
  title_prefix: [Fragen]
```

### talks.yml

This file contains information about the talks of the event.

```yaml
---
'1648627195':
  id: <id_talk_1>
  slug: willkommen-auf-dem-deutschen-perlraku-worksho
  time: '2022-03-30 10:00:00'
  title: <title_talk_1>
  url: http://pad.your-domain.tld/p/willkommen-auf-dem-deutschen-perlraku-worksho
'1648628395':
  id: <id_talk_2>
  slug: corinnas-current-status
  time: '2022-03-30 10:20:00'
  title: <title_talk_2>
  url: http://pad.your-domain.tld/p/corinnas-current-status
'1648631995':
  id: <id_talk_3>
  slug: praxisbericht-migration-der-webapp-otobo-von-
  time: '2022-03-30 11:20:00'
  title: <title_talk_3>
  url: http://pad.your-domain.tld/p/praxisbericht-migration-der-webapp-otobo-von-
```

This is needed for the bot to identify the pad where to put the questions to and to send a
message to the chat that contains the links to the pad.

In the `cfg` directory is an example configuration file `example-bot.yml` with all possible options.
