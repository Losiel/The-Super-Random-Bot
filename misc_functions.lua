local module = {}

local da = package.preload["discordia"]
local coro = package.preload["coro-http"]
local json = package.preload["json"]
local important = require("important_info")
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

return module
