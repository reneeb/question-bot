# Question Bot for Online GPW 2021

This is a Chatbot that connects to a Matrix channel and collects questions that are asked into an Etherpad. The question are marked via a special prefix string (default: `q:`).
## Installation
Run following command in the root directory:
```bash
cpanm --installdeps .
```
Install [Matterbridge](https://github.com/42wim/matterbridge) via your distributions package manager.

## Usage
Run `bin/start_bot.pl` to use the bot. You can specify a topic to which the questions are collected and a configuration file via the CLI arguments.<br>
Here is an example:
```bash
bin/start_bot.pl --conf myconfig.yml mytopic
```

In the `cfg` directory is an example configuration file `example-bot.yml` with all possible options.

## Acknowledgments
Thanks to [@Corion](https://github.com/Corion) for providing a simple API for sending and receiving messages from Matterbridge. Link to his bot https://github.com/Corion/Bot-Matterbridge.