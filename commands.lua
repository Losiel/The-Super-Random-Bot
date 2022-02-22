local module = {}

local MIN_ID = 10000
local MAX_ID = 3582601336

local misc = require("misc_functions")
local roblox = require("roblox")
local github = require("github")
local gd = require("geometrydash")
local serpent = require("libs/serpent")
local timer = package.preload["timer"]

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

local function generateEmbedForGame(gameinfo)
	local embed = {}
	embed.title = gameinfo.name
	embed.description = gameinfo.description
	embed.url = roblox.getGameLink(gameinfo)
	embed.color = misc.successColor
	
	embed.footer = {
		text =
			(
				(gameinfo.cached and "(Cached, took " .. gameinfo.benchmark .. "s)")
				or
				("Took " .. gameinfo.benchmark .. "s to fetch game")
			)
			.. " · Developer info {UniverseId: " .. gameinfo.id .. "}";
	}
	embed.author = {
		name = gameinfo.creator.name;
		url = roblox.getCreatorLink(gameinfo);
	}
	local avatar = roblox.getCreatorAvatar(gameinfo)
	if avatar then
		embed.author.icon_url = avatar.imageUrl
	end
	
	local icon = roblox.getGameIcon(gameinfo)
	if icon then
		embed.thumbnail = {
			url = icon and icon.imageUrl or roblox.defaultIcon;
			width = 50;
			height = 50;
		}
	end
	
	local image = roblox.getGameThumbnail(gameinfo)
	embed.image = {
		url = image and image.imageUrl or roblox.defaultThumbnail;
		width = 480;
		height = 270;
	}
	
	local str = ""
	
	-- favorites
	str = str .. ":star: " .. ((gameinfo.favoritedCount == 0 and "No favorites") or gameinfo.favoritedCount)
	
	-- upvotes
	local upvotes = roblox.getGameUpvotes(gameinfo)
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
	
	-- people playing
	str = str .. "\n :busts_in_silhouette: " .. ((gameinfo.playing == 0 and "Nobody is playing") or ("Users playing: " .. gameinfo.playing))
	
	-- visits
	str = str .. "\n :busts_in_silhouette: " .. ((gameinfo.visits == 0 and "**No visits**") or ("Visits: " .. gameinfo.visits))
	
	-- maxplayers
	str = str .. "\n :busts_in_silhouette: Max players: " .. gameinfo.maxPlayers
	
	-- dates
	local created = roblox.getMainDate(gameinfo.created)
	local updated = roblox.getMainDate(gameinfo.updated)
	str = str .. "\n :calendar: Created: " .. roblox.getMainDate(created)
	str = str .. "\n :calendar: " .. ((updated == created and "**Never updated**") or ("Updated: " .. updated))
	
	-- genre
	str = str .. "\n :performing_arts: Genre: " .. (gameinfo.isAllGenre and "All" or gameinfo.genre)
		
	if gameinfo.copyingAllowed then
		str = str .. "\n :link: **THIS GAME IS UNCOPYLOCKED**"
	end
				
	if tonumber(roblox.getMainAge(gameinfo.created)) <= 2014 then
		str = str .. "\n :open_mouth: **THIS GAME IS OLD**"
	end
				
	if upvotes and upvotes.downVotes > upvotes.upVotes then
		str = str .. "\n :warning: **THIS GAME HAS MORE DOWNVOTES THAN UPVOTES**"
	end
	
	embed.fields = {
		{
			name = "Data";
			value = str;
			inline = false;
		}
	}
	
	return embed
end

local cached_games = {}
local function giveRandomGame(msg, attempts, ids)
	-- display game
	local benchmark = os.time()
	
	local gameinfo = table.remove(cached_games, 1)
	local fetcherror;
	local generated = false
	
	if not gameinfo then
		for i = 1, 5 do
			coroutine.wrap(function()
				gameinfo, fetcherror = roblox.randomGame(MIN_ID, MAX_ID, attempts, ids)
				if gameinfo then
					gameinfo.benchmark = os.time() - benchmark
				end
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
		
		if loadingmsg then -- there is a possibility it can be nil
			loadingmsg:delete()
		end
	end
	
	if not gameinfo then
		msg:reply {
			embed = {
				title = "Error: " .. fetcherror;
				color = misc.errorColor;
			}
		}
		return
	end
	
	local embed = generateEmbedForGame(gameinfo)
	
	msg:reply({embed = embed})
end

function module.rgame(msg)
	giveRandomGame(msg, 25, 15)
end

function module.rad(msg)
	local ad = roblox.parseAd(roblox.getAdHtml())
		
	msg:reply {
		embed = {
			title = ad.name or "Ad";
			url = ad.link;
			color = misc.successColor;
			image = {
				url = ad.image;
				height = ad.height;
				width = ad.width;
			};
		}
	}
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
					   .. "\n`rgd   ` - Random Geometry Dash level"
					   .. "\n`rgit  ` - Random Github repository"
					   .. "\n||`[REDACTED]`|| - ||`[REDACTED]`||"
		}
	}
end

function module.rgd(msg)
	-- this doesnt need caching or anything complex as
	-- getting a random playable geometry dash level doesnt require that many complexity
	local level
	
	loadingmsg = msg:reply {embed = {
		title = "Fetching level...";
		color = misc.warningColor;
	}}
	
	repeat
		level = gd.getLevelInfo(gd.getRandomId())
	until level ~= -1 -- if there was an error, gd.getLevelInfo will return -1, so we want to keep going if there are any errors
	
	print("Found geometry dash level " .. level.id)
	
	local embed = {}
	embed.title = level.name
	embed.description = level.description ~= "(No description provided)" and level.description or ""
	embed.url = gd.getBrowserLink(level)
	embed.color = misc.successColor
	
	embed.author = {
		name = level.author;
		url = gd.getUserLink(level.playerID);
		icon_url = gd.getUserIcon(level.author);
	}
	
	embed.footer = {
		text = "Level id: " .. level.id
	}
	
	local str = ""	
	
	-- difficulty
	str = str .. gd.difficultyFaces[level.difficulty] .. " " .. level.difficulty
	
	-- downloads
	str = str .. "\n :inbox_tray: " .. level.downloads
	
	-- likes
	local upvotes = level.likes
	if upvotes > 0 then
		str = str .. "\n :thumbsup: " .. upvotes
	elseif upvotes < 0 then
		str = str .. "\n :thumbsdown: " .. upvotes
	else
		str = str .. "\n :thumbsup: :thumbsdown: 0"
	end
	
	-- stars
	if level.stars > 0 then
		str = str .. "\n :star: " .. level.stars
	end
	
	-- coins
	if level.coins > 0 then
		str = str .. "\n :coin: " .. level.coins
		if not level.verifiedCoins then
			str = str .. " (Unverified)"
		end
	end
	
	-- length
	str = str .. "\n :alarm_clock: " .. level.length
	
	-- ldm
	if level.ldm then
		str = str .. "\n :open_mouth: **This level allows LDM**"
	end
	
	-- two player
	if level.twoPlayer then
		str = str .. "\n :open_mouth: **This level is for two players**"
	end
	
	-- song
	local song = ""
	if level.songLink then
		song = song .. "[" .. level.songName .. "](" .. level.songLink .. ")"
	else
		song = song .. level.songName
	end
	song = song .. "\n by " .. level.songAuthor
	
	embed.fields = {
		{
			name = "Data";
			value = str;
			inline = false;
		},
		{
			name = "Song";
			value = song;
			inline = false;
		}
	}
	
	msg:reply {
		embed = embed
	}
	loadingmsg:delete()
end

function module.rgit(msg)
	-- this doesnt need caching or anything complex as
	-- getting a random public github repository doesnt require that many complexity
	local repo
	local attempts = 0
	repeat
		local id = github.randomId()
		repo = github.getRepoFromId(id)
		if not repo then
			attempts = attempts + 1
			timer.sleep(100)
		end
	until repo and repo.visibility == "public" or attempts > 10
	
	print("Found repo", repo.name)
	
	if attempts > 10 then
		msg:reply {
			embed = {
				color = misc.errorColor;
				title = "Timeout!";
			}
		}
	end
	
	local embed = {}
	embed.title = repo.name
	embed.url = repo.html_url
	embed.description = repo.description or ""
	embed.color = misc.successColor
	
	embed.author = {
		name = repo.owner.login;
		url = repo.owner.url;
		icon_url = repo.owner.avatar_url;
	}
	
	local str = ""
	
	-- language
	local lang = repo.language or (repo.parent and repo.parent.language)
	if lang then
		str = str .. "**Language: " .. lang .. "**"
	end
	
	-- license
	if repo.license then
		str = str .. "\n**License: " .. (repo.license and repo.license.name) .. "**"
	end
	
	-- stars
	str = str .. "\n:star: " .. repo.stargazers_count
	
	-- watchers
	str = str .. "\n:eye: " .. repo.watchers_count
	
	-- forks
	str = str .. "\n:menorah: " .. repo.forks
	
	-- if fork
	if repo.fork then
		str = str .. "\n:open_mouth: **Fork of this [repo]("..repo.parent.html_url..")**"
	end
	
	embed.fields = {
		{
			name = "Data";
			value = str;
			inline = false;
		}
	}
	
	msg:reply {
		embed = embed
	}
end

return module
