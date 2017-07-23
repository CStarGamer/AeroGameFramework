-- Fade
-- Crazyman32
-- February 4, 2017

--[[
	
	
	METHODS:
	
		Fade:In([duration [, async] ])                  Fade in from black
		Fade:Out([duration [, async] ])                 Fade out to black
		
		Fade:To(transparency [, duration [, async] ])   Fade to the given transparency level
		Fade:FromTo(from, to [, duration [, async] ])   Fade from one transparency level to another
		
		Fade:SetText(text)                              Set text to show on fade screen
		Fade:ClearText()                                Sets text to a blank string
		Fade:SetFont(font)                              Sets the font
		
		Fade:SetBackgroundColor(color)                  Set the fade color (can be a Color3 or BrickColor)
		Fade:SetTextColor(color)                        Set the text color (can be a Color3 or BrickColor)
		
		Fade:SetEasingStyle(easingStyle)                Set the easing style (e.g. Enum.EasingStyle.Quad)
		
		Fade:GetScreenGui()                             Returns the ScreenGui for this fade system
		Fade:GetFrame()                                 Returns the overlay Frame
		Fade:GetLabel()                                 Returns the TextLabel used for showing text
	
	
	EVENTS:
		
		Fade.Started()
		Fade.Ended()
	
	
	
	EXAMPLES:
		
		-- Hello fade:
		Fade:SetText("Hello")
		Fade:Out()
		wait(1)
		Fade:In()
		
		-- Slow fade:
		Fade:ClearText()
		Fade:Out(5)
		wait(1)
		Fade:In(5)
		
		-- Half fade:
		Fade:To(0.5)
		
		-- Asynchronous w/ events:
		Fade.Ended:connect(function()
			print("Fade ended!")
		end)
		Fade:Out(1, true)
	
	
	
	
	Note: This module is dependent on the Tween module.
	
--]]



local Fade = {}


local DEFAULT_DURATION = 0.5
local DEFAULT_ASYNC    = false


-- ScreenGui:
local fadeGui = Instance.new("ScreenGui")
	fadeGui.Name = "FadeGui"
	fadeGui.DisplayOrder = 9

-- Main overlay frame:
local fade = Instance.new("Frame", fadeGui)
	fade.Name = "Fade"
	fade.Size = UDim2.new(1, 500, 1, 500)
	fade.Position = UDim2.new(0, -250, 0, -250)
	fade.BorderSizePixel = 0
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.BackgroundTransparency = 1

-- Text label:
local label = Instance.new("TextLabel", fade)
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSans
	label.TextScaled = true
	label.TextWrapped = true
	label.Size = UDim2.new(1, -500, 1, -500)
	label.Position = UDim2.new(0, 250, 0, 250)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = ""


local easingStyle = Enum.EasingStyle.Quad

local Tween
local currentTween

--local fadeStarted
--local fadeEnded

local fadeStartedEvent = "Started"
local fadeEndedEvent = "Ended"


-- Set background color:
function Fade:SetBackgroundColor(c)
	local t = typeof(c)
	if (t == "Color3") then
		fade.BackgroundColor3 = c
	elseif (t == "BrickColor") then
		fade.BackgroundColor3 = c.Color
	else
		error("Argument must be of type Color3 or BrickColor")
	end
end


-- Set text color:
function Fade:SetTextColor(c)
	local t = typeof(c)
	if (t == "Color3") then
		label.TextColor3 = c
	elseif (t == "BrickColor") then
		label.TextColor3 = c.Color
	else
		error("Argument must be of type Color3 or BrickColor")
	end
end


-- Set text:
function Fade:SetText(text)
	label.Text = (text == nil and "" or tostring(text))
end


-- Clear text:
function Fade:ClearText()
	self:SetText(nil)
end


-- Fade in (fade the transparency frame out of the picture)
function Fade:In(duration, async)
	self:FromTo(0, 1, duration, async)
end


--  Fade out (fade the transparency frame into picture)
function Fade:Out(duration, async)
	self:FromTo(1, 0, duration, async)
end


-- Fade to a transparency, starting at whatever transparency level it is currently:
function Fade:To(transparency, duration, async)
	self:FromTo(fade.BackgroundTransparency, transparency, duration, async)
end


-- Fade from a transparency to another:
function Fade:FromTo(fromTransparency, toTransparency, duration, async)
	
	assert(type(fromTransparency) == "number", "'fromTransparency' argument must be a number")
	assert(type(toTransparency) == "number", "'toTransparency' argument must be a number")
	assert(duration == nil or type(duration) == "number", "'duration' argument must be a number or nil")
	
	duration = (duration or DEFAULT_DURATION)
	
	if (duration <= 0) then
		-- Instant fade; skip everything else:
		self:FireEvent(fadeStartedEvent)
		fade.BackgroundTransparency = toTransparency
		label.TextTransparency = toTransparency
		self:FireEvent(fadeEndedEvent)
		return
	end
	
	if (async == nil) then
		async = DEFAULT_ASYNC
	end
	
	-- If already fading, stop fading so we can prioritize this new fade:
	if (currentTween) then
		currentTween:Cancel()
		currentTween = nil
	end
	
	-- Fire Started event:
	self:FireEvent(fadeStartedEvent)
	
	local deltaTransparency = (toTransparency - fromTransparency)
	
	-- Fade operation:
	local tweenInfo = TweenInfo.new(
		(duration or DEFAULT_DURATION),
		easingStyle,
		(fromTransparency > toTransparency and Enum.EasingDirection.In or Enum.EasingDirection.Out)
	)
	currentTween = Tween.new(tweenInfo, function(ratio)
		local transparency = (fromTransparency + (deltaTransparency * ratio))
		fade.BackgroundTransparency = transparency
		label.TextTransparency = transparency
	end)
	
	-- Start fading:
	currentTween:Play()
	
	-- Await fade to end, then fire Ended event:
	local function AwaitEnd()
		currentTween.Completed:Wait()
		self:FireEvent(fadeEndedEvent)
	end
	
	if (async) then
		coroutine.resume(coroutine.create(AwaitEnd))
	else
		AwaitEnd()
	end
	
end


function Fade:SetEasingStyle(style)
	assert(typeof(style) == "EnumItem", "Argument must be of type EnumItem")
	easingStyle = style
end


function Fade:GetScreenGui()
	return fadeGui
end


function Fade:GetFrame()
	return fade
end


function Fade:GetLabel()
	return label
end


function Fade:Start()
	fadeGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end


function Fade:Init()
	Tween = self.Modules.Tween
	self:RegisterEvent(fadeStartedEvent)
	self:RegisterEvent(fadeEndedEvent)
end


return Fade