# EnvSync

### Motivation
There is only a single Environment Sync script openly available and it comes bundled with a whole framework. Putting a whole framework on your server that takes over a pletora of things is not always something server admins want. For these users this light weight script might be more appealing.

### What does it do?
- If enabled this script takes full control over every clients Environment. This currently only means Time, Time progression, Clouds, Fog, wind and gravity `/esync enable`
- The server ticks its own time and updates it to the clients but only if the server notices that the clients are out of sync. This is true for all synchronized environment settings
- A player cannot set settings in the environment tab while the script is active
- Gravity sync can be disabled/reenabled either via a lua variable or through a command. This is usefull if you have other mods on your server that need authority over the gravity eg. [Sumo](https://github.com/SaltySnail/Sumo-BeamMP). `/esync gravitysync false`
- Should the script be disabled it stops all synchronization, which gives the player or other scripts the full authority over the entire environment back `/esync disable`
- You can enable time progressing even if no player is on your server
- Time is automatically reset back to a preset if the server has no players, can be disabled
- You can set your own environment settings to the servers. Disable first then set your environment and fire `/esync updateenv`, now the server inherited your environment
- Script can also be controlled from the Server Console. Type `/esync` in the console
- You can set lower and higher Day/Night scales then the game environment tab allows you eg Day Scale 0.1, while the game only allows 0.5 at minimum

### Usage
- Type these either into the ingame chat or into the server console
- `/esync` and `/esync help` will show all available commands
- `/esync enable` will enable the env sync
- `/esync disable` disables
- There are over 20 Commands.

### Installation
- Put the `EnvSync.zip` into your servers `Resources/Client/` folder
- Put the entire `EnvSync` folder into your servers `Resources/Server` folder
- Open the `Resources/Server/EnvSync/main.lua` file in a text editor
- Add the player names to the ADMINS variable that you wish to have control over this script.
> eg `{"player_1", "player_2"}`
- Save file
- Run the Server and have fun (:
- There are various settings you can set on the top of this file

<p align="center">
    <img src=".art/envsync.jpg" width="292" />
</p>

### Behind the Scenes
All Clients send the Server their full environment state in a specified interval that the server dictates. The server then compares the values to its controlled environment and creates a diff table that only contains unequal settings. Only those are then send to the out of sync client. Every setting has a allowed out of sync range.