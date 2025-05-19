local fix_script_name = require("./utils/fix-script-name")

type Token =
	{ kind: "call_function", fn: string, raw_args: string }
	| { kind: "open_scope" }
	| { kind: "close_scope" }
	| { kind: "if_statement", condition: string }
	| { kind: "else_keyword" }
	| { kind: "declare_variable", type: string, name: string, is_array: boolean }
	| { kind: "overwrite_variable", name: string, value: string }

local function translate_datatype(datatype: string): string
	return if datatype == "int" then "number" elseif datatype == "char" then "string" else "nil"
end

local function trim_quotes(str: string): string
	return string.match(str, '^"(.*)"$') or str
end

local function trim_escaped_quotes(str: string): string
	return string.gsub(str, '^\\"(.*)\\"$', '"%1"')
end

local function collect_args(raw_args: string): { any }
	raw_args = string.gsub(raw_args, "\\n", "\n")
	raw_args = string.gsub(raw_args, '\\"', "\0")

	local args = {}
	local offset = 1
	local len = #raw_args
	local current = ""
	local in_quotes = false

	local idx = 0
	local function push_arg(raw_arg: string)
		raw_arg = string.gsub(raw_arg, "\0", '"')

		local trimmed = string.match(raw_arg, "^ ?(.-) *$")
		if trimmed and #trimmed ~= 0 then
			idx += 1
			args[idx] = trimmed
		end
	end

	while offset <= len do
		local char = string.sub(raw_args, offset, offset)

		if char == '"' then
			current ..= char
			if in_quotes then
				push_arg(current)
				current = ""
				in_quotes = false
			else
				in_quotes = true
			end
		elseif char == "," and not in_quotes then
			push_arg(current)
			current = ""
		else
			current ..= char
		end

		offset += 1
	end

	if #current ~= 0 then
		push_arg(current)
	end

	return args
end

local function translate_call(
	fn: string,
	args: { string },
	state: {
		dependencies: { [string]: true },
	}
): string
	if fn == "CallScript" then
		local script = trim_quotes(args[1])
		state.dependencies[script] = true
		return `{fix_script_name(script)}.main(controls)`
	elseif fn == "CallSection" then
		local section = trim_quotes(args[1])
		return `{section}(controls)`
	elseif fn == "JumpSection" then
		local section = trim_quotes(args[1])
		return `{section}(controls)`
	elseif fn == "Wait" then
		local duration = args[1]
		return `controls.wait({duration})`
	elseif fn == "OutputLine" then
		local speaker, text, behavior = args[3], args[4], args[5]
		text = string.gsub(text, "\n", "\\n")
		text = string.gsub(text, '"', '\\"')
		return `controls.append({speaker}, {trim_escaped_quotes(text)}, {behavior})`
	elseif fn == "OutputLineAll" then
		local speaker, text, behavior = args[1], args[2], args[3]
		text = string.gsub(text, "\n", "\\n")
		text = string.gsub(text, '"', '\\"')
		return `controls.append({speaker}, {trim_escaped_quotes(text)}, {behavior})`
	elseif fn == "ClearMessage" then
		return "controls.clear()"
	elseif fn == "SetValidityOfInput" then
		local validity = args[1]
		return `controls.set_skip_allowed({validity})`
	elseif fn == "DisableWindow" then
		return "controls.hide()"
	elseif fn == "SavePoint" then
		local chapter, stage = args[1], args[2]
		return `controls.save({chapter}, {stage})`
	elseif fn == "DrawBG" then
		local background = args[1]
		return `controls.set_background({background})`
	elseif fn == "FadeBG" then
		local duration = args[1]
		return `controls.fade_out_background({duration})`
	elseif fn == "DrawScene" then
		local scene, duration = args[1], args[2]
		return `controls.draw_scene({scene}, {duration})`
	elseif fn == "DrawSceneWithMask" then
		-- TODO
		local scene, duration = args[1], args[5]
		return `controls.draw_scene({scene}, {duration})`
	elseif fn == "DrawBustshot" then
		-- TODO
		local id, sprite, offset_x, offset_y, fade_in_time, yield =
			args[1], args[2], args[3], args[4], args[15], args[16]
		return `controls.draw_sprite({id}, {sprite}, vector.create({offset_x}, {offset_y}), {fade_in_time}, {yield})`
	elseif fn == "MoveBustshot" then
		local id, offset_x, offset_y, duration, yield = args[1], args[3], args[4], args[7], args[8]
		return `controls.move_sprite({id}, vector.create({offset_x}, {offset_y}), {duration}, {yield})`
	elseif fn == "FadeBustshot" then
		local id, duration, yield = args[1], args[7], args[8]
		return `controls.fade_out_sprite({id}, {duration}, {yield})`
	elseif fn == "DrawBustshotWithFiltering" then
		-- TODO
		local id, sprite, offset_x, offset_y, fade_in_time, yield =
			args[1], args[2], args[5], args[6], args[14], args[15]
		return `controls.draw_sprite({id}, {sprite}, vector.create({offset_x}, {offset_y}), {fade_in_time}, {yield})`
	elseif fn == "FadeBustshotWithFiltering" then
		-- TODO
		local id, duration, yield = args[1], args[7], args[8]
		return `controls.fade_out_sprite({id}, {duration}, {yield})`
	elseif fn == "FadeAllBustshots" then
		local duration, yield = args[1], args[2]
		return `controls.fade_out_all_sprites({duration}, {yield})`
	elseif fn == "DrawSprite" then
		local id, sprite, offset_x, offset_y, yield = args[1], args[2], args[5], args[6], args[16]
		return `controls.draw_sprite({id}, {sprite}, vector.create({offset_x}, {offset_y}), NULL, {yield})`
	elseif fn == "DrawSpriteWithFiltering" then
		-- TODO
		local id, sprite, offset_x, offset_y, fade_in_time, yield =
			args[1], args[2], args[5], args[6], args[12], args[13]
		return `controls.draw_sprite({id}, {sprite}, vector.create({offset_x}, {offset_y}), {fade_in_time}, {yield})`
	elseif fn == "MoveSprite" then
		local id, offset_x, offset_y, duration, yield = args[1], args[2], args[3], args[9], args[10]
		return `controls.move_sprite({id}, vector.create({offset_x}, {offset_y}), {duration}, {yield})`
	elseif fn == "FadeSprite" then
		local id, duration, yield = args[1], args[2], args[3]
		return `controls.fade_out_sprite({id}, {duration}, {yield})`
	elseif fn == "PlayBGM" then
		local id, music = args[1], args[2]
		return `controls.play_music({id}, {music})`
	elseif fn == "StopBGM" then
		local id = args[1]
		return `controls.stop_music({id})`
	elseif fn == "FadeOutBGM" then
		local id, duration, yield = args[1], args[2], args[3]
		return `controls.fade_out_music({id}, {duration}, {yield})`
	elseif fn == "PlaySE" then
		local sfx = args[2]
		return `controls.play_sound_effect({sfx})`
	elseif fn == "Select" then
		local options = args[2]
		return `controls.prompt_selection({options})`
	elseif fn == "StoreValueToLocalWork" then
		local var, value = args[1], args[2]
		return `controls.set({var}, {value})`
	elseif fn == "LoadValueFromLocalWork" then
		local var = args[1]
		return `controls.get({var})`
	elseif fn == "SetGlobalFlag" then
		local flag, value = args[1], args[2]
		return `controls.set_global_flag({flag}, {value})`
	elseif fn == "GetGlobalFlag" then
		local flag = args[1]
		return `controls.get_global_flag({flag})`
	end

	-- 07th-mod
	if fn == "ModCallScriptSection" then
		local script, section = trim_quotes(args[1]), trim_quotes(args[2])
		state.dependencies[script] = true
		return `{fix_script_name(script)}.{section}(controls)`
	elseif fn == "ModDrawCharacter" then
		local id, sprite, index, offset_x, offset_y, fade_in_time, yield =
			args[1], args[3], args[4], args[5], args[6], args[17], args[18]
		return `controls.draw_character({id}, {sprite}, {index}, vector.create({offset_x}, {offset_y}), {fade_in_time}, {yield})`
	elseif fn == "ModDrawCharacterWithFiltering" then
		local id, sprite, index, offset_x, offset_y, fade_in_time, yield =
			args[1], args[3], args[4], args[7], args[8], args[16], args[17]
		return `controls.draw_character({id}, {sprite}, {index}, vector.create({offset_x}, {offset_y}), {fade_in_time}, {yield})`
	elseif fn == "ModPlayBGM" then
		local id, music = args[1], args[2]
		return `controls.play_music({id}, {music})`
	elseif fn == "ModFadeOutBGM" then
		local id, duration, yield = args[1], args[2], args[3]
		return `controls.fade_out_music({id}, {duration}, {yield})`
	elseif fn == "ModPlayMovie" then
		local movie = args[1]
		return `controls.play_movie({movie})`
	end

	return "controls.noop()"
end

local function iter_declare_fn(source: string): () -> (string?, string, string)
	return string.gmatch(source, "([%w_]+)%s+([%w_]+)%s*%(%s*%)%s*(%b{})") :: any
end

local function get_line_task(line: string): Token?
	line = string.match(line, "^%s*(.-)%s*$") :: string

	do
		local condition = string.match(line, "^if%s*%((.+)%)%s*$")
		if condition then
			return { kind = "if_statement", condition = condition }
		end
	end

	do
		local fn, raw_args = string.match(line, "^(%w+)%s*%((.-)%)%s*;$")
		if fn and raw_args then
			return { kind = "call_function", fn = fn, raw_args = raw_args }
		end
	end

	do
		local type, name = string.match(line, "^(%S+)%s+(%S+)%s*;$")
		if type and name then
			local array = string.match(name, "^(.+)%[%d+%]$")
			name = array or name
			return { kind = "declare_variable", type = type, name = name, is_array = array ~= nil }
		end
	end

	do
		local name, value = string.match(line, "^%s*(.-)%s*=%s*(.-)%s*;$")
		if name and value then
			return { kind = "overwrite_variable", name = name, value = value }
		end
	end

	do
		if string.match(line, "^{$") then
			return { kind = "open_scope" }
		end
	end

	do
		if string.match(line, "^}$") then
			return { kind = "close_scope" }
		end
	end

	do
		if string.match(line, "^else$") then
			return { kind = "else_keyword" }
		end
	end

	return nil
end

local function translate(source: string, require_root: string): (string, { [string]: true })
	local dependencies = {} :: { [string]: true }
	local constants = {} :: { [string]: any }
	local exports = {} :: { [string]: true }

	constants.TRUE = true
	constants.FALSE = false
	constants.NULL = "nil"

	source = string.gsub(source, "//[^\n]*", "") -- erase comments
	source = string.gsub(source, "\r\n", "\n") -- normalize newlines
	source = string.gsub(source, "\n%s+", "\n"):gsub("^%s+", ""):gsub("%s+\n", "\n"):gsub("%s+$", "") -- strip leading and trailing spaces
	source = string.gsub(source, "([,(\n])\n", "%1 ") -- strip useless newlines
	source = string.gsub(source, "\n(%))", "%1 ") -- strip more useless newlines
	source = string.gsub(source, "([^%d])([{}])([^%d])", "%1\n%2\n%3") -- wrap braces with newlines

	local function push_constants(args: { string }, variables: { [string]: true })
		for _, arg in args do
			local arg_without_quotes = trim_quotes(arg)

			local is_number = tonumber(arg) ~= nil
			local is_string = arg_without_quotes ~= arg
			local is_call = string.find(arg, "[()]") ~= nil
			local is_alphanumeric = string.match(arg, "^[%w _]+$") ~= nil
			local is_constant = not is_number and not is_string and not is_call and is_alphanumeric

			local should_push = is_constant and constants[arg] == nil and not variables[arg]
			if should_push then
				constants[arg] = `"{arg}"`
			end
		end
	end

	local function replace_calls(input: string, variables: { [string]: true })
		local result = string.gsub(
			input,
			"(%w+)%((.-)%)",
			function(fn, raw_args)
				local args = collect_args(raw_args)
				push_constants(args, variables)
				return `{translate_call(fn, args, { dependencies = dependencies })}`
			end :: any
		)
		return result
	end

	local output = ""

	for returns, section, contents in iter_declare_fn(source) do
		local variables = {} :: { [string]: true }

		do
			local datatype = translate_datatype(returns)
			if datatype == "nil" then
				output ..= `function {section}(controls: types.Controls)\n`
			else
				output ..= `function {section}(controls: types.Controls): {datatype}\n`
			end
		end

		local previous_line_task
		local expect_close_scope = false

		for line in string.gmatch(contents, "([^\n]+)") do
			local line_task = get_line_task(line)
			if not line_task then
				continue
			end

			if previous_line_task and previous_line_task.kind == "close_scope" and line_task.kind ~= "else_keyword" then
				expect_close_scope = false
				output ..= "end\n"
			end

			if line_task.kind == "call_function" then
				local args = collect_args(replace_calls(line_task.raw_args, variables))
				push_constants(args, variables)
				output ..= `{translate_call(line_task.fn, args, { dependencies = dependencies })}\n`
			elseif line_task.kind == "if_statement" then
				output ..= `if {replace_calls(line_task.condition, variables)} then\n`
			elseif line_task.kind == "else_keyword" then
				output ..= "else\n"
			elseif line_task.kind == "declare_variable" then
				variables[line_task.name] = true
				if not line_task.is_array then
					output ..= `local {line_task.name}: {translate_datatype(line_task.type)}\n`
				else
					output ..= `local {line_task.name}: \{{translate_datatype(line_task.type)}\} = \{\}\n`
				end
			elseif line_task.kind == "overwrite_variable" then
				output ..= `{line_task.name} = {replace_calls(line_task.value, variables)}\n`
			elseif line_task.kind == "open_scope" then
				expect_close_scope = true
			end

			local should_close_scope = previous_line_task
				and previous_line_task.kind == "if_statement"
				and line_task.kind ~= "open_scope"

			if should_close_scope then
				output ..= "end\n"
			end

			previous_line_task = line_task
		end

		if previous_line_task.kind == "close_scope" or expect_close_scope then
			output ..= "end\n"
		end

		exports[section] = true
	end

	for constant, value in constants do
		output = `local {constant} = {value}\n` .. output
	end

	for dependency in dependencies do
		dependency = fix_script_name(dependency)
		output = `local {dependency} = require("{require_root}/{dependency}")\n` .. output
	end

	output = `local types = require("{require_root}/types")\n` .. output

	output ..= "return {\n"
	for export in exports do
		output ..= `{export} = {export},\n`
	end
	output ..= "}\n"

	return output, dependencies
end

return {
	translate = translate,
}
