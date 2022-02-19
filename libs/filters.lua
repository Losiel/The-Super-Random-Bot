local f = {}

f.classic = function(asset)
	local name = asset.Name
	local desc = asset.Description
	
	local t = "'s Place"
	local d = desc ~= "This is your very first ROBLOX creation. Check it out, then make it your own with ROBLOX Studio!"
	
	local place = asset.AssetTypeId == 9
	local errors = asset.errors == nil
	
	return (name:sub(-(#t)) ~= t) and d and place and errors
end

return f