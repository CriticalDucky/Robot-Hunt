local Players = game:GetService "Players"

local cachedFriends = {}

local Friends = {}

--[[
	Returns a cached list of friends for a player.
	Items in the list are as follows:

	```lua
	{
	Id: number			--The user ID of the friend
	Username: string	--The current username of the friend
	IsOnline: boolean	--Whether or not the user is presently online.
	}
	```
]]
function Friends.get(userId: number): { [number]: { Id: number, Username: string, IsOnline: boolean } }
	userId = userId or Players.LocalPlayer.UserId

	local function fetchFriends()
		local function iterPageItems(pages: FriendPages)
			return coroutine.wrap(function()
				local pagenum = 1
				while true do
					for _, item in ipairs(pages:GetCurrentPage()) do
						coroutine.yield(item, pagenum)
					end
					if pages.IsFinished then break end
					pages:AdvanceToNextPageAsync()
					pagenum = pagenum + 1
				end
			end)
		end

		local success, friendPages = pcall(function()
			return Players:GetFriendsAsync(userId)
		end)

		if not success then return {} end

		local list = {}

		for item, _ in iterPageItems(friendPages) do
			table.insert(list, item)
		end

		cachedFriends[userId] = list

		return list
	end

	return if cachedFriends[userId] then cachedFriends[userId] else fetchFriends()
end

--[[
	Returns whether or not the player is friends with any of the given users.

	Example:
	```lua
	local areFriends = Friends.are(123456789, 987654321, 1234567890)
	local areFriends = Friends.are(123456789, { 987654321, 1234567890 })
	```
]]
function Friends.are(basePlayer, ...: number | { number })
	local friends = Friends.get(basePlayer)

	local function checkFriend(userId)
		for _, friend in ipairs(friends) do
			if friend.Id == userId then return true end
		end
		return false
	end

	local args = { ... }

	if #args == 1 and typeof(args[1]) == "table" then
		args = args[1]
	end

	for _, userId in ipairs(args) do
		if checkFriend(userId) then return true end
	end

	return false
end

return Friends
