local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local disable_roblox_features = require(script.disable_roblox_features)
local load_assets = require(script.load_assets)
local run = require(script.run.onik_003)
local ui = require(script.ui)

local assets = load_assets()

local function load_sprite(name: string): Content
	local sprite = assets[`images/{string.lower(name)}`]
	return if sprite then Content.fromUri(sprite) else Content.none
end

local function yield_if_should<T..., U...>(should_yield: boolean, fn: (T...) -> U..., ...: T...): U...
	if should_yield then
		fn(...)
	else
		task.spawn(fn, ...)
	end
end

local music = {} :: { [number]: Sound }

local variables = {} :: { [string]: any }
local global_flags = {} :: { [string]: any }

global_flags.GADVMode = 1
global_flags.GLanguage = 1
global_flags.GLinemodeSp = "Line_Normal"

ui.hide()
disable_roblox_features()

run.main({
	append = function(speaker, text, behavior)
		if speaker then
			local name = string.match(speaker, ">(%w-)<")
			local color = string.match(speaker, "^<color=(#%w-)>")
			if name and color then
				ui.set_speaker(name, Color3.fromHex(color))
			end
		end

		if text then
			ui.show()
			ui.append(text)

			if behavior == "Line_ContinueAfterTyping" then
				return
			end

			ui.wait_until_skipped()
			if behavior == "Line_Normal" then
				ui.clear()
			end
		end
	end,
	hide = ui.hide,
	clear = ui.clear,
	set_skip_allowed = ui.set_skip_allowed,
	set_background = function(name)
		ui.set_background(load_sprite(name))
	end,
	draw_scene = function(name, fade_in_time)
		ui.draw_scene(load_sprite(name), fade_in_time / 1000)
	end,
	fade_out_background = function(duration)
		ui.fade_out_background(duration / 1000)
	end,
	draw_sprite = function(id, name, offset, fade_in_time, yield)
		local transition = if fade_in_time then fade_in_time / 1000 else nil
		yield_if_should(yield, ui.draw_sprite, id, load_sprite(name), offset, transition)
	end,
	move_sprite = function(id, offset, duration, yield)
		yield_if_should(yield, ui.move_sprite, id, offset, duration / 1000)
	end,
	fade_out_sprite = function(id, duration, yield)
		yield_if_should(yield, ui.fade_out_sprite, id, duration / 1000)
	end,
	fade_out_all_sprites = function(duration, yield)
		yield_if_should(yield, ui.fade_out_all_sprites, duration / 1000)
	end,
	draw_character = function(id, name, index, offset, fade_in_time, yield)
		local transition = if fade_in_time then fade_in_time / 1000 else nil
		yield_if_should(yield, ui.draw_sprite, id, load_sprite(name .. index), offset, transition)
	end,
	play_music = function(id, name)
		local track = assets[`music/{string.lower(name)}`] or ""

		if not music[id] then
			local sound = Instance.new("Sound")
			sound.Name = `music_{id}`
			sound.Looped = true
			sound.Parent = SoundService

			music[id] = sound
		end

		local sound = music[id]
		sound.SoundId = track
		sound:Play()
	end,
	stop_music = function(id)
		local sound = music[id]
		if sound then
			music[id] = nil
			sound:Stop()
			sound:Destroy()
		end
	end,
	fade_out_music = function(id, duration, yield)
		local sound = music[id]
		if not sound then
			return
		end
		music[id] = nil

		local tween = TweenService:Create(sound, TweenInfo.new(duration / 1000), { Volume = 0 })
		tween:Play()
		tween.Completed:Once(function()
			sound:Stop()
			sound:Destroy()
		end)

		if yield then
			tween.Completed:Wait()
		end
	end,
	play_sound_effect = function(name)
		local sfx = assets[`sfx/{string.lower(name)}`]
		if sfx then
			local sound = Instance.new("Sound")
			sound.SoundId = sfx
			SoundService:PlayLocalSound(sound)
		end
	end,
	play_movie = function(name)
		local movie = assets[`movies/{string.lower(name)}`]
		if movie then
			ui.play_movie(movie)
		end
	end,
	prompt_selection = function(options)
		local result = ui.prompt_selection(options)
		variables.SelectResult = result
	end,
	wait = function(milliseconds)
		task.wait(milliseconds / 1000)
	end,
	save = function(chapter, stage)
		print("save", chapter, stage)
	end,
	set = function(var, value)
		variables[var] = value
	end,
	get = function(var)
		if var == "LOCALWORK_NO_RESULT" then
			return 1
		end
		if variables[var] == nil then
			variables[var] = 0
		end
		return variables[var]
	end,
	set_global_flag = function(flag, value)
		global_flags[flag] = value
	end,
	get_global_flag = function(flag)
		if global_flags[flag] == nil then
			global_flags[flag] = 0
		end
		return global_flags[flag]
	end,

	noop = function() end,
})
