local LibraryChoice = (GeminiHub and GeminiHub.UILibrary == "Linoria" and "LinoriaLib" or "Obsidian")
local BaseUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

local Interface = {
    Library = loadstring(game:HttpGet(BaseUrl .. "Library.lua"))(),
    SaveManager = loadstring(game:HttpGet(BaseUrl .. "addons/SaveManager.lua"))(),
    ThemeManager = loadstring(game:HttpGet(BaseUrl .. "addons/ThemeManager.lua"))(),

    ApplyInfoTab = GeminiHub.LoadModule("Components/InfoTab.luau"),
    ApplySettingsTab = GeminiHub.LoadModule("Components/SettingsTab.luau")
}

Interface.ThemeManager.BuiltInThemes = {
    ["Default"]        = { 1,  { FontColor = "ffffff", MainColor = "1c1c1c", AccentColor = "00a6ff", BackgroundColor = "141414", OutlineColor = "323232" } },
    ["Gemini Neon"]    = { 2,  { FontColor = "ffffff", MainColor = "181a20", AccentColor = "1e88e5", BackgroundColor = "101216", OutlineColor = "2d3342" } },
    ["BBot"]           = { 3,  { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" } },
    ["Fatality"]       = { 4,  { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" } },
    ["Tokyo Night"]    = { 5,  { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" } },
    ["Nord"]           = { 6,  { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a" } },
    ["Dracula"]        = { 7,  { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4" } },
    ["Cyberpunk"]      = { 8,  { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e" } },
}

return Interface
