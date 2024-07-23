# RaceOptions

### Motivation
Quickly made on request

### What does it do?
Upon calling the `/rcopt enable` command every player is put into a competitive mode. They can no longer change their vehicle, spawn a vehicle, remove a or their vehicle, use the walking mode, ai controls, no longer teleport (but reset) and no longer control physics.

Independent from the enable/disable command, a player cannot use the nodegrabber, world editor, the lua console, slowmotion, not pause the game, toggle traffic, or use any of the fun stuff.

Beware the Client side script is super simple. For the Server side i used a template that had also been used in `TrollThings` and `CarBomb`

### Usage
- Type these either into the ingame chat or into the server console
- `/rcopt` and `/rcopt help` will show all available commands
- `/rcopt enable` will enable the competitive mode
- `/rcopt disable` disables

### Installation
- Put the `RaceOptions.zip` into your servers `Resources/Client/` folder
- Put the entire `RaceOptions` folder into your servers `Resources/Server` folder
- Open the `Resources/Server/RaceOptions/main.lua` file in a text editor
- Add the player names to the ADMINS variable that you wish to have control over this script.
> eg `{"player_1", "player_2"}`
- Save file
- Run the Server and have fun (:

