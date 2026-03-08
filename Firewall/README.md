# Firewall Script

Will prevent players with a to young account and players that connect through a VPN/Proxy to join.
The Account age check and min age, just as the IP check can be toggled on/off.

If the IP or Account check fail for any reason, the script will let the player join. Simply because the ip-api or forum may not be available at times and we wouldnt want the players to suffer from that outtage.

## Installation
1) Move the folder `Firewall` from `Server/` to your servers `Resources/Server/` folder
2) (Re)Start server
3) Done

## Configuration
1) Open the file in `Server/Firewall/main.lua`
2) And at the top of the file you will see multiple variables, such as `B_NO_GUESTS`, `B_CHECK_IP`, `B_CHECK_ACCOUNTAGE` and `MIN_AGE_IN_DAYS`
3) Edit the variables to your liking and save the file.

The Script is hotreload safe. Edits can be done without having to restart the server.

## Variables
- `B_NO_GUESTS` (true/false) will enable or disable the ability of guest accounts to join your server
- `B_CHECK_IP` (true/false) will check the ip of each connecting player for if the ip is coming from a vpn or proxy. If the case the player is kicked. Warning: With the amount of vpn adverts it is not as unnormal for a player to connect through a vpn. You might be blocking away a great potion of your playerbase if you activate this option. As such this should rather be used when in need.
- `B_CHECK_ACCOUNTAGE` (true/false) will check each connecting players account against BeamMP's backend. If the accounts creation date is younger then the time defined in `MIN_AGE_IN_DAYS` then the player is kicked.
- `MIN_AGE_IN_DAYS` (number) defines how old a players account must be before its allowed to join.
