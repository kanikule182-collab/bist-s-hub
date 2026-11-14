local Library = {
	Font = Enum.Font.RobotoCondensed,
	Rainbow = false,
	Tracers = false,
	Unloaded = false,
	ShowDistance = false,
	MatchColors = true,
	Arrows = false,
	TextTransparency = 0,
	TracerOrigin = "Bottom",
	FillTransparency = 0.75,
	OutlineTransparency = 0,
	TextOutlineTransparency = 0,
	FadeTime = 0,
	RenderLimit = 240,
	TracerSize = 0.5,
	ArrowRadius = 200,
	TextSize = 20,
	DistanceSizeRatio = 1,
	OutlineColor = Color3.fromRGB(255, 255, 255),
	RainbowColor = Color3.fromRGB(255, 255, 255),

	ElementsEnabled = {},
	TransparencyEnabled = {},
	Highlights = {},
	Labels = {},
	Frames = {},
	Lines = {},
	ArrowsTable = {},
	ColorTable = {},
	TextTable = {},
	ConnectionsTable = {},
	Objects = {},
	TotalObjects = {},
}

local RainbowState = {
	HueSetup = 0,
	Hue = 0,
	Step = 0,
	Color = Color3.new(),
}

local CloneReference = cloneref or function(O) return O end
local Players = CloneReference(game:GetService("Players"))
local CoreGui = getgenv and CloneReference(game:GetService("CoreGui")) or Players.LocalPlayer.PlayerGui
local Workspace = CloneReference(workspace)
local RunService = CloneReference(game:GetService("RunService"))
local TweenService = CloneReference(game:GetService("TweenService"))
local UserInputService = CloneReference(game:GetService("UserInputService"))
local LocalPlayer = Players.LocalPlayer

function Library:GenerateRandomString()
	local Chars = {}
	local Pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local PoolLen = #Pool
	for I = 1, 24 do
		local Idx = math.random(1, PoolLen)
		Chars[I] = Pool:sub(Idx, Idx)
	end
	return table.concat(Chars)
end

local function GetHiddenUI()
	if gethui then
		local hui = gethui()
		if hui then return hui end
	end
	local Folder = Instance.new("Folder", CoreGui)
	Folder.Name = Library:GenerateRandomString()
	return Folder
end

local HiddenUI = GetHiddenUI()

-- Avoid nesting ScreenGui inside an existing ScreenGui/LayerCollector
local RootGui
if HiddenUI:IsA("LayerCollector") then
	RootGui = HiddenUI
else
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Name = Library:GenerateRandomString()
	ScreenGui.Parent = HiddenUI
	RootGui = ScreenGui
end

local HighlightsFolder = Instance.new("Folder")
HighlightsFolder.Name = Library:GenerateRandomString()
HighlightsFolder.Parent = RootGui

local BillboardsFolder = Instance.new("Folder")
BillboardsFolder.Name = Library:GenerateRandomString()
BillboardsFolder.Parent = RootGui

local TracersFrame = Instance.new("Frame")
TracersFrame.Size = UDim2.new(1, 0, 1, 0)
TracersFrame.BackgroundTransparency = 1
TracersFrame.Visible = false
TracersFrame.Name = Library:GenerateRandomString()
TracersFrame.Parent = RootGui

local ArrowsFrame = Instance.new("Frame")
ArrowsFrame.Size = UDim2.new(1, 0, 1, 0)
ArrowsFrame.BackgroundTransparency = 1
ArrowsFrame.Visible = false
ArrowsFrame.Name = Library:GenerateRandomString()
ArrowsFrame.Parent = RootGui

local ArrowTemplate = Instance.new("ImageLabel")
ArrowTemplate.Image = "rbxassetid://16368985219"
ArrowTemplate.Size = UDim2.new(0, 42, 0, 42)
ArrowTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowTemplate.BackgroundTransparency = 1
ArrowTemplate.ImageTransparency = 1
local ArrowConstraint = Instance.new("UIAspectRatioConstraint")
ArrowConstraint.AspectRatio = 1
ArrowConstraint.Name = Library:GenerateRandomString()
ArrowConstraint.Parent = ArrowTemplate

local function MakeTween(Instance_, Props)
	local Info = TweenInfo.new(Library.FadeTime or 0, Enum.EasingStyle.Quad)
	return TweenService:Create(Instance_, Info, Props)
end

local function PlayTween(Instance_, Props)
	if Library.FadeTime and Library.FadeTime > 0 then
		MakeTween(Instance_, Props):Play()
	else
		for prop, val in pairs(Props) do
			pcall(function() Instance_[prop] = val end)
		end
	end
end

local function DestroyObjectData(Object)
	local Highlight = Library.Highlights[Object]
	if Highlight then
		Highlight:Destroy()
		Library.Highlights[Object] = nil
	end

	local Frame = Library.Frames[Object]
	if Frame then
		Frame:Destroy()
		Library.Frames[Object] = nil
	end

	local LineData = Library.Lines[Object]
	if LineData then
		if LineData[1] then LineData[1]:Destroy() end
		Library.Lines[Object] = nil
	end

	local Arrow = Library.ArrowsTable[Object]
	if Arrow then
		Arrow:Destroy()
		Library.ArrowsTable[Object] = nil
	end

	local Conns = Library.ConnectionsTable[Object]
	if Conns then
		for _, Conn in ipairs(Conns) do
			Conn:Disconnect()
		end
		Library.ConnectionsTable[Object] = nil
	end

	Library.Labels[Object] = nil
	Library.ColorTable[Object] = nil
	Library.TextTable[Object] = nil
	Library.ElementsEnabled[Object] = nil
	Library.TransparencyEnabled[Object] = nil
	Library.Objects[Object] = nil

	for Idx = #Library.TotalObjects, 1, -1 do
		if Library.TotalObjects[Idx] == Object then
			table.remove(Library.TotalObjects, Idx)
			break
		end
	end
end

function Library:AddESP(Parameters)
	local Object = Parameters.Object
	if not Object or Library.Unloaded == true then return end
	if not Object:IsA("BasePart") and not Object:IsA("Model") then return end

	-- If already registered, simply update color, text, and re-enable
	if Library.ElementsEnabled[Object] == true then
		if Parameters.Text then
			Library:UpdateObjectText(Object, Parameters.Text)
		end
		if Parameters.Color then
			Library:UpdateObjectColor(Object, Parameters.Color)
		end
		return
	end

	Library.ElementsEnabled[Object] = true
	Library.TransparencyEnabled[Object] = true
	Library.ConnectionsTable[Object] = Library.ConnectionsTable[Object] or {}

	-- Create Highlight ONCE (never destroy and re-create in render loop)
	if Library.Highlights[Object] then
		Library.Highlights[Object]:Destroy()
		Library.Highlights[Object] = nil
	end

	local Highlight = Instance.new("Highlight")
	Highlight.FillTransparency = Library.FillTransparency
	Highlight.OutlineTransparency = Library.OutlineTransparency
	Highlight.Name = Library:GenerateRandomString()
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.FillColor = Parameters.Color or Color3.fromRGB(255, 255, 255)
	Highlight.OutlineColor = Library.MatchColors and (Parameters.Color or Color3.fromRGB(255, 255, 255)) or Library.OutlineColor
	Highlight.Adornee = Object
	Highlight.Parent = HighlightsFolder
	Library.Highlights[Object] = Highlight

	-- 2D Billboard Text Frame (exact offset sizing to center over 3D point)
	local TextFrame = Instance.new("Frame")
	TextFrame.Visible = false
	TextFrame.Name = Library:GenerateRandomString()
	TextFrame.Size = UDim2.new(0, 200, 0, 40)
	TextFrame.BackgroundTransparency = 1
	TextFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	TextFrame.Parent = BillboardsFolder

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Name = Library:GenerateRandomString()
	TextLabel.BackgroundTransparency = 1
	TextLabel.Text = Parameters.Text or ""
	TextLabel.TextTransparency = Library.TextTransparency
	TextLabel.TextStrokeTransparency = Library.TextOutlineTransparency
	TextLabel.Size = UDim2.new(1, 0, 1, 0)
	TextLabel.Font = Library.Font
	TextLabel.TextSize = Library.TextSize
	TextLabel.TextXAlignment = Enum.TextXAlignment.Center
	TextLabel.TextYAlignment = Enum.TextYAlignment.Center
	TextLabel.RichText = true
	TextLabel.TextColor3 = Parameters.Color or Color3.fromRGB(255, 255, 255)
	TextLabel.Parent = TextFrame

	Library.Frames[Object] = TextFrame
	Library.Labels[Object] = TextLabel
	Library.ColorTable[Object] = Parameters.Color or Color3.fromRGB(255, 255, 255)
	Library.TextTable[Object] = Parameters.Text or ""
	Library.Objects[Object] = Object

	if not table.find(Library.TotalObjects, Object) then
		table.insert(Library.TotalObjects, Object)
	end

	-- Tracer Line Frame
	local LineFrame = Instance.new("Frame")
	LineFrame.Size = UDim2.new(0, 0, 0, 1)
	LineFrame.BackgroundTransparency = 0
	LineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	LineFrame.BorderSizePixel = 0
	LineFrame.Visible = false
	LineFrame.Name = Library:GenerateRandomString()
	LineFrame.Parent = TracersFrame

	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = Library.TracerSize
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Transparency = 0
	Stroke.Name = Library:GenerateRandomString()
	Stroke.Parent = LineFrame

	Library.Lines[Object] = { LineFrame, Stroke }
end

function Library:RemoveESP(Object)
	if Library.Unloaded == true or not Object then return end
	if Library.ElementsEnabled[Object] ~= true then return end
	Library.ElementsEnabled[Object] = false

	local FadeTime = Library.FadeTime or 0
	if FadeTime > 0 then
		local Label = Library.Labels[Object]
		if Label then
			PlayTween(Label, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end

		local LineData = Library.Lines[Object]
		if LineData then
			if LineData[1] then PlayTween(LineData[1], { BackgroundTransparency = 1 }) end
			if LineData[2] then PlayTween(LineData[2], { Transparency = 1 }) end
		end

		local Highlight = Library.Highlights[Object]
		if Highlight then
			PlayTween(Highlight, { FillTransparency = 1, OutlineTransparency = 1 })
		end

		local Arrow = Library.ArrowsTable[Object]
		if Arrow then
			PlayTween(Arrow, { ImageTransparency = 1 })
		end

		task.delay(FadeTime + 0.05, function()
			if Library.ElementsEnabled[Object] == false then
				DestroyObjectData(Object)
			end
		end)
	else
		DestroyObjectData(Object)
	end
end

function Library:UpdateObjectText(Object, Text)
	if Library.TextTable[Object] ~= nil then
		Library.TextTable[Object] = Text
		if Library.Labels[Object] then
			Library.Labels[Object].Text = Text
		end
	end
end

function Library:UpdateObjectColor(Object, Color)
	Library.ColorTable[Object] = Color
	if Library.Labels[Object] and Library.Rainbow ~= true then
		Library.Labels[Object].TextColor3 = Color
	end
	if Library.Highlights[Object] and Library.Highlights[Object]:IsA("Highlight") and Library.Rainbow ~= true then
		Library.Highlights[Object].FillColor = Color
		if Library.MatchColors then
			Library.Highlights[Object].OutlineColor = Color
		end
	end
end

function Library:SetColorTable(Name, Color)
	Library.ColorTable[Name] = Color
end

function Library:SetFadeTime(Number)
	Library.FadeTime = Number
end

function Library:SetRenderLimit(Number)
	Library.RenderLimit = Number
end

function Library:SetTextTransparency(Number)
	Library.TextTransparency = Number
	for _, Label in pairs(Library.Labels) do
		Label.TextTransparency = Number
	end
end

function Library:SetFillTransparency(Number)
	Library.FillTransparency = Number
	for _, Highlight in pairs(Library.Highlights) do
		if Highlight:IsA("Highlight") then
			Highlight.FillTransparency = Number
		end
	end
end

function Library:SetOutlineTransparency(Number)
	Library.OutlineTransparency = Number
	for _, Highlight in pairs(Library.Highlights) do
		if Highlight:IsA("Highlight") then
			Highlight.OutlineTransparency = Number
		end
	end
end

function Library:SetTextSize(Number)
	Library.TextSize = Number
	for _, Label in pairs(Library.Labels) do
		Label.TextSize = Number
	end
end

function Library:SetTextOutlineTransparency(Number)
	Library.TextOutlineTransparency = Number
	for _, Label in pairs(Library.Labels) do
		Label.TextStrokeTransparency = Number
	end
end

function Library:SetFont(Font)
	Library.Font = Font
	for _, Label in pairs(Library.Labels) do
		Label.Font = Font
	end
end

function Library:SetOutlineColor(Color)
	Library.OutlineColor = Color
	for _, Highlight in pairs(Library.Highlights) do
		if Highlight:IsA("Highlight") and not Library.MatchColors then
			Highlight.OutlineColor = Color
		end
	end
end

function Library:SetRainbow(Value)
	Library.Rainbow = Value
end

function Library:SetShowDistance(Value)
	Library.ShowDistance = Value
end

function Library:SetMatchColors(Value)
	Library.MatchColors = Value
end

function Library:SetTracers(Value)
	Library.Tracers = Value
	TracersFrame.Visible = Value
end

function Library:SetArrows(Value)
	Library.Arrows = Value
	ArrowsFrame.Visible = Value
end

function Library:SetArrowRadius(Value)
	Library.ArrowRadius = Value
end

function Library:SetTracerOrigin(Value)
	Library.TracerOrigin = Value
end

function Library:SetDistanceSizeRatio(Value)
	Library.DistanceSizeRatio = Value
end

function Library:SetTracerSize(Value)
	Library.TracerSize = 0.5 * Value
	for _, LineData in pairs(Library.Lines) do
		if LineData and LineData[2] then
			LineData[2].Thickness = Library.TracerSize
		end
	end
end

-- High-performance Centralized Render Loop (single connection, no frame drops, no memory leaks)
local LastRender = 0
local RenderConnection
local RainbowConnection

RenderConnection = RunService.RenderStepped:Connect(function(Delta)
	if Library.Unloaded then return end

	LastRender = LastRender + Delta
	local MinInterval = 1 / math.max(Library.RenderLimit or 60, 30)
	if LastRender < MinInterval then return end
	LastRender = 0

	local Camera = Workspace.CurrentCamera or workspace.CurrentCamera
	if not Camera then return end

	local ScreenSize = Camera.ViewportSize
	local ScreenCenter = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)
	local CamPos = Camera.CFrame.Position
	local CamCF = Camera.CFrame

	for i = #Library.TotalObjects, 1, -1 do
		local Object = Library.TotalObjects[i]
		if not Object or not Object.Parent then
			Library:RemoveESP(Object)
		elseif Library.ElementsEnabled[Object] == true then
			local ObjectPos = Object:GetPivot().Position
			local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(ObjectPos)
			local IsVisibleOnScreen = OnScreen and ScreenPoint.Z > 0

			local Frame = Library.Frames[Object]
			local Label = Library.Labels[Object]
			local CachedHighlight = Library.Highlights[Object]
			local LineData = Library.Lines[Object]
			local ActiveColor = Library.Rainbow and RainbowState.Color or (Library.ColorTable[Object] or Color3.fromRGB(255, 255, 255))

			-- Only update highlight color dynamically if Rainbow mode is active (avoids dirtying mesh buffers every frame)
			if Library.Rainbow and CachedHighlight and CachedHighlight.Parent then
				CachedHighlight.FillColor = ActiveColor
				if Library.MatchColors then
					CachedHighlight.OutlineColor = ActiveColor
				end
			end

			-- Update 2D Billboard Label (properly positioned and centered)
			if Frame and Label then
				Frame.Visible = IsVisibleOnScreen
				if IsVisibleOnScreen then
					Frame.Position = UDim2.new(0, ScreenPoint.X, 0, ScreenPoint.Y)
					if Library.ShowDistance then
						local Distance = math.floor((CamPos - ObjectPos).Magnitude)
						Label.Text = (Library.TextTable[Object] or "") .. "\n" .. '<font size="' .. math.round(Library.TextSize * Library.DistanceSizeRatio) .. '">[' .. Distance .. ']</font>'
					end
				end
			end

			-- Update Tracers (strictly when in front of camera)
			if LineData and LineData[1] then
				if Library.Tracers and IsVisibleOnScreen then
					local Origin
					if Library.TracerOrigin == "Center" then
						Origin = ScreenCenter
					elseif Library.TracerOrigin == "Top" then
						Origin = Vector2.new(ScreenSize.X / 2, 0)
					elseif Library.TracerOrigin == "Mouse" then
						local MouseLoc = UserInputService:GetMouseLocation()
						Origin = Vector2.new(MouseLoc.X, MouseLoc.Y)
					else
						Origin = Vector2.new(ScreenSize.X / 2, ScreenSize.Y)
					end

					local Destination = Vector2.new(ScreenPoint.X, ScreenPoint.Y)
					local MidPoint = (Origin + Destination) / 2
					local Rotation = math.deg(math.atan2(Destination.Y - Origin.Y, Destination.X - Origin.X))
					local Length = (Origin - Destination).Magnitude

					local LF = LineData[1]
					local SK = LineData[2]
					LF.Position = UDim2.new(0, MidPoint.X, 0, MidPoint.Y)
					LF.Size = UDim2.new(0, Length, 0, 1)
					LF.Rotation = Rotation
					LF.BackgroundColor3 = ActiveColor
					LF.Visible = true

					if SK then
						SK.Color = ActiveColor
						SK.Thickness = Library.TracerSize
					end
				else
					LineData[1].Visible = false
				end
			end

			-- Update Off-Screen Arrows (pointing accurately toward off-screen objects)
			if Library.Arrows then
				local Arrow = Library.ArrowsTable[Object]
				if not Arrow then
					Arrow = ArrowTemplate:Clone()
					Arrow.Name = Library:GenerateRandomString()
					Arrow.Parent = ArrowsFrame
					Library.ArrowsTable[Object] = Arrow
					PlayTween(Arrow, { ImageTransparency = 0 })
				end

				if IsVisibleOnScreen then
					Arrow.Visible = false
				else
					local RelPos = CamCF:PointToObjectSpace(ObjectPos)
					local Dir = Vector2.new(RelPos.X, -RelPos.Y)
					if Dir.Magnitude < 0.001 then Dir = Vector2.new(0, -1) end
					local Angle = math.atan2(Dir.Y, Dir.X)
					local Radius = math.min(ScreenSize.X, ScreenSize.Y) / 2 - math.clamp(400 - Library.ArrowRadius, 20, 300)
					local ArrowPos = ScreenCenter + Dir.Unit * Radius

					Arrow.Position = UDim2.new(0, ArrowPos.X, 0, ArrowPos.Y)
					Arrow.Rotation = math.deg(Angle) + 90
					Arrow.ImageColor3 = ActiveColor
					Arrow.Visible = true
				end
			elseif Library.ArrowsTable[Object] then
				Library.ArrowsTable[Object].Visible = false
			end
		end
	end
end)

RainbowConnection = RunService.RenderStepped:Connect(function(Delta)
	RainbowState.Step = RainbowState.Step + Delta
	if RainbowState.Step >= (1 / 60) then
		RainbowState.Step = 0
		RainbowState.HueSetup = RainbowState.HueSetup + (1 / 400)
		if RainbowState.HueSetup > 1 then RainbowState.HueSetup = 0 end
		RainbowState.Hue = RainbowState.HueSetup
		RainbowState.Color = Color3.fromHSV(RainbowState.Hue, 0.8, 1)
		Library.RainbowColor = RainbowState.Color
	end
end)

function Library:Unload()
	if Library.Unloaded then return end
	Library.Unloaded = true

	if RenderConnection then
		RenderConnection:Disconnect()
		RenderConnection = nil
	end
	if RainbowConnection then
		RainbowConnection:Disconnect()
		RainbowConnection = nil
	end

	for _, Object in pairs(Library.Objects) do
		Library:RemoveESP(Object)
	end
	for _, Conns in pairs(Library.ConnectionsTable) do
		for _, Conn in ipairs(Conns) do
			Conn:Disconnect()
		end
	end

	if RootGui and not RootGui:IsA("LayerCollector") then
		RootGui:Destroy()
	else
		HighlightsFolder:Destroy()
		BillboardsFolder:Destroy()
		TracersFrame:Destroy()
		ArrowsFrame:Destroy()
	end
end

if getgenv then
	getgenv().ESPLibrary = Library
end

return Library
