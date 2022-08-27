# Nanday Twitch App

A desktop application to handle my Twitch channel and automate some stuff.

## Compatibility

Currently running on Windows only. Planning to add MacOS, and maybe Linux, later during the development.

## Features

- [x] Authentication:
  - [x] with Twitch APIs
  - [x] with Twitch Chat Interface
- [x] Displays a list of messages from the Twitch chat and lets you select one. Then you may:
  - [x] Read it aloud
    - [x] Bot's language should be selectable
- [x] Sends periodic messages to the chat with some predefined messages (such as "Subscribe!" or similar)
  - [x] Add a textbox to choose how many seconds should pass between each predefined message
- [x] Thanks new subscribers
- [ ] Thanks new followers
- [x] Says "Hi!" to new people joining the chat
- [ ] Custom commands
  - [ ] "!what" to get to know what the streamer is doing today
  - [ ] "!time": get local time in the streamer's time zone
- [ ] Sounds
  - [ ] Soft sound when someone writes a message in the chat
  - [ ] When someone subscribes
  - [ ] When someone raids

### Features on hold

- [ ] Show a popup on the streaming screen with a chat message sent by a user

### Improvements

- [ ] Creating a centralized event center for notifications to the app components
- [ ] Evaluate raid size when someone raids: saying "Wow, a lot of people!" in the chat could be sarcastic!
- [ ] Broadcast messages should be sent by the BroadcastService, not the TwitchChatService

### Other aspects

- [ ] Security?

### Bugs to fix

- [x] Double broadcast messages

## Building the app

Simply power up Android Studio after installing Flutter with this project.
Add a `twitch_keys.json` file to your **assets/keys** folder, with the following syntax:

    {
        "applicationClientId" : "your Twitch API chat bot app client id",
        "botUsername" : "your bot username as registered in Twitch",
        "channelName" : "name of the channel your bot should join (your username should work)"
    }
