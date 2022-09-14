# Nanday Twitch App

A desktop application to handle my Twitch channel and automate some stuff.

## Compatibility

Currently running on Windows only. Planning to add MacOS, and maybe Linux, later during the development.

## Features to add

- [ ] "Multiprofile": possibility to login with a profile and use that
- [ ] "Epic quotes"
  - [ ] Saving
  - [ ] Displaying
- [ ] Sound effects playing, with the possibility to add more
- [ ] Currency system

### Other aspects

- [ ] Security?

### Completed Features

- [x] Authentication:
  - [x] with Twitch APIs
  - [x] with Twitch Chat Interface
- [x] Displays a list of messages from the Twitch chat and lets you select one. Then you may:
  - [x] Read it aloud
    - [x] Bot's language should be selectable
- [x] Sends periodic messages to the chat with some predefined messages (such as "Subscribe!" or similar)
  - [x] Add a textbox to choose how many seconds should pass between each predefined message
- [x] Thanks new subscribers
- [x] Thanks new followers
- [x] Says "Hi!" to new people joining the chat
- [x] Custom commands
  - [x] "!what" to get to know what the streamer is doing today
    - [x] add a way for the streamer to edit the "!what" content response
  - [x] "!time": get local time in the streamer's time zone
- [x] Sounds
  - [x] Soft sound when someone writes a message in the chat
  - [x] When someone subscribes
  - [x] When someone follows
  - [x] When someone raids

### Features on hold

- [ ] Show a popup on the streaming screen with a chat message sent by a user

### Improvements

- [x] Creating a centralized event center for notifications to the app components
- [x] Evaluate raid size when someone raids: saying "Wow, a lot of people!" in the chat could be sarcastic!
- [x] Broadcast messages should be sent by the BroadcastService, not the TwitchChatService
- [x] Switch just_audio dependency with something more stable



### Bugs to fix

- [x] Double broadcast messages
- [x] Bot shouldn't greet myself or itself

## Building the app

Simply power up Android Studio after installing Flutter with this project.
Add a `twitch_keys.json` file to your **assets/keys** folder, with the following syntax:

    {
        "applicationClientId" : "your Twitch API chat bot app client id",
        "botUsername" : "your bot username as registered in Twitch",
        "channelName" : "name of the channel your bot should join (your username should work)",
        "browserExecutable" : "path of your browser, or null if should use the default one of your OS"
    }
