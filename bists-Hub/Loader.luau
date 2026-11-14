if getgenv and (getgenv().OpenHub or getgenv().BistsHub or getgenv().GeminiHub or getgenv().DoorsMainUnload or getgenv().PS99Unload) then
    local old = getgenv().OpenHub or getgenv().BistsHub or getgenv().GeminiHub
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
    if getgenv().PS99Unload then
        pcall(getgenv().PS99Unload)
        getgenv().PS99Unload = nil
    end
    getgenv().OpenHub = nil
    getgenv().BistsHub = nil
    getgenv().GeminiHub = nil
    getgenv().Abysall = nil
    task.wait(0.15)
end

local OpenHub = {
    Legit = true,
    Name = "Open Hub",
    Version = "1.1.0",
}
local BistsHub = OpenHub
local GeminiHub = OpenHub

function OpenHub:Unload()
    if self.Unloaded then return end
    self.Unloaded = true

    if self.DoorsUnload then
        pcall(self.DoorsUnload)
        self.DoorsUnload = nil
    end

    if self.PS99Unload then
        pcall(self.PS99Unload)
        self.PS99Unload = nil
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
                if child.Name:find("OpenHub") or child.Name:find("BistsHub") or child.Name:find("GeminiHub") or child.Name == "OpenHub_FloatToggle" or child.Name == "BistsHub_FloatToggle" then
                    child:Destroy()
                end
            end
        end
    end)
end

if getgenv then
    getgenv().OpenHub = OpenHub
    getgenv().BistsHub = OpenHub
    getgenv().GeminiHub = OpenHub
    getgenv().Abysall = OpenHub
end

local function LoadModule(relPath)
    local localPaths = {
        "Open-Hub/" .. relPath,
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
                    warn("[Open Hub] Failed to load local module: " .. relPath .. " - " .. tostring(err))
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

    if getgenv and getgenv().OpenHubBaseUrl then
        table.insert(Repos, 1, getgenv().OpenHubBaseUrl)
    elseif getgenv and getgenv().BistsHubBaseUrl then
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
            warn("[Open Hub] Failed to parse remote module from " .. BaseUrl .. ": " .. tostring(err))
        end
    end

    warn("[Open Hub Fatal] Unable to load module: " .. tostring(relPath))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Open Hub Error",
            Text = "Failed to load: " .. tostring(relPath),
            Duration = 10
        })
    end)
    error("[Open Hub] Unable to load module: " .. relPath)
end

OpenHub.LoadModule = LoadModule

local rawEnv = LoadModule("Components/Environment.luau")
OpenHub.Environment = setmetatable(rawEnv or {}, {
    __index = function(_, key)
        return (getgenv and getgenv()[key]) or getfenv(0)[key]
    end
})

OpenHub.ESPLibrary = LoadModule("Components/ESP.luau")

local function CloneReference(Object)
    if OpenHub and OpenHub.Environment and OpenHub.Environment.cloneref then
        return OpenHub.Environment.cloneref(Object)
    else
        return Object
    end
end

local Services = setmetatable({}, {
    __index = function(self, Name)
        return CloneReference(game:GetService(Name))
    end
})

local g_writefile = writefile or (OpenHub.Environment and OpenHub.Environment.writefile)
local g_readfile = readfile or (OpenHub.Environment and OpenHub.Environment.readfile)
local g_isfile = isfile or (OpenHub.Environment and OpenHub.Environment.isfile)
local g_makefolder = makefolder or (OpenHub.Environment and OpenHub.Environment.makefolder)
local g_isfolder = isfolder or (OpenHub.Environment and OpenHub.Environment.isfolder)

if g_writefile and g_readfile then
    pcall(function()
        if g_makefolder and g_isfolder and not g_isfolder("OpenHub") then
            g_makefolder("OpenHub")
        end

        if not (g_isfile and g_isfile("OpenHub/UserData.json")) then
            local Data = {
                TotalExecutions = 0,
                UILibrary = "Obsidian"
            }
            g_writefile("OpenHub/UserData.json", Services.HttpService:JSONEncode(Data))
        end

        local UserData = g_readfile("OpenHub/UserData.json")
        local Decoded = Services.HttpService:JSONDecode(UserData)
        Decoded.TotalExecutions = (Decoded.TotalExecutions or 0) + 1
        Decoded.UILibrary = Decoded.UILibrary or "Obsidian"

        OpenHub.TotalExecutions = Decoded.TotalExecutions
        OpenHub.UILibrary = Decoded.UILibrary

        g_writefile("OpenHub/UserData.json", Services.HttpService:JSONEncode(Decoded))
    end)
end

OpenHub.Interface = LoadModule("Components/Interface.luau")
OpenHub.Analytics = LoadModule("Components/Analytics.luau")

local GameList = {
    [2440500124] = "Doors",
    [6839171747] = "Doors",
    [6516141723] = "Doors",
    [8737899170] = "PetSimulator99",
    [16498369169] = "PetSimulator99",
}

local CurrentGame = GameList[game.GameId] or GameList[game.PlaceId]
if not CurrentGame then
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        if info and info.Name then
            local n = info.Name:lower()
            if n:find("doors") then
                CurrentGame = "Doors"
            elseif n:find("pet simulator 99") or n:find("pet sim 99") or n:find("ps99") then
                CurrentGame = "PetSimulator99"
            end
        end
    end)
end

local success, err = pcall(function()
    if CurrentGame == "Doors" or game.PlaceId == 6839171747 or game.PlaceId == 6516141723 or game.GameId == 2440500124 then
        LoadModule("Games/Doors/Loader.luau")
    elseif CurrentGame == "PetSimulator99" or game.PlaceId == 8737899170 or game.PlaceId == 16498369169 or game.GameId == 3317771874 then
        LoadModule("Games/PetSimulator99/Loader.luau")
    else
        LoadModule("Games/Universal/Loader.luau")
    end
end)

if not success then
    warn("[Open Hub Error]: " .. tostring(err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Open Hub Error",
            Text = tostring(err):sub(1, 100),
            Duration = 10
        })
    end)
end
