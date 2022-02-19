local module = {}

local da = package.preload["discordia"]
local coro = package.preload["coro-http"]
local json = package.preload["json"]
local important = require("important_info")
local html = require("libs/html")
local serpent = require("libs/serpent")

function module.discordColor(r, g, b)
	return da.Color.fromRGB(r, g, b).value
end

module.errorColor = module.discordColor(255, 80, 0)
module.warningColor = module.discordColor(255, 255, 80)
module.successColor = module.discordColor(20, 150, 255)

function module.pick(tbl)
	return tbl[math.random(1, #tbl)]
end

-- alias for coro.request and json.decode
function module.httpGet(url, ...)
	local SUC, result, body = pcall(coro.request, "GET", url, ...)
	if not SUC then return end
	
	local SUC, body = pcall(json.decode, body)
	return SUC and body
end

function module.getPlayabilityStatus(game)
	local url = "https://games.roblox.com/v1/games/multiget-place-details?placeIds=" .. game.rootPlaceId
	local data = module.httpGet(url, {{"Cookie", important.ROBLOX_TOKEN}})
	return data and data[1]
end

function module.getGameLink(game)
	return "https://www.roblox.com/games/" .. game.rootPlaceId
end

function module.getGameInfo(universeId)
	local url = "https://games.roblox.com/v1/games?universeIds=" .. universeId
	return module.httpGet(url)
end

function module.getCreatorLink(game)
	return
		game.creator.type == "User" and ("https://www.roblox.com/users/" .. game.creator.id .. "/profile")
		or
		game.creator.type == "Group" and ("https://www.roblox.com/groups/" .. game.creator.id .. "/about")
end

function module.getCreatorAvatar(game)
	if game.creator.type ~= "User" then
		return
	end
	
	local url = ("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=48x48&format=Png&isCircular=false"):format(tostring(game.creator.id))
	local data = module.httpGet(url)
	return data and data.data and data.data[1]
end

module.defaultThumbnail = "https://t6.rbxcdn.com/13819027ce9c0c2867f2633acdece885"
function module.getGameThumbnail(game)
	local url = "https://thumbnails.roblox.com/v1/games/multiget/thumbnails?countPerUniverse=1&defaults=true&size=768x432&format=Jpeg&isCircular=false&universeIds=" .. game.id
	local data = module.httpGet(url)
	return data and data.data and data.data[1].thumbnails[1]
end

module.defaultIcon = "https://t0.rbxcdn.com/499667ccffd43c33b9165d5b4d04a083"
function module.getGameIcon(game)
	local url = "https://thumbnails.roblox.com/v1/places/gameicons?size=50x50&defaults=false&format=Png&isCircular=false&placeUrl=" .. tostring(game.id)
	local data = module.httpGet(url)
	return data and data.data and data.data[1]
end

function module.getGameUpvotes(game)
	if game.upVotes or game.totalUpVotes then
		return {
			upVotes = game.upVotes or game.totalUpVotes;
			downVotes = game.downVotes or game.totalDownVotes;
			universeId = game.id;
		}
	end
	
	local url = "https://games.roblox.com/v1/games/votes?universeIds=" .. game.id
	local data = module.httpGet(url)
	return data and data.data and data.data[1]
end

-- receives a roblox date (for example: "2020-04-26T09:35:06.2Z"
-- and returns "2020-04-26"
function module.getMainDate(roblox_date)
	return roblox_date:sub(1, 10)
end

function module.getMainAge(roblox_date)
	return roblox_date:sub(1, 4)
end

function module.getAdHtml()
	local SUC, body = coro.request("GET", "https://www.roblox.com/user-sponsorship/" .. tostring(math.random(1, 3)))
	return SUC and body
end

function module.parseAd(data)
	local parse = html.parse(data)
	local body = {}
	
	body.link = parse[2].child[2].child[1].attrs[3].value
	body.name = parse[2].child[2].child[1].attrs[2].value
	body.image = parse[2].child[2].child[1].child[1].attrs[1].value
	body.height = parse[2].child[2].child[1].child[1].attrs[3].value
	body.width = parse[2].child[2].child[1].child[1].attrs[4].value
	
	return body
end

return module