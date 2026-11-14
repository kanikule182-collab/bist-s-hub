if getgenv and (getgenv().BistsHub or getgenv().GeminiHub or getgenv().DoorsMainUnload) then
    local old = getgenv().BistsHub or getgenv().GeminiHub
    if old then
        if old.Unload then
            pcall(function() old:Unload() end)
        elseif old.Interface and old.Interface.Library then
            pcall(function() old.Interface.Library:Unload() end)
        end
        if old.ESPLibrary then
            pcall(function() old.ESPLibrary:Unload() end)
        end
    end
    if getgenv().DoorsMainUnload then
        pcall(getgenv().DoorsMainUnload)
        getgenv().DoorsMainUnload = nil
    end
    getgenv().BistsHub = nil
    getgenv().GeminiHub = nil
    getgenv().Abysall = nil
    task.wait(0.15)
end

local BistsHub = {
    Legit = true,
    Name = "Bist's Hub",
    Version = "1.0.0",
}
local GeminiHub = BistsHub

function BistsHub:Unload()
    if self.Unloaded then return end
    self.Unloaded = true

    if self.DoorsUnload then
        pcall(self.DoorsUnload)
        self.DoorsUnload = nil
    end

    if self.Interface and self.Interface.Library then
        pcall(function() self.Interface.Library:Unload() end)
    end

    if self.ESPLibrary then
        pcall(function() self.ESPLibrary:Unload() end)
    end

    pcall(function()
        local gethui = gethui or function() return game:GetService("CoreGui") end
        local h = gethui()
        if h then
            for _, child in ipairs(h:GetChildren()) do
                if child.Name:find("BistsHub") or child.Name:find("GeminiHub") or child.Name == "BistsHub_FloatToggle" then
                    child:Destroy()
                end
            end
        end
    end)
end

if getgenv then
    getgenv().BistsHub = BistsHub
    getgenv().GeminiHub = BistsHub
    getgenv().Abysall = BistsHub
end

local function LoadModule(relPath)
    local localPaths = {
        "Bists-Hub/" .. relPath,
        "Gemini-Hub/" .. relPath,
        relPath,
    }

    if isfile and readfile then
        for _, path in ipairs(localPaths) do
            if isfile(path) then
                local content = readfile(path)
                if content and #content > 0 then
                    if content:sub(1, 3) == "\239\187\191" then
                        content = content:sub(4)
                    end
                    local fn, err = loadstring(content, relPath)
                    if fn then return fn() end
                    warn("[Bist's Hub] Failed to load local module: " .. relPath .. " - " .. tostring(err))
                end
            end
        end
    end

    local Repos = {
        "https://raw.githubusercontent.com/kanikule182-collab/bist-s-hub/main/bists-Hub/",
        "https://raw.githubusercontent.com/kanikule182-collab/bist-s-hub/refs/heads/main/bists-Hub/",
        "https://raw.githubusercontent.com/kanikule182-collab/bist-s-hub/main/",
        "https://raw.githubusercontent.com/kanikule182-collab/Bists-Hub/refs/heads/main/",
        "https://raw.githubusercontent.com/kanikule182-collab/Gemini-Hub/refs/heads/main/",
        "https://raw.githubusercontent.com/kanikule182-collab/bists-hub/refs/heads/main/",
        "https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/",
    }

    if getgenv and getgenv().BistsHubBaseUrl then
        table.insert(Repos, 1, getgenv().BistsHubBaseUrl)
    end

    for _, BaseUrl in ipairs(Repos) do
        local url = BaseUrl .. relPath
        local s, remoteContent = pcall(function() return game:HttpGet(url .. "?t=" .. tick()) end)
        if not s or not remoteContent or #remoteContent == 0 or remoteContent:find("404: Not Found") then
            s, remoteContent = pcall(function() return game:HttpGet(url) end)
        end
        if s and remoteContent and #remoteContent > 0 and not remoteContent:find("404: Not Found") then
            if remoteContent:sub(1, 3) == "\239\187\191" then
                remoteContent = remoteContent:sub(4)
            end
            local fn, err = loadstring(remoteContent, relPath)
            if fn then return fn() end
            warn("[Bist's Hub] Failed to parse remote module from " .. BaseUrl .. ": " .. tostring(err))
        end
    end

    warn("[Bist's Hub Fatal] Unable to load module: " .. tostring(relPath))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Bist's Hub Error",
            Text = "Failed to load: " .. tostring(relPath),
            Duration = 10
        })
    end)
    error("[Bist's Hub] Unable to load module: " .. relPath)
end

GeminiHub.LoadModule = LoadModule

local rawEnv = LoadModule("Components/Environment.luau")
GeminiHub.Environment = setmetatable(rawEnv or {}, {
    __index = function(_, key)
        return (getgenv and getgenv()[key]) or getfenv(0)[key]
    end
})

GeminiHub.ESPLibrary = LoadModule("Components/ESP.luau")

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

local g_writefile = writefile or (GeminiHub.Environment and GeminiHub.Environment.writefile)
local g_readfile = readfile or (GeminiHub.Environment and GeminiHub.Environment.readfile)
local g_isfile = isfile or (GeminiHub.Environment and GeminiHub.Environment.isfile)
local g_makefolder = makefolder or (GeminiHub.Environment and GeminiHub.Environment.makefolder)
local g_isfolder = isfolder or (GeminiHub.Environment and GeminiHub.Environment.isfolder)

if g_writefile and g_readfile then
    pcall(function()
        if g_makefolder and g_isfolder and not g_isfolder("GeminiHub") then
            g_makefolder("GeminiHub")
        end

        if not (g_isfile and g_isfile("GeminiHub/UserData.json")) then
            local Data = {
                TotalExecutions = 0,
                UILibrary = "Obsidian"
            }
            g_writefile("GeminiHub/UserData.json", Services.HttpService:JSONEncode(Data))
        end

        local UserData = g_readfile("GeminiHub/UserData.json")
        local Decoded = Services.HttpService:JSONDecode(UserData)
        Decoded.TotalExecutions = (Decoded.TotalExecutions or 0) + 1
        Decoded.UILibrary = Decoded.UILibrary or "Obsidian"

        GeminiHub.TotalExecutions = Decoded.TotalExecutions
        GeminiHub.UILibrary = Decoded.UILibrary

        g_writefile("GeminiHub/UserData.json", Services.HttpService:JSONEncode(Decoded))
    end)
end

GeminiHub.Interface = LoadModule("Components/Interface.luau")
GeminiHub.Analytics = LoadModule("Components/Analytics.luau")

local GameList = {
    [2440500124] = "Doors",
    [6839171747] = "Doors",
    [6516141723] = "Doors",
}

local CurrentGame = GameList[game.GameId] or GameList[game.PlaceId]
if not CurrentGame then
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        if info and info.Name and info.Name:lower():find("doors") then
            CurrentGame = "Doors"
        end
    end)
end

local success, err = pcall(function()
    if CurrentGame == "Doors" or game.PlaceId == 6839171747 or game.PlaceId == 6516141723 or game.GameId == 2440500124 then
        LoadModule("Games/Doors/Loader.luau")
    else
        LoadModule("Games/Universal/Loader.luau")
    end
end)

if not success then
    warn("[Bist's Hub Error]: " .. tostring(err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Bist's Hub Error",
            Text = tostring(err):sub(1, 100),
            Duration = 10
        })
    end)
end
