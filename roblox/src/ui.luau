local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local DIALOG_BOX_TRANSITION = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = "display"
screen_gui.IgnoreGuiInset = true
screen_gui.ResetOnSpawn = false
screen_gui.Parent = Players.LocalPlayer.PlayerGui

local black = Instance.new("Frame")
black.Name = "black"
black.Size = UDim2.fromScale(1, 1)
black.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
black.ZIndex = -5
black.Parent = screen_gui

local background_fallback = Instance.new("ImageLabel")
background_fallback.Name = "background_fallback"
background_fallback.Size = UDim2.fromScale(1, 1)
background_fallback.BackgroundTransparency = 1
background_fallback.ZIndex = -3
background_fallback.Parent = screen_gui

local background = Instance.new("ImageLabel")
background.Name = "background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundTransparency = 1
background.ZIndex = -2
background.Parent = screen_gui

local dialog_box = Instance.new("CanvasGroup")
dialog_box.Name = "dialog_box"
dialog_box.Size = UDim2.new(1, 0, 1, 0)
dialog_box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dialog_box.BackgroundTransparency = 0.15
dialog_box.BorderSizePixel = 0
dialog_box.Parent = screen_gui

local padding = Instance.new("UIPadding")
padding.Name = "padding"
padding.PaddingLeft = UDim.new(0, 30)
padding.PaddingRight = UDim.new(0, 50)
padding.PaddingTop = UDim.new(0, 30)
padding.PaddingBottom = UDim.new(0, 60)
padding.Parent = dialog_box

local gradient = Instance.new("UIGradient")
gradient.Name = "gradient"
gradient.Rotation = 90
-- gradient.Transparency = NumberSequence.new(1)
gradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.65, 1),
	NumberSequenceKeypoint.new(1, 0),
})
gradient.Parent = dialog_box

local list = Instance.new("UIListLayout")
list.Name = "list"
list.Padding = UDim.new(0, 8)
list.VerticalAlignment = Enum.VerticalAlignment.Bottom
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = dialog_box

local speaker = Instance.new("TextLabel")
speaker.Name = "speaker"
speaker.Size = UDim2.fromScale(1, 0)
speaker.AutomaticSize = Enum.AutomaticSize.Y
speaker.BackgroundTransparency = 1
speaker.FontFace = Font.fromName("Ubuntu", Enum.FontWeight.Bold)
speaker.Text = ""
speaker.TextSize = 34
speaker.TextWrapped = true
speaker.TextColor3 = Color3.fromRGB(255, 255, 255)
speaker.TextXAlignment = Enum.TextXAlignment.Left
speaker.TextYAlignment = Enum.TextYAlignment.Bottom
speaker.LayoutOrder = 1
speaker.Parent = dialog_box

local dialog = Instance.new("TextLabel")
dialog.Name = "dialog"
dialog.Size = UDim2.fromScale(1, 0)
dialog.AutomaticSize = Enum.AutomaticSize.Y
dialog.BackgroundTransparency = 1
dialog.FontFace = Font.fromName("Ubuntu")
dialog.Text = ""
dialog.TextSize = 32
dialog.TextWrapped = true
dialog.TextColor3 = Color3.fromRGB(255, 255, 255)
dialog.TextXAlignment = Enum.TextXAlignment.Left
dialog.TextYAlignment = Enum.TextYAlignment.Bottom
dialog.LayoutOrder = 2
dialog.Parent = dialog_box

local arrow = Instance.new("ImageLabel")
arrow.Name = "arrow"
arrow.AnchorPoint = Vector2.new(0, 1)
arrow.Size = UDim2.fromOffset(30, 30)
arrow.BackgroundTransparency = 1
arrow.Image = "rbxassetid://97082881520404"
arrow.Visible = false
arrow.Parent = dialog

local movie = Instance.new("VideoFrame")
movie.Name = "movie"
movie.Size = UDim2.fromScale(1, 1)
movie.BackgroundTransparency = 1
movie.Visible = false
movie.ZIndex = 2
movie.Parent = screen_gui

local did_skip = false
local skip_allowed = true
local sprites = {} :: { [number]: ImageLabel }

ContextActionService:BindAction("Skip", function(_, state)
	if state == Enum.UserInputState.Begin then
		did_skip = true
	end
end, false, Enum.KeyCode.Return)

local function compute_gradient_transparency()
	local speaker_height = if #speaker.ContentText > 0 then speaker.AbsoluteSize.Y else 0
	local dialog_height = if #dialog.ContentText > 0 then dialog.AbsoluteSize.Y else 0

	local height = speaker_height + dialog_height + list.Padding.Offset + padding.PaddingBottom.Offset - 78
	local percentage = height / dialog_box.AbsoluteSize.Y

	gradient.Offset = Vector2.new(0, -percentage)
end
RunService.RenderStepped:Connect(compute_gradient_transparency)

local function get_last_dialog_line_width(): number
	local text_bound_params = Instance.new("GetTextBoundsParams")
	text_bound_params.Width = dialog.AbsoluteSize.X
	text_bound_params.Size = dialog.TextSize
	text_bound_params.Font = dialog.FontFace

	local line_height = TextService:GetTextBoundsAsync(text_bound_params).Y

	local function count_lines(str: string)
		text_bound_params.Text = str
		local size = TextService:GetTextBoundsAsync(text_bound_params)
		return math.ceil(size.Y / line_height)
	end

	local lines_total = count_lines(dialog.Text)
	if lines_total <= 1 then
		return dialog.TextBounds.X
	end

	local words = {}
	for word in dialog.Text:gmatch("%S+") do
		table.insert(words, word)
	end

	local low = 1
	local high = #words
	local last_line_index = 1

	while low <= high do
		local mid = math.floor((low + high) / 2)
		local sub_text = table.concat(words, " ", 1, mid)
		local lines = count_lines(sub_text)

		if lines < lines_total then
			low = mid + 1
		else
			last_line_index = mid
			high = mid - 1
		end
	end

	local last_line = table.concat(words, " ", last_line_index)

	text_bound_params.Text = last_line
	return TextService:GetTextBoundsAsync(text_bound_params).X
end

local function show()
	local tween = TweenService:Create(dialog_box, DIALOG_BOX_TRANSITION, { GroupTransparency = 0 })
	tween:Play()
end

local function hide()
	local tween = TweenService:Create(dialog_box, DIALOG_BOX_TRANSITION, { GroupTransparency = 1 })
	tween:Play()
end

local function append(text: string)
	local previous_length = #dialog.Text
	local new_length = #dialog.Text + #text

	dialog.Text ..= text

	for max_visible_graphemes = previous_length + 1, new_length do
		dialog.MaxVisibleGraphemes = max_visible_graphemes
		task.wait()
	end
end

local function clear()
	dialog.Text = ""
	speaker.Text = ""
end

local function set_speaker(name: string, color: Color3)
	speaker.Text = name
	speaker.TextColor3 = color
end

local function set_background(image: Content)
	background.ImageContent = image
	background.ImageTransparency = 0
end

local function fade_out_background(duration: number)
	local tween = TweenService:Create(background, TweenInfo.new(duration), { ImageTransparency = 1 })
	tween:Play()
	tween.Completed:Wait()
end

local function draw_scene(image: Content, fade_in_time: number)
	for _, sprite in sprites do
		sprite:Destroy()
	end
	table.clear(sprites)

	hide()

	background_fallback.ImageContent = background.ImageContent
	background_fallback.ImageTransparency = 0
	background.ImageTransparency = 1
	background.ImageContent = image

	local tween = TweenService:Create(background, TweenInfo.new(fade_in_time), { ImageTransparency = 0 })
	tween:Play()
	tween.Completed:Wait()
end

local function draw_sprite(id: number, image: Content, offset: vector, fade_in_time: number?)
	local position = UDim2.new(0.5, offset.x * 1.75, 0.5, offset.y * 1.75)

	if not sprites[id] then
		local sprite = Instance.new("ImageLabel")
		sprite.Name = `sprite_{id}`
		sprite.AnchorPoint = Vector2.new(0.5, 0.5)
		sprite.Size = UDim2.fromScale(1, 1)
		sprite.Position = position
		sprite.BackgroundTransparency = 1
		sprite.ZIndex = -1
		sprite.ImageContent = image
		sprite.ImageTransparency = 1
		sprite.Parent = screen_gui

		sprites[id] = sprite
	end

	local sprite = sprites[id]
	sprite.ImageContent = image
	sprite.Position = position

	if not fade_in_time then
		sprite.ImageTransparency = 0
	else
		local tween = TweenService:Create(sprite, TweenInfo.new(fade_in_time), { ImageTransparency = 0 })
		tween:Play()
		tween.Completed:Wait()
	end
end

local function move_sprite(id: number, offset: vector, duration: number)
	local sprite = sprites[id]
	if not sprite then
		return
	end

	local position = UDim2.new(0.5, offset.x * 1.75, 0.5, offset.y * 1.75)
	local tween = TweenService:Create(sprite, TweenInfo.new(duration), { Position = position })
	tween:Play()
	tween.Completed:Wait()
end

local function fade_out_sprite(id: number, duration: number)
	local sprite = sprites[id]
	if not sprite then
		return
	end

	local tween = TweenService:Create(sprite, TweenInfo.new(duration), { ImageTransparency = 1 })
	tween:Play()
	tween.Completed:Wait()

	sprites[id] = nil
	sprite:Destroy()
end

local function fade_out_all_sprites(duration: number)
	local remaining = 0
	for _ in sprites do
		remaining += 1
	end

	for id, sprite in sprites do
		local tween = TweenService:Create(sprite, TweenInfo.new(duration), { ImageTransparency = 1 })
		tween:Play()
		tween.Completed:Once(function()
			sprites[id] = nil
			sprite:Destroy()
			remaining -= 1
		end)
	end

	while remaining > 0 do
		task.wait()
	end
end

local function play_movie(video: string)
	movie.Video = video
	movie.Visible = true
	movie:Play()
	movie.Ended:Wait()
	movie.Visible = false
end

local function prompt_selection(options: { string }): number
	local thread = coroutine.running()

	local container = Instance.new("Frame")
	container.Name = "select"
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = screen_gui

	local list = Instance.new("UIListLayout")
	list.Name = "list"
	list.Padding = UDim.new(0, 24)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = container

	for index, option in options do
		local button = Instance.new("TextButton")
		button.Name = option
		button.AutomaticSize = Enum.AutomaticSize.XY
		button.BackgroundTransparency = 1
		button.FontFace = Font.fromName("Ubuntu")
		button.Text = option
		button.TextSize = 60
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.LayoutOrder = index

		button:GetPropertyChangedSignal("GuiState"):Connect(function()
			local gui_state = button.GuiState
			button.TextColor3 = if gui_state == Enum.GuiState.Hover
				then Color3.fromRGB(255, 0, 0)
				else Color3.fromRGB(255, 255, 255)
		end)

		button.MouseButton1Click:Connect(function()
			task.spawn(thread, index)
		end)

		button.Parent = container
	end

	local result = coroutine.yield()
	container:Destroy()
	return result
end

local function just_skipped()
	local previous_did_skip = did_skip
	did_skip = false
	return previous_did_skip
end

local function sink_skip()
	did_skip = false
end

local function wait_until_skipped()
	sink_skip()

	local width = get_last_dialog_line_width()
	arrow.Position = UDim2.new(0, width + 12, 1, 0)
	arrow.Visible = true

	while not just_skipped() or not skip_allowed do
		task.wait()
	end

	arrow.Visible = false
end

local function set_skip_allowed(allowed: boolean)
	skip_allowed = allowed
end

return {
	show = show,
	hide = hide,
	append = append,
	clear = clear,
	set_speaker = set_speaker,
	set_background = set_background,
	fade_out_background = fade_out_background,
	draw_scene = draw_scene,
	draw_sprite = draw_sprite,
	move_sprite = move_sprite,
	fade_out_sprite = fade_out_sprite,
	fade_out_all_sprites = fade_out_all_sprites,
	play_movie = play_movie,
	prompt_selection = prompt_selection,
	just_skipped = just_skipped,
	sink_skip = sink_skip,
	wait_until_skipped = wait_until_skipped,
	set_skip_allowed = set_skip_allowed,
}
