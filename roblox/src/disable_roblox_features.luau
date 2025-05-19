local StarterGui = game:GetService("StarterGui")

local DISABLE_RESET_RETRIES = 8

local function disable_reset_button()
	for _ = 1, DISABLE_RESET_RETRIES do
		local ok = pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
		if ok then
			break
		end
		task.wait()
	end
end

local function disable_roblox_features()
	local camera = workspace.CurrentCamera
	camera.FieldOfView = 1
	camera.CFrame = CFrame.fromMatrix(Vector3.zero, Vector3.zero, Vector3.zero)
	camera.Focus = CFrame.fromMatrix(Vector3.zero, Vector3.zero, Vector3.zero)

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	task.spawn(disable_reset_button)
end

return disable_roblox_features
