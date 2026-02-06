# VehicleConfigCheck (WIP)

Performs a server side vehicle config check and automatically removes vehicles that dont pass it. That way this script can automatically remove player owned vehicles that contain parts not allowed on the server.


### Functionality
This script contains a third party tool that extracts all vanilla vehicles and their parts from the game files and puts them into a file. Then upon launch of the server it goes through all mods that have been put into the `Resources/Client/*` folder and extracts all vehicles and their parts as well. Then it merges both the vanilla definitions with the custom modded definitions and this way automatically creates an allow list of vehicles and parts.

A player now spawning either a non enlisted modded vehicle or a non enlisted part (by for example sideloading a mod) will automatically have their vehicle removed.


### Usage
- Type these either into the ingame chat or into the server console
- `/vcc` and `/vcc help` will show all available commands
- `/vcc check` will perform a manual check on all spawned vehicles


### Installation
- Put the entire `VehicleConfigCheck` folder into your servers `Resources/Server` folder
- Open the `Resources/Server/VehicleConfigCheck/main.lua` file in a text editor
- Add the player names to the `SETTINGS.admins` variable that you wish to have control over this script.
> eg `{"player_1", "player_2"}`
- Save file
- Run the Server and have fun (:


### After installation AND Everytime that there is a minor or mayor game update you need to perform these additional steps
1. Go into the `Resources/Server/VehicleConfigCheck/bin` folder.
2. Open a Terminal/CMD in this very folder and run
- On Windows
> `extract_parts.exe full\path\togame\BeamNG.drive\content\vehicles vanilla_parts.json --parts-only`
- On Linux
> `./extract_parts full/path/togame/BeamNG.drive/content/vehicles vanilla_parts.json --parts-only`
3. After it created the `vanilla_parts.json` move it to the `Resources/Server/VehicleConfigCheck/assets` folder
4. You may want to reboot the server now or hotreload the main.lua and thats it.
