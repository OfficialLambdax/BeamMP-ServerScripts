# Lua Hangup Mitigator Script

## Motivation
The beammp server is plagued by a bug that hangups a lua state (that casually crashes data event rich servers) in a specific case. Once it enters this hangup state, the server can rarely recover from it and usually just crashes. This bug has been present for a while and many communities expressed their hate for it. Unfortunately it is impossible to fix this bug without a full rewrite of a core system in the server. You can track that progress here https://github.com/BeamMP/BeamMP-Server/pull/256

This script tries to detect the lua hangup bug before it occures and tries to kick the player causing it.

## Downside
This script is not player friendly. It will kick players that have a less fast computer. If it takes them eg. longer to load a vehicle then `TIME_UNTIL_KICK` in `main.lua` is set to, then they are thrown out with the Kick message "Kicked by system".

## Usage
Changing `TIME_UNTIL_KICK` to a lower number makes the script even less player friendly, but more likely to prevent a server crash caused by the lua hangup. Increasing the value, makes it more player friendly, but less able to prevent the crash.

## Feedback
I got feedback from Ashmaker000 telling me that a number of 20 seconds in `TIME_UNTIL_KICK` also gives solid results

## WIP
Unlike my other scripts, this one yet has to undergo long term testing to fine tune the numbers and to perhaps introduce better ways of detecting it.