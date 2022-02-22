local coro = package.preload["coro-http"]
local json = package.preload["json"]
local misc = require("misc_functions")

local gh = {}

gh.MIN_ID = 10000
gh.MAX_ID = 460000000

function gh.randomId()
	return math.random(gh.MIN_ID, gh.MAX_ID)
end

function gh.getRepoFromId(id)
	local repos = misc.httpGet("https://api.github.com/repositories?since=" .. id, {
			{"User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:97.0) Gecko/20100101 Firefox/97.0"},
	})
	
	if not repos then
		return
	end
	
	local repo = misc.httpGet(repos[1].url, {
			{"User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:97.0) Gecko/20100101 Firefox/97.0"},
	})
	
	return repo
end

return gh
