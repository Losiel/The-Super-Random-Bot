local misc = require("misc_functions")

-- thanks colon for his gdbrowser.com/api
-- its a lot simpler than the actual geometry dash API (that I was going to use)

local gd = {}

local function getMaxId() -- gets the id of the latest geometry dash level
	local recent_levels = misc.httpGet("https://gdbrowser.com/api/search/*?type=recent")
	return recent_levels[1] and recent_levels[1].id
end

gd.MIN_ID = 128 -- first gd level
function gd.getRandomId() -- returns the id of a random geometry dash level
	if not gd.max_id then
		gd.MAX_ID = getMaxId()
	end
	
	return math.random(gd.MIN_ID, gd.MAX_ID)
end

function gd.getLevelInfo(id)
	return misc.httpGet("https://gdbrowser.com/api/level/" .. id)
end

function gd.getBrowserLink(level)
	return "https://gdbrowser.com/" .. level.id
end

function gd.getUserIcon(username)
	return "https://gdbrowser.com/icon/" .. username
end

function gd.getUserLink(userid)
	return "https://gdbrowser.com/u/" .. userid
end

gd.difficultyFaces = {
	["Auto"] = ":robot:";
	["Unrated"] = ":bust_in_silhouette:";
	["Easy"] = ":smiley:";
	["Normal"] = ":slight_smile:";
	["Hard"] = ":neutral_face:";
	["Harder"] = " :angry:";
	["Insane"] = ":rage:";
	["Easy Demon"] = ":imp:";
	["Medium Demon"] = ":imp:";
	["Hard Demon"] = ":imp:";
	["Insane Demon"] = ":imp:";
	["Extreme Demon"] = ":imp:";
}

return gd
