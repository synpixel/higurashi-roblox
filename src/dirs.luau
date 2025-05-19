local fs = require("@lune/fs")

local function data(root_dir: string): string
	for _, dir in fs.readDir(root_dir) do
		if string.match(dir, "_Data$") then
			return `{root_dir}/{dir}`
		end
	end
	error("failed to find data directory")
end

local function streaming_assets(root_dir: string): string
	return `{data(root_dir)}/StreamingAssets`
end

local function scripts(root_dir: string): string
	return `{data(root_dir)}/StreamingAssets/Scripts`
end

return {
	data = data,
	streaming_assets = streaming_assets,
	scripts = scripts,
}
