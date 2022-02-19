# Information
The code is using [Discordia](https://github.com/SinisterRectus/Discordia/), [Luvit](https://luvit.io/) and of course: Lua.<br/>
This bot is dedicated to receiving random content from the internet, start with `rhelp`.

# Running
This bot depends on [Discordia](https://github.com/SinisterRectus/Discordia/) and [Luvit](https://luvit.io/).<br/>
To install Luvit, go [here](https://luvit.io/install.html).<br/>
To install Discordia, run the following command: `lit install SinisterRectus/discordia`<br/>
To run the bot, run the following command: `luvit main.lua`

# Note
The bot requires of your Discord bot's token (to put your bot online) and your Roblox account's token (to check if a game is online)<br/>
That information should be inside `important_info.lua`, so create one with:<br/>
```lua
return {
	BOT_TOKEN = "";
	ROBLOX_TOKEN = "";
}
```
`BOT_TOKEN` should be your Discord's bot token<br/>
`ROBLOX_TOKEN` should be your Roblox's cookie, you might not provide it (and leave it as an empty string), but if thats the case then the bot wont be able to check if a game is public<br/>

# Credits
This bot uses the following libraries
- ~~[json](https://github.com/rxi/json.lua)~~ (replaced with Luvit's JSON)
- [html](https://github.com/thenumbernine/htmlparser-lua/blob/master/htmlparser.lua) (used to parse Roblox ads)
- [serpent](https://github.com/pkulchenko/serpent) (for debugging purposes, not actually used on the code but its there to debug)
