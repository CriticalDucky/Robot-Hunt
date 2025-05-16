--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

type UsedAs<T> = Fusion.UsedAs<T>
--#endregion

export type Props = {
	-- Default props
	Name: UsedAs<string>?,
	LayoutOrder: UsedAs<number>?,
	Position: UsedAs<UDim2>?,
	AnchorPoint: UsedAs<Vector2>?,
	Size: UsedAs<UDim2>?,
	AutomaticSize: UsedAs<Enum.AutomaticSize>?,
	ZIndex: UsedAs<number>?,
}

--[[
	This component creates a...

	Example usage:
	```lua
	
	```
]]
local function Component(scope: Fusion.Scope, props: Props)

end

return Component
