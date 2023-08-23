# Allows the Changing of the Map via Commands

Can be run by anyone
- /map MapName
- /map help

On map swap the script creates a file name "restart" in the root dir of the Server.
Since the Server provides no method of restarting the server via lua, you have to have a script that looks regulary for this file and then restarts the server.