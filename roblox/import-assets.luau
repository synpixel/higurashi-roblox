local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StudioService = game:GetService("StudioService")

local EXTENSIONS = { "png", "ogg", "mp4" }

local files = StudioService:PromptImportFiles(EXTENSIONS)

local paths = {} :: { [string]: File }

for _, file in files do
	local name = string.match(file.Name, "^(.+)%.(.-)$")
	if name then
		local path = string.gsub(name, "%+", "/")
		paths[path] = file
	end
end

local output = "return {\n"

for path, file in paths do
	output ..= `["{path}"] = "{file:GetTemporaryId()}",\n`
end

output ..= "}\n"

if ReplicatedStorage:FindFirstChild("assets") then
	ReplicatedStorage.assets:Destroy()
end

local assets = Instance.new("ModuleScript")
assets.Name = "assets"
assets.Source = output
assets.Parent = ReplicatedStorage
