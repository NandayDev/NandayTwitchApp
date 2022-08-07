# Nanday Twitch App

A desktop application to handle my Twitch channel and automate some stuff.

## Compatibility

Currently running on Windows only. Planning to add MacOS, and maybe Linux, later during the development.

## Features

* [X] Authentication:
  * [X] with Twitch APIs
  * [X] with Twitch Chat Interface
* [X] Displays a list of messages from the Twitch chat and lets you select one. Then you may:
  * [X] Read it aloud
    * [X] Bot's language should be selectable
* [ ] Sends periodic messages to the chat with some predefined messages (such as "Subscribe!" or similar)
* [ ] Thanks new followers, new subscribers
* [ ] Says "Hi!" to new people joining the chat

### Features on hold

* [ ] Show a popup on the streaming screen with a chat message sent by a user


## Building the app

Simply power up Android Studio after installing Flutter with this project.
Add a `twitch_keys.json` file to your **assets/keys** folder, with the following syntax:

    {
        "applicationClientId" : "your Twitch API chat bot app client id",
        "botUsername" : "your bot username as registered in Twitch",
        "channelName" : "name of the channel your bot should join (your username should work)"
    }
