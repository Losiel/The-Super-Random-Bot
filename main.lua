--
-- name: Random Place Roulette
-- author: Lusie
--
local da = require("discordia")
local coro = require("coro-http")
local json = require("json")
local timer = require("timer")
package.preload["discordia"] = da
package.preload["coro-http"] = coro
package.preload["json"] = json
package.preload["timer"] = timer
-- the reason I have to load packages like that, it's because
-- doing 'require' outside of the file given to the luvit command
-- doesnt work properly, so doing that apparently made other files
-- be able to use 'require' without problems

local html = require("libs/html")

local important = require("important_info")
local misc = require("misc_functions")
local game = require("roblox")
local commands = require("commands")

local client = da.Client()

client:run("Bot " .. important.BOT_TOKEN)

--
-- User Interface
local function processMessage(msg)
	local command = commands[msg.content]
	
	if (not command) then
		return
	end
	
	command(msg)
end

client:on("messageCreate", processMessage)
