local GeminiHub = (getgenv and (getgenv().BistsHub or getgenv().GeminiHub)) or _G.BistsHub or _G.GeminiHub

return function(Window)
	local function CloneReference(Object)
		if GeminiHub and GeminiHub.Environment and GeminiHub.Environment.cloneref then
			return GeminiHub.Environment.cloneref(Object)
		else
			return Object
		end
	end
	
	local Services = setmetatable({}, {
		__index = function(self, Name)
			return CloneReference(game:GetService(Name))
		end
	})

	local Library = GeminiHub.Interface.Library
	local SaveManager = GeminiHub.Interface.SaveManager
	local ThemeManager = GeminiHub.Interface.ThemeManager
	local Options = Library.Options or (getgenv and getgenv().Options) or {}
	local Toggles = Library.Toggles or (getgenv and getgenv().Toggles) or {}
	
	local SettingsTab = Window:AddTab("Settings", "settings")
	local MenuGroup = SettingsTab:AddLeftGroupbox("Menu")
	
	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = Library.KeybindFrame.Visible,
		Text = "Open Keybind Menu",
		Callback = function(value)
			Library.KeybindFrame.Visible = value
		end,
	})
	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = "Custom Cursor",
		Default = false,
		Callback = function(Value)
			Library.ShowCustomCursor = Value
		end,
	})

	MenuGroup:AddDropdown("UILibrary", {
		Text = "UI Style",
		Values = {
			"Obsidian",
			"Linoria"
		},
		Default = (GeminiHub.UILibrary == "Linoria" and 2 or 1),
		Callback = function(Value)
			if GeminiHub.Environment.writefile and GeminiHub.Environment.readfile then
				if not GeminiHub.Environment.isfile("GeminiHub/UserData.json") then
					local Data = {
						TotalExecutions = 0,
						UILibrary = "Obsidian"
					}
					GeminiHub.Environment.writefile("GeminiHub/UserData.json", Services.HttpService:JSONEncode(Data))
				end

				local UserData = GeminiHub.Environment.readfile("GeminiHub/UserData.json")
				local Decoded = Services.HttpService:JSONDecode(UserData)
				Decoded.UILibrary = Value

				GeminiHub.UILibrary = Value
				GeminiHub.Environment.writefile("GeminiHub/UserData.json", Services.HttpService:JSONEncode(Decoded))
			end
		end
	})

	local MenuKeybind = MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
		Default = "RightShift",
		NoUI = true,
		Text = "Menu Keybind"
	})

	Library.ToggleKeybind = MenuKeybind or (Options and Options.MenuKeybind)

	Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
		local focused = Services.UserInputService:GetFocusedTextBox()
		if focused then return end

		local currentBind = Options.MenuKeybind and Options.MenuKeybind.Value
		local matches = false
		if typeof(currentBind) == "string" and currentBind ~= "" then
			if input.KeyCode.Name == currentBind then
				matches = true
			end
		elseif typeof(currentBind) == "EnumItem" then
			if input.KeyCode == currentBind then
				matches = true
			end
		end

		if matches or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
			if Library.Toggle then
				Library:Toggle()
			end
		end
	end)

	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)

	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

	ThemeManager:SetFolder("GeminiHub")
	ThemeManager:ApplyToTab(SettingsTab)

	SaveManager:LoadAutoloadConfig()
end
