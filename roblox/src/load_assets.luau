local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function load_assets(): { [string]: string }
	local assets = ReplicatedStorage:FindFirstChild("assets")
	if assets then
		return (require)(assets)
	else
		return {}
	end
end

return load_assets
