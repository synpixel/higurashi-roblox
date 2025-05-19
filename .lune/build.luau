local process = require("@lune/process")
local fs = require("@lune/fs")
local build = require("../src/build")

local INPUT_PATH = process.args[1]
assert(INPUT_PATH ~= nil, "failed to resolve input path")
assert(fs.isDir(INPUT_PATH), `"{INPUT_PATH}" is not a valid directory`)

build(INPUT_PATH, "dist")
