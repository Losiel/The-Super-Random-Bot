local module = {}

local MIN_ID = 10000
local MAX_ID = 3582601336

local misc = require("misc_functions")
local game = require("game_functions")
local serpent = require("libs/serpent")
local timer = package.preload["timer"]

-- rate limit commands library
local RATE_LIMITED_MSGS = {}

local function isRateLimitted(msg, command)
	return RATE_LIMITED_MSGS[#msg.channel .. command]
end

local function startRateLimit(msg, command)
	RATE_LIMITED_MSGS[#msg.channel .. command] = true
end

local function stopRateLimit(msg, command)
	RATE_LIMITED_MSGS[#msg.channel .. command] = nil
end

local function rateLimit(msg, cmd, catch, run)
	if isRateLimitted(msg, cmd) then
		catch()
		return
	end
	
	startRateLimit(msg, cmd)
	run()
	stopRateLimit(msg, cmd)
end

local function warn(msg, str)
	return function()
		msg:reply {
			embed = {
				title = str;
				color = misc.errorColor;
			}
		}
	end
end

local function generateEmbedForGame(gameinfo, time)
	local embed = {}
	embed.title = gameinfo.name
	embed.description = gameinfo.description
	embed.url = misc.getGameLink(gameinfo)
	embed.color = misc.successColor
	
	embed.footer = {
		text = (gameinfo.cached and "(Cached)" or ("Took " .. time .. "s to fetch game")) .. " · Developer info {UniverseId: " .. gameinfo.id .. "}";
	}
	embed.author = {
		name = gameinfo.creator.name;
		url = misc.getCreatorLink(gameinfo);
	}
	local avatar = misc.getCreatorAvatar(gameinfo)
	if avatar then
		embed.author.icon_url = avatar.imageUrl
	end
	
	local icon = misc.getGameIcon(gameinfo)
	if icon then
		embed.thumbnail = {
			url = icon and icon.imageUrl or misc.defaultIcon;
			width = 50;
			height = 50;
		}
	end
	
	local image = misc.getGameThumbnail(gameinfo)
	embed.image = {
		url = image and image.imageUrl or misc.defaultThumbnail;
		width = 480;
		height = 270;
	}
	
	embed.fields = {
		{
			name = "Data";
			value = (function()
				str = ":star: " .. ((gameinfo.favoritedCount == 0 and "No favorites") or gameinfo.favoritedCount)
				
				local upvotes = misc.getGameUpvotes(gameinfo)
				if not upvotes then
					str = str .. "\n :thumbsup: :thumbsdown: Unable to get game score"
				elseif upvotes.upVotes == 0 and upvotes.downVotes == 0 then
					str = str .. "\n :thumbsup: :thumbsdown: Game doesnt have score"
				else
					local downvotes = upvotes.downVotes
					local upvotes = upvotes.upVotes
					local totalvotes = upvotes + downvotes
					str = str .. ("\n :thumbsup: %d (%d%%)    :thumbsdown: %d (%d%%)"):format(
						upvotes,
						math.floor((upvotes / totalvotes)*100 + 0.5),
						downvotes,
						math.floor((downvotes / totalvotes)*100 + 0.5)
					)
				end
				
				str = str .. "\n :busts_in_silhouette: " .. ((gameinfo.playing == 0 and "Nobody is playing") or ("Users playing: " .. gameinfo.playing))
				str = str .. "\n :busts_in_silhouette: " .. ((gameinfo.visits == 0 and "**No visits**") or ("Visits: " .. gameinfo.visits))
				str = str .. "\n :busts_in_silhouette: Max players: " .. gameinfo.maxPlayers
				local created = misc.getMainDate(gameinfo.created)
				local updated = misc.getMainDate(gameinfo.updated)
				str = str .. "\n :calendar: Created: " .. misc.getMainDate(created)
				str = str .. "\n :calendar: " .. ((updated == created and "**Never updated**") or ("Updated: " .. updated))
				str = str .. "\n :performing_arts: Genre: " .. (gameinfo.isAllGenre and "All" or gameinfo.genre)
				
				if gameinfo.copyingAllowed then
					str = str .. "\n :link: **THIS GAME IS UNCOPYLOCKED**"
				end
				
				if tonumber(misc.getMainAge(gameinfo.created)) <= 2014 then
					str = str .. "\n :open_mouth: **THIS GAME IS OLD**"
				end
				
				if upvotes and upvotes.downVotes > upvotes.upVotes then
					str = str .. "\n :warning: **THIS GAME HAS MORE DOWNVOTES THAN UPVOTES**"
				end
				
				return str
			end)();
			inline = false;
		}
	}
	
	return embed
end

local cached_games = {}
local function giveRandomGame(msg, filter, attempts, ids)
	-- display game
	local benchmark = os.time()
	
	local gameinfo = table.remove(cached_games, 1)
	local fetcherror;
	local generated = false
	
	if not gameinfo then
		for i = 1, 5 do
			coroutine.wrap(function()
				gameinfo, fetcherror = game.randomGame(MIN_ID, MAX_ID, filter, attempts, ids)
				if generated then
					if not fetcherror then
						gameinfo.cached = true
						table.insert(cached_games, gameinfo)
					end
				else
					generated = true
				end
			end)()
		end
	end
	
	-- wait for a game to generate
	local loadingmsg;
	if not gameinfo then -- (in case its not cached)
		-- loading message
		loadingmsg = msg:reply {embed = {
			title = "Fetching game...";
			color = misc.warningColor;
		}}
		
		repeat
			timer.sleep(100)
		until gameinfo or fetcherror
		
		loadingmsg:delete()
	end
	
	if not gameinfo then
		loadingmsg:delete()
		msg:reply {
			embed = {
				title = "Error: " .. fetcherror;
				color = misc.errorColor;
			}
		}
		return
	end
	
	local embed = generateEmbedForGame(gameinfo, os.time() - benchmark)
	
	msg:reply({embed = embed})
end

function module.rgame(msg)
	-- rateLimit(msg, "rgame", warn(msg, "A game is already being generated"), function()
		giveRandomGame(msg, game.isValidGame, 25, 15)
	-- end)
end

-- function module.rrgame(msg)
	-- rateLimit(msg, "rgame", warn(msg, "A game is already being generated"), function()
		-- giveRandomGame(msg, game.isValidLessStrictGame, 25, 15)
	-- end)
-- end

function module.rugame(msg)
	msg:reply {
		embed = {
			title = "Command temporaly disabled";
		}
	}
	-- giveRandomGame(msg, game.isValidGoodGame, 15, 60)
end

function module.rad(msg)
	-- rateLimit(msg, "rad", warn(msg, "An ad is already being generated"), function()
		local ad = misc.parseAd(misc.getAdHtml())
	
		msg:reply {
			embed = {
				title = ad.title or "Ad";
				url = ad.link;
				color = misc.successColor;
				image = {
					url = ad.image;
					height = ad.height;
					width = ad.width;
				};
			}
		}
	-- end)
end

function module.rscp(msg)
	
	msg:reply("scp-" .. tostring(math.random(1,6000)))
end

local EMOJI_CACHE;

function module.remoji(msg)
	if not EMOJI_CACHE then
		EMOJI_CACHE = misc.httpGet("https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json")
	end
	
	msg:reply(misc.pick(EMOJI_CACHE).emoji)
end

function module.rcredits(msg)
	msg:reply(
		""
		.. "**__made by ribsi9#0539__**"
		.. "\nUsing the Lua programming language (lua.org)"
		.. "\nUsing Luvit (luvit.io) and an edited github.com/SinisterRectus/Discordia"
	)
end

function module.rhelp(msg)
	msg:reply {
		embed = {
			title = "These are the commands";
			color = misc.successColor;
			description =   "`rgame ` - Random Roblox game"
			           .. "\n`rad   ` - Random Roblox ad"
					   .. "\n`remoji` - Random emoji"
					   .. "\n`rscp  ` - Random SCP"
					   .. "\n||`[REDACTED]`|| - ||`[REDACTED]`||"
		}
	}
end

return module