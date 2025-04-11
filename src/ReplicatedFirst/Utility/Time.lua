local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local utilityFolder = ReplicatedFirst:WaitForChild "Utility"

local Types = require(utilityFolder:WaitForChild "Types")
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

type TimeInfo = Types.TimeInfo
type TimeRange = Types.TimeRange

local scope = Fusion.scoped(Fusion)

local timeValue = scope:Value(workspace:GetServerTimeNow())

local function date(format: string, time: number?): number
	local timeString = os.date(format, time or workspace:GetServerTimeNow())

	local number = tonumber(timeString)

	assert(timeString, "Error: os.date returned nil")
	assert(number, "Error: os.date returned a non-number")

	return number
end

local Time = {}

--[[
    Gets the current year. Returns a number (e.g. 2020).
]]
function Time.currentYear(unixTime: number?): number
	return date("%Y", unixTime)
end

--[[
    Gets the current month. Returns a number from 1 to 12.
]]
function Time.currentMonth(unixTime: number?): number
	return date("%m", unixTime)
end

--[[
    Gets the current day. Returns a number from 1 to 31.
]]
function Time.currentDay(unixTime: number?): number
	return date("%d", unixTime)
end

--[[
    Gets the current hour. Returns a number from 0 to 23.
]]
function Time.currentHour(unixTime: number?): number
	return date("%H", unixTime)
end

--[[
    Gets the current minute. Returns a number from 0 to 59.
]]
function Time.currentMinute(unixTime: number?): number
	return date("%M", unixTime)
end

--[[
    Gets the current second. Returns a number from 0 to 59.
]]
function Time.currentSecond(unixTime: number?): number
	return date("%S", unixTime)
end

--[[
    Gets the unix time that corresponds to the given time info.

    TimeInfo is a table or function that returns a table with the following keys:
    ```lua
    TimeInfo = {
        year: number
        month: number
        day: number
        hour: number
        min: number
        sec: number
    } | () -> TimeInfo
    ```
    TimeInfo can also be a number, in which case it will be returned as is.

    WARNING: Nil keys will be replaced with the current time. This is sometimes
    undesirable, so make sure your time info is complete with 0 values.
]]
function Time.getUnixFromTimeInfo(timeInfo: TimeInfo): number
	if type(timeInfo) == "function" then timeInfo = timeInfo() :: TimeInfo end

	if type(timeInfo) == "number" then return timeInfo end

	if type(timeInfo) ~= "table" then error "Error: timeInfo is not a table" end

	return os.time {
		year = timeInfo.year or Time.currentYear(),
		month = timeInfo.month or Time.currentMonth(),
		day = timeInfo.day or Time.currentDay(),
		hour = timeInfo.hour or Time.currentHour(),
		min = timeInfo.min or Time.currentMinute(),
		sec = timeInfo.sec or Time.currentSecond(),
	}
end

local TimeRange = {}
TimeRange.__index = TimeRange
TimeRange.isATimeRange = true

--[[
	Creates a new TimeRange.
	A time range represents a range of time or intervals of time.
	These intervals can be automatic, such as "every day between 12:00 and 13:00".

	`introduction` and `closing` specify when the TimeRange is out of range.
	If not specified, time ranges will be infinite.
	`introduction` and `closing` are TimeInfo types. They look like this:

	```lua
		type TimeInfo = number | () -> TimeInfo | {
			year: number?,
			month: number?,
			day: number?,
			hour: number?,
			min: number?,
			sec: number?,
		}
	```lua

	Leaving a field out of the table will default to the current time.
	So, you can make interesting time ranges like "every day at 12:00" by doing:

	```lua
		TimeRange.new({
			hour = 12,
			min = 0,
			sec = 0,
		}, {
			hour = 12,
			min = 59,
			sec = 59,
		})
	```

	You can also create a TimeRange that is a group of other TimeRanges.
	For example, you can create a TimeRange that is "every day at 12:00" or "every day at 18:00" by doing:

	```lua
		TimeRange.newGroup(
			TimeRange.new({
				hour = 12,
				min = 0,
				sec = 0,
			}, {
				hour = 13,
				min = 0,
				sec = 0,
			}),
			TimeRange.new({
				hour = 18,
				min = 0,
				sec = 0,
			}, {
				hour = 19,
				min = 0,
				sec = 0,
			})
		)
	```

	This feature is recursive, so you can create a TimeRange
	that is a group of other TimeRanges that are groups of other TimeRanges, etc.
]]
function TimeRange.new(introduction: TimeInfo?, closing: TimeInfo?): TimeRange
	local newTimeRange = setmetatable({}, TimeRange)

	newTimeRange.introduction = introduction
	newTimeRange.closing = closing

	return newTimeRange
end

--[[
	Creates a new TimeRange that is a group of other TimeRanges.
	When :isInRange() is called on this TimeRange, it will return true if any of the TimeRanges in the group are in range.
]]
function TimeRange.newGroup(...: TimeRange): TimeRange
	local newTimeRange = setmetatable({}, TimeRange)

	newTimeRange.timeRanges = { ... }

	return newTimeRange
end

-- Returns a boolean indicating whether the given TimeRange is in fact a TimeRange (via duck typing)
function TimeRange.is(timeRange: TimeRange | any): boolean
	return typeof(timeRange) == "table" and timeRange.isATimeRange == true
end

--[[
	Returns a boolean indicating whether the given time is in range.
	`timeInfo` is a TimeInfo, which can be a unix timestamp, a function that returns a TimeInfo,
	or a table that looks like this:

	```lua
	type TimeInfo = number | () -> TimeInfo | {
		year: number?,
		month: number?,
		day: number?,
		hour: number?,
		min: number?,
		sec: number?,
	}
	```

	timeInfo can also be nil, in which case the current time will be used.
]]
function TimeRange:isInRange(timeInfo: TimeInfo?)
	timeInfo = timeInfo or workspace:GetServerTimeNow()

	if self.timeRanges then
		for _, timeRange in ipairs(self.timeRanges) do
			if timeRange:isInRange(timeInfo) then return true end
		end

		return false
	else
		local timeInfoUnix = Time.getUnixFromTimeInfo(timeInfo :: TimeInfo)
		local introduction = self.introduction
		local closing = self.closing

		if introduction and closing then
			local introductionUnix = Time.getUnixFromTimeInfo(introduction)
			local closingUnix = Time.getUnixFromTimeInfo(closing)

			return introductionUnix <= timeInfoUnix and timeInfoUnix < closingUnix
		elseif introduction then
			local introductionUnix = Time.getUnixFromTimeInfo(introduction)

			return introductionUnix <= timeInfoUnix
		elseif closing then
			local closingUnix = Time.getUnixFromTimeInfo(closing)

			return timeInfoUnix < closingUnix
		else
			return true
		end
	end
end

--[[
	Gets the amount of time, in seconds, until the TimeRange is no longer in range.
	If called with a TimeRange group, it will return the amount of time until
	`:isInRange` would return false (not necessarily the amount of time until
	the current TimeRange is no longer in range)

	* An optional `timeInfo` can be passed in, which describes the time to check.
	* If the TimeRange is infinite, it will return nil.
	* If the TimeRange is not in range, it will return 0.
]]
function TimeRange:distanceToClosing(timeInfo: TimeInfo?): number?
	timeInfo = timeInfo or workspace:GetServerTimeNow()

	local timeInfoUnix = Time.getUnixFromTimeInfo(timeInfo :: TimeInfo)
	local closing = self.closing

	if self.timeRanges then
		local distance = math.huge

		for _, timeRange in ipairs(self.timeRanges) do
			if timeRange:isInRange(timeInfoUnix) then
				local distanceToClosing = timeRange:distanceToClosing(timeInfoUnix)

				if distanceToClosing > distance and distanceToClosing > 0 then
					distance = distanceToClosing
				end
			end
		end

		if distance == math.huge then
			return nil
		else
			return distance
		end
	else
		if closing then
			local closingUnix = Time.getUnixFromTimeInfo(closing)

			if closingUnix <= timeInfoUnix then
				return 0
			else
				return closingUnix - timeInfoUnix
			end
		else
			return nil
		end
	end
end

--[[
	Gets the amount of time, in seconds, until the TimeRange is in range.
	If called with a TimeRange group, it will return the amount of time until
	`:isInRange` would return true.

	* An optional `timeInfo` can be passed in, which describes the time to check.
	* If the TimeRange is infinite, it will return nil.
	* If the TimeRange is in range, it will return 0.
]]
function TimeRange:distanceToIntroduction(timeInfo: TimeInfo?): number?
	local timeInfoUnix = if timeInfo then Time.getUnixFromTimeInfo(timeInfo) else workspace:GetServerTimeNow()

	if self.timeRanges then
		local distance = math.huge

		for _, timeRange in ipairs(self.timeRanges) do
			if not timeRange:isInRange(timeInfoUnix) then
				local distanceToIntroduction = timeRange:distanceToIntroduction(timeInfoUnix)

				if distanceToIntroduction < distance then
					distance = distanceToIntroduction
				end
			end
		end

		if distance == math.huge then
			return nil
		else
			return distance
		end
	else
		local introduction = self.introduction

		if introduction then
			local introductionUnix = Time.getUnixFromTimeInfo(introduction)

			if introductionUnix <= timeInfoUnix then
				return 0
			else
				return introductionUnix - timeInfoUnix
			end
		else
			return nil
		end
	end
end

--[[
    Creates a new time range from the given time info.
    A time range represents a time interval between two points in time.

    Example usage:
    ```lua
    local timeRange = Time.newRange({
        year = 2021,
        month = 1,
        day = 1,
        hour = 0,
        min = 0,
        sec = 0,
    }, {
        year = 2021,
        month = 1,
        day = 1,
        hour = 0,
        min = 0,
        sec = 10,
    })

    print(timeRange:isInRange()) -- true if the current time is between the time range's 10 second interval
    ```
]]
function Time.newRange(introduction: TimeInfo, closing: TimeInfo): TimeRange
	return TimeRange.new(introduction, closing)
end

--[[
    Creates a new time range group from the given time ranges.
    Rather than representing a single time interval, a time range group represents a collection of time intervals.

    Example usage:
    ```lua
    local timeRangeGroup = Time.newRangeGroup(
        Time.newRange({
            year = 2021,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 0,
        }, {
            year = 2021,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 10,
        }),
        Time.newRange({
            year = 2021,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 20,
        }, {
            year = 2021,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 30,
        })
    )

    print(timeRangeGroup:isInRange()) -- true if the current time is between the time range group's *sectioned* 20 second interval
    ```
]]
function Time.newRangeGroup(...: TimeRange)
	assert(select("#", ...) > 0, "Error: Time.newRangeGroup requires at least one time range")

	for _, timeRange in { ... } do
		assert(TimeRange.is(timeRange), "Error: Time.newRangeGroup requires time ranges")
	end

	return TimeRange.newGroup(...)
end

RunService.RenderStepped:Connect(function()
	timeValue:set(workspace:GetServerTimeNow())
end)

return Time
