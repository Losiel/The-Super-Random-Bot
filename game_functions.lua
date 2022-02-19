local module = {}

local important = require("important_info")
local misc = require("misc_functions")

-- returns true if a game with the following info: games.roblox.com/v1/games
-- meets with the criteria of choosing games
module.isValidGame = {
	expr = function(data)
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
	end;
	filterPrivateGames = true;
}

module.isValidLessStrictGame = {
	expr = module.isValidGame.expr;
	filterPrivateGames = false;
}

function module.isValidGoodGame(data)
	return (
		data.description ~= "This is your very first ROBLOX creation. Check it out, then make it your own with ROBLOX Studio!" -- avoid the description of unmodified places
		and
		data.description ~= "This is your very first Roblox creation. Check it out, then make it your own with Roblox Studio!"
		and
		data.name ~= "Untitled Game"
		and
		(not (data.name:find("'s Place"))) -- avoid names that end with 's Place
		and
		(not (data.name:find("'s #####")))
		and
		data.name:find("[^%#]") -- avoid games that the whole name is tagged
		and
		data.visits > 0
		and
		data.updated ~= data.created
		and
		data.favoritedCount > 0
		-- and
		-- (not data.isAllGenre)
	)
end

-- check out games.roblox.com/v1/games API
-- this function returns an object from that api or nil
-- every of the following games have an extra field 'isPlayable'
function module.getInfoOfRandomGames(min_id, max_id, generated_ids)
	local ids = {}
	for i = 1, generated_ids do
		table.insert(ids, tostring(math.random(min_id, max_id)))
		-- table.insert(ids, "2612347489")
	end
	
	return misc.getGameInfo(table.concat(ids, ","))
end

-- tries 6 times to get a valid game from getInfoRandomGames()
function module.randomGame(min_id, max_id, filter, attempts, ids)
	print("Requested game")
	
	for attempts = 1, attempts do
		local games = module.getInfoOfRandomGames(min_id, max_id, ids)
		
		for _, game in ipairs(games and games.data or {}) do
			if filter.expr(game) then
				if not filter.filterPrivateGames then
					print("Found game")
					return game
				end
				
				local status = misc.getPlayabilityStatus(game)
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

return module