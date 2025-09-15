# Event Management Script

# The what
This is a helper script that was designed to help run the Official BeamMP Events in a manner where the event hosts dont have to either select which players shall join the event servers, nor have to supervise that only these players do join the servers, all while still be able to maintain/not loose oversight over a big number of participants.

Official events where seperated into 2 categories.
- A qualification round. Where all players are able to join one or more servers and qualify a time.
- A racing round. Where all players join one or more servers and race each other.

This script doesnt track qualification or race results. But rather only helps with the coordination of both. You are entirely free to only use one or both of the modes, that is totally up to you.

This way it is possible for hundreds of players to qualify following the simple method of *"Who joins first, is served first. Who has already, doesnt get to again"*. While racing on the other hand allows the event hosts to easily specify which players can join which server.

This brings moderational needs of large scale events to almost zero. You as the event host open your servers and then just rotate your players.

# How to use

<p align="center">
    <img src="/.art/eventctl.jpg" />
</p>

### Qualification
- /event setquali
- /event setlimit player_limit
- eg. /event setlimit 15
	
> Now 15 Players can join. After they have successfully downloaded the mods and fully joined, a timer starts running. After SETTINGS.overplayed_after minutes this player is considered to have played enough to not be able to join again. They are not kicked automatically. But if they try to rejoin this or another server the script will not allow them to rejoin.
> 
> You Essentially open your Servers and eg set a limit of 15 players. After you as the event host decide that these 15 players have qualified enough you just `/event kickall` which will kick everyone but the adminds and this way allow other 15 players join and qualify. Rinse and repeat.

Commands
- /event setlimit 15 - will allow 15 players (wont affect admins and admins arent counted)
- /event kickall - kicks everyone that is not a admin, this way allowing x many more players do join that havent yet qualied
- /event reset - will reset the database

### Racing
- /event setrace
- /event nextrace player1 player2 playerN

> Now only these players can join + Admins.
> 
> Once the race has concluded you simply `/event nextrace player3 player4 playerN` with another set of players, this will kick everyone but admins and will allow all the given players into the server. Rinse and repeat.

Commands
- /event wipewhitelist - will wipe the whitelist but not kick anyone
- /event kickall - will kick everyone that is not a admin
- /event nextrace player1 player2 playerN - will kick everyone, wipe the whitelist and set a new all in one command
- /event missing - will show who of the whitelisted people is missing

# How to setup
1. After installing the script on your server, open the `main.lua` file.
2. After a tiny bit of scrolling you'll find the Settings section.
3. Fillout atleast `SETTINGS.admins = {"Player_1", "Player_N"}`
4. (re)start the Server
5. Done

With a simple `/event` either in the ingame chat or within the server console you can see all available commands.

### More settings in `main.lua`
> Enable/Disable the script by default (after the server has started). Will not limit server joins if disabled. Can be toggled via command
- SETTINGS.enabled = false

> The default mode, can only either be nil/"quali"/"race", can be set via command.
- SETTINGS.type = nil

> Repeats errors to the chat in the interval of X ms. These errors are only shown to the admins of this script. Can eg. be `Players cannot join until you define a type "/event setquali" "/event setrace"`
- SETTINGS.repeat_important_information_every = 60000 -- as ms

> Shown when the set player limit is 0 or no type has been set
- SETTINGS.message_not_ready_yet = "Event Server is not ready yet. Please wait patiently!"

> Shown when the joining player is a guest
- SETTINGS.message_is_guest = "Sorry but you have to join with a registered account, not as a guest!"

- SETTINGS.message_kick_all = "Thank you for joining, time for the next round of drivers!"

> Defines the playerlimit of the server. Does not overwrite the setting from ServerConfig.toml, but rather introduces its own playerlimit without counting admins. Can be set via command
- SETTINGS.player_limit = 0

> if multiple servers are used for quali at the same time, then these pathes must match between the servers. Every server needs to access the same exact files or it wont sync between them.
- SETTINGS.db_path = "eventorg_players_played.json"
- SETTINGS.db_lockfile = "eventorg_locked"

> as ms - After this many minutes the player is considered to have played enough to not be able to rejoin in the quali type
- SETTINGS.overplayed_after = 1000 * 60 * 5

> Shown when the player limit has been reached
> % will be replaced with SETTINGS.player_limit
- SETTINGS.message_server_full = "%/% players have already joined! Try next round!"

> Shown when the player already qualified
- SETTINGS.message_competed_already = "Thank you, but you have already participated in the qualification!"

> Players in this table can join during race, set this via command. {"player_name_n": true}
- SETTINGS.player_whitelist = {}

> Shown when a player joins in the race type that wasnt whitelisted
- SETTINGS.message_not_selected_for_race = "You have not been selected for this race. Please wait for your turn!"