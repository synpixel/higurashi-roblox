local fs = require("@lune/fs")
local dirs = require("./dirs")
local collect_assets = require("./collect-assets")
local converter = require("./converter")
local fix_script_name = require("./utils/fix-script-name")

local function read_script(dir: string, name: string): string
	if fs.isFile(`{dir}/Update/{name}.txt`) then
		return fs.readFile(`{dir}/Update/{name}.txt`)
	elseif fs.isFile(`{dir}/Scripts/{name}.txt`) then
		return fs.readFile(`{dir}/Scripts/{name}.txt`)
	else
		error(`failed to read script "{name}"`)
	end
end

local function build(root_dir: string, out_dir: string)
	if fs.isDir(out_dir) then
		fs.removeDir(out_dir)
	end
	fs.writeDir(out_dir)
	fs.writeDir(`{out_dir}/run`)
	fs.writeDir(`{out_dir}/assets`)

	local existing_scripts = {} :: { [string]: boolean }
	local streaming_assets = dirs.streaming_assets(root_dir)

	local function import(name: string)
		if existing_scripts[name] then
			return
		end
		existing_scripts[name] = true

		local source = read_script(streaming_assets, name)
		local output, dependencies = converter.translate(source, if name == "init" then "./run" else ".")
		fs.writeFile(`{out_dir}/run/{fix_script_name(name)}.luau`, output)

		for dependency in dependencies do
			import(dependency)
		end
	end

	fs.copy("src/types.luau", `{out_dir}/run/types.luau`)
	import("init")

	collect_assets(root_dir, `{out_dir}/assets`)
end

return build
