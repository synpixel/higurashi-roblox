local fs = require("@lune/fs")
local dirs = require("./dirs")

local EXTENSIONS = { "png", "ogg", "mp4" }

local function try_collect_assets(dir: string, out_dir: string, prefix: string)
	if not fs.isDir(dir) then
		return
	end

	for _, name in fs.readDir(dir) do
		local path = `{dir}/{name}`
		name = if prefix then `{prefix}+{name}` else name

		if fs.isDir(path) then
			try_collect_assets(path, out_dir, name)
			continue
		end

		if fs.isFile(`{out_dir}/{name}`) then
			warn(`{out_dir}/{name} already exists`)
			continue
		end

		local extension = string.match(name, "%.([^.]+)$")
		if table.find(EXTENSIONS, extension :: any) then
			fs.copy(path, `{out_dir}/{name}`)
		end
	end
end

local function collect_assets(root_dir: string, out_dir: string)
	local streaming_assets = dirs.streaming_assets(root_dir)

	try_collect_assets(`{streaming_assets}/CG`, out_dir, "images")
	try_collect_assets(`{streaming_assets}/movies`, out_dir, "movies")
	try_collect_assets(`{streaming_assets}/BGM`, out_dir, "music")
	try_collect_assets(`{streaming_assets}/ExtraBGM`, out_dir, "music")
	try_collect_assets(`{streaming_assets}/SE`, out_dir, "sfx")
	try_collect_assets(`{streaming_assets}/ExtraSE`, out_dir, "sfx")
end

return collect_assets
