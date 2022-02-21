local important = require("important_info")
local misc = require("misc_functions")
local coro = package.preload["coro-http"]
local html = require("libs/html")

local roblox = {}

-- gets if a game is playable, this is why the Roblox token is needed
function roblox.getPlayabilityStatus(game)
	if important.ROBLOX_TOKEN == "" then
		print("ROBLOX COOKIE NOT PROVIDED!")
		return {
			reasonProhibited = "None";
		}
	end
	
	local url = "https://games.roblox.com/v1/games/multiget-place-details?placeIds=" .. game.rootPlaceId
	local data = misc.httpGet(url, {{"Cookie", important.ROBLOX_TOKEN}})
	return data and data[1]
end

function roblox.getGameLink(game)
	return "https://www.roblox.com/games/" .. game.rootPlaceId
end

function roblox.getGameInfo(universeId)
	local url = "https://games.roblox.com/v1/games?universeIds=" .. universeId
	return misc.httpGet(url)
end

function roblox.getCreatorLink(game)
	return
		game.creator.type == "User" and ("https://www.roblox.com/users/" .. game.creator.id .. "/profile")
		or
		game.creator.type == "Group" and ("https://www.roblox.com/groups/" .. game.creator.id .. "/about")
end

function roblox.getCreatorAvatar(game)
	if game.creator.type ~= "User" then
		return
	end
	
	local url = ("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=48x48&format=Png&isCircular=false"):format(tostring(game.creator.id))
	local data = misc.httpGet(url)
	return data and data.data and data.data[1]
end

roblox.defaultThumbnail = "https://t6.rbxcdn.com/13819027ce9c0c2867f2633acdece885"
function roblox.getGameThumbnail(game)
	local url = "https://thumbnails.roblox.com/v1/games/multiget/thumbnails?countPerUniverse=1&defaults=true&size=768x432&format=Jpeg&isCircular=false&universeIds=" .. game.id
	local data = misc.httpGet(url)
	return data and data.data and data.data[1].thumbnails[1]
end

roblox.defaultIcon = "https://t0.rbxcdn.com/499667ccffd43c33b9165d5b4d04a083"
function roblox.getGameIcon(game)
	local url = "https://thumbnails.roblox.com/v1/places/gameicons?size=50x50&defaults=false&format=Png&isCircular=false&placeUrl=" .. tostring(game.id)
	local data = misc.httpGet(url)
	return data and data.data and data.data[1]
end

-- gets a game upvotes
function roblox.getGameUpvotes(game)
	if game.upVotes or game.totalUpVotes then
		return {
			upVotes = game.upVotes or game.totalUpVotes;
			downVotes = game.downVotes or game.totalDownVotes;
			universeId = game.id;
		}
	end
	
	local url = "https://games.roblox.com/v1/games/votes?universeIds=" .. game.id
	local data = misc.httpGet(url)
	return data and data.data and data.data[1]
end

-- receives a roblox date (for example: "2020-04-26T09:35:06.2Z"
-- and returns "2020-04-26"
function roblox.getMainDate(roblox_date)
	return roblox_date:sub(1, 10)
end

-- gets the age of a date
function roblox.getMainAge(roblox_date)
	return roblox_date:sub(1, 4)
end

-- gets a random ad html
function roblox.getAdHtml()
	local SUC, body = coro.request("GET", "https://www.roblox.com/user-sponsorship/" .. tostring(math.random(1, 3)))
	return SUC and body
end

-- parses an ad HTML
function roblox.parseAd(data)
	local parse = html.parse(data)
	local body = {}
	
	body.link = parse[2].child[2].child[1].attrs[3].value
	body.name = parse[2].child[2].child[1].attrs[2].value
	body.image = parse[2].child[2].child[1].child[1].attrs[1].value
	body.height = parse[2].child[2].child[1].child[1].attrs[3].value
	body.width = parse[2].child[2].child[1].child[1].attrs[4].value
	
	return body
end

-- returns true if a game with the following info: games.roblox.com/v1/games
-- meets with the criteria of choosing games
function roblox.isValidGame(data)
	return (
		data.description ~= "This is your very first ROBLOX creation. Check it out, then make it your own with ROBLOX Studio!" -- avoid the description of unmodified places
		and
		data.description ~= "This is your very first Roblox creation. Check it out, then make it your own with Roblox Studio!"
		and
		(data.description and (not data.description:find("Remember that this game is early in development, which means bugs will happen and some aspects of the game will be bare bones. Thanks for understanding!"))) -- this description is too common in crappy games
		and
		(data.description and (not data.description:find("OBBY OBBY"))) -- scam crappy games
		and
		(data.description and (not data.description:find(data.name .. " " .. data.name)))
		and
		(data.description and data.description ~= data.name)
		and
		data.name ~= "Untitled Game"
		and
		(not (data.name:find("'s Place"))) -- avoid names that end with 's Place, commonly means the game was made by a new acc
		and
		(not (data.name:find("'s #####"))) -- sometimes the 's Place can get filtered because of the user name
		and
		data.name:find("[^%#]") -- avoid games that the whole name is tagged
	)
end

-- check out games.roblox.com/v1/games API
-- this function returns an object from that api or nil
-- every of the following games have an extra field 'isPlayable'
function roblox.getInfoOfRandomGames(min_id, max_id, generated_ids)
	local ids = {}
	for i = 1, generated_ids do
		table.insert(ids, tostring(math.random(min_id, max_id)))
		-- table.insert(ids, "2612347489")
	end
	
	return roblox.getGameInfo(table.concat(ids, ","))
end

-- tries 6 times to get a valid game from getInfoRandomGames()
function roblox.randomGame(min_id, max_id, attempts, ids)
	print("Requested game")
	
	for attempts = 1, attempts do
		local games = roblox.getInfoOfRandomGames(min_id, max_id, ids)
		
		for _, game in ipairs(games and games.data or {}) do
			if roblox.isValidGame(game) then
				local status = roblox.getPlayabilityStatus(game)
				if status and status.reasonProhibited == "None" then
					print("Found game")
					return game
				end
			end
		end
		
		print("Rejected, attempt ", attempts)
	end
	
	print("Timeout")
	return nil, "Timeout"
end

return roblox
