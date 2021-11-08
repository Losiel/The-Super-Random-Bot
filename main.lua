--
-- name: Random Place Roulette
-- author: Lusie
-- note: idented with tabs and \CR\LF newlines
--
local da = require("discordia")
local coro = require("coro-http")
local json = require("json")

local client = da.Client()

local token = [[]]
client:run("Bot " .. token)

--
-- Internal functions 

-- alias for coro.request and json.decode
local function httpGet(url)
	local SUC, result, body = pcall(coro.request, "GET", url)
	if not SUC then return end
	
	local SUC, body = pcall(json.decode, body)
	return SUC and body
end

-- returns true if a game with the following info: games.roblox.com/v1/games
-- meets with the criteria of choosing games
local function isValidGame(data)
	return (
		(data.description ~= "This is your very first ROBLOX creation. Check it out, then make it your own with ROBLOX Studio!") -- avoid the description of unmodified places
		and
		(not (data.name:find("'s Place"))) -- avoid names that end with 's Place
		and
		(data.name:find("[^%#]")) -- avoid games that the whole name is tagged
	)
end

-- check out games.roblox.com/v1/games API
-- this function returns an object from that api or nil
local function getInfoOfRandomGames(min_id, max_id)
	local ids = {}
	for i = 1, 20 do
		table.insert(ids, tostring(math.random(min_id, max_id)))
	end
	
	local url = "https://games.roblox.com/v1/games?universeIds=" .. table.concat(ids, ",")
	return httpGet(url)
end

-- tries 6 times to get a valid game from getInfoRandomGames(9
local function randomGame(min_id, max_id)
	for attempts = 1, 6 do
		local games = getInfoOfRandomGames(min_id, max_id)
		
		for _, game in ipairs(games and games.data or {}) do
			if isValidGame(game) then
				return game
			end
		end
	end
	
	return nil, "Timeout"
end

local function getGameLink(game)
	return "https://www.roblox.com/games/" .. game.rootPlaceId
end

local function getCreatorLink(game)
	return
		game.creator.type == "User" and ("https://www.roblox.com/users/" .. game.creator.id .. "/profile")
		or
		game.creator.type == "Group" and ("https://www.roblox.com/groups/" .. game.creator.id .. "/about")
end

local function getCreatorAvatar(game)
	if game.creator.type ~= "User" then
		return
	end
	
	local url = ("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=48x48&format=Png&isCircular=false"):format(tostring(game.creator.id))
	local data = httpGet(url)
	return data and data.data and data.data[1]
end

local function getGameThumbnail(game)
	local url = "https://thumbnails.roblox.com/v1/games/multiget/thumbnails?countPerUniverse=1&defaults=true&size=480x270&format=Jpeg&isCircular=false&universeIds=" .. game.id
	local data = httpGet(url)
	return data and data.data and data.data[1].thumbnails[1]
end

local function getGameIcon(game)
	local url = "https://thumbnails.roblox.com/v1/places/gameicons?size=50x50&format=Png&isCircular=false&placeUrl=" .. tostring(game.id)
	local data = httpGet(url)
	return data and data.data and data.data[1]
end

-- receives a roblox date (for example: "2020-04-26T09:35:06.2Z"
-- and returns "2020-04-26"
local function getMainDate(roblox_date)
	return roblox_date:sub(1, 10)
end

--
-- Commands
local commands = {}

local MIN_ID = 10000
local MAX_ID = 3582601336

function commands.rgame(msg)
	-- loading message
	local loadingmsg = msg:reply {embed = {
		title = "Fetching game...";
	}}
	
	-- display game
	local benchmark = os.time()
	local game, fetcherror = randomGame(MIN_ID, MAX_ID)
	if not game then
		loadingmsg:delete()
		msg:reply {
			embed = {
				title = "Error: " .. fetcherror;
			}
		}
		return
	end
	
	local embed = {}
	embed.title = game.name
	embed.description = game.description
	embed.url = getGameLink(game)
	embed.footer = {
		text = "Took " .. os.time() - benchmark .. "s to fetch game";
	}
	embed.author = {
		name = game.creator.name;
		url = getCreatorLink(game);
	}
	local avatar = getCreatorAvatar(game)
	if avatar then
		embed.author.icon_url = avatar.imageUrl
	end
	
	local icon = getGameIcon(game)
	if icon then
		embed.thumbnail = {
			url = icon.imageUrl;
			width = 50;
			height = 50;
		}
	end
	
	local image = getGameThumbnail(game)
	if image then
		embed.image = {
			url = image.imageUrl;
			width = 0;
			height = 0;
		}
	end
	
	embed.fields = {
		{
			name = "Data";
			value = (function()
				str = ":star: " .. game.favoritedCount
				str = str .. "\n :busts_in_silhouette: Users playing: " .. game.playing
				str = str .. "\n :busts_in_silhouette: Visits: " .. game.visits
				str = str .. "\n :busts_in_silhouette: Max players: " .. game.maxPlayers
				local created = getMainDate(game.created)
				local updated = getMainDate(game.updated)
				str = str .. "\n :calendar: Created: " .. getMainDate(created)
				str = str .. "\n :calendar: " .. ((updated == created and "Never updated") or ("Updated: " .. updated))
				return str
			end)();
			inline = false;
		}
	}
	
	msg:reply({embed = embed})
	
	-- remove loading message
	loadingmsg:delete()
end

--
-- User Interface
local function processMessage(msg)
	if msg.content == "rgame" then
		commands.rgame(msg)
	end
end

client:on("messageCreate", processMessage)
