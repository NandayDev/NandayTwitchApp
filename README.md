# Nanday Twitch App

A desktop application to handle my Twitch channel and automate some stuff.

## Features

* [X] Authentication:
  * [X] with Twitch APIs
  * [X] with Twitch Chat Interface
* [ ] Displays a list of messages from the Twitch chat and lets you select one. Then you may:
  * [ ] Read it aloud
  * [ ] Show a popup on the streaming screen with the message
* [ ] Sends periodic messages to the chat with some predefined messages (such as "Subscribe!" or similar)
* [ ] Thanks new followers, new subscribers
* [ ] Says "Hi!" to new people joining the chat

## Building the app

Simply power up Android Studio after installing Flutter with this project.
Add a `twitch_keys.json` file to your **assets/keys** folder, with the following syntax:

    {
        "apiClientId" : "your Twitch API client id",
        "chatBotClientId" : "your Twitch API chat bot client id"
    }

At least for the moment, we're only using this second property, since we're not using the normal Twitch APIs, but only the chat bot capabilities.