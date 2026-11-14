return function(Window)
    local LatestChangelog = {
        "<font size='22' color='rgb(50, 200, 255)'><b>Open Hub</b></font>",
        "<font color='rgb(180, 255, 200)'>• Добавлен Pet Simulator 99 (Авто Ранг, Авто Фарм, Сбор Дропа)</font>",
        "<font color='rgb(180, 255, 200)'>• Фиксы и оптимизация (Doors, ESP, Unload)</font>",
    }

    local function CloneReference(Object)
        local env = (getgenv and (getgenv().OpenHub or getgenv().GeminiHub or getgenv().BistsHub)) and (getgenv().OpenHub or getgenv().GeminiHub or getgenv().BistsHub).Environment or (getgenv and getgenv()) or {}
        if env and env.cloneref then
            return env.cloneref(Object)
        elseif cloneref then
            return cloneref(Object)
        else
            return Object
        end
    end

    local Services = setmetatable({}, {
        __index = function(self, Name)
            return CloneReference(game:GetService(Name))
        end
    end)

    local Hub = (getgenv and (getgenv().OpenHub or getgenv().GeminiHub or getgenv().BistsHub)) or _G.OpenHub or _G.GeminiHub or _G.BistsHub
    local Library = Hub.Interface.Library
    local SaveManager = Hub.Interface.SaveManager
    local ThemeManager = Hub.Interface.ThemeManager

    local LocalPlayer = Services.Players.LocalPlayer
    local InfoTab = Window:AddTab("Info", "user")

    local User = InfoTab:AddLeftGroupbox("User Info")

    local ImageSize = Enum.ThumbnailSize.Size420x420
    local ImageType = Enum.ThumbnailType.HeadShot

    local Content = Services.Players:GetUserThumbnailAsync(LocalPlayer.UserId, ImageType, ImageSize)

    User:AddImage("UserIcon", {
        Image = Content
    })

    User:AddLabel("User: " .. LocalPlayer.Name, true)
    User:AddLabel("Total Executions: " .. (Hub.TotalExecutions and Hub.TotalExecutions or "1"), true)

    local Changelog = InfoTab:AddRightGroupbox("Changelog")
    for Index, Change in pairs(LatestChangelog) do
        Changelog:AddLabel(Change, true)
    end

    local Name, Version = "Unknown", "N/A"
    if Hub.Environment and Hub.Environment.identifyexecutor then
        Name, Version = Hub.Environment.identifyexecutor()
    end
    local Executor = InfoTab:AddRightGroupbox("Executor Info")
    Executor:AddLabel("Name: " .. tostring(Name), true)
    Executor:AddLabel("Version: " .. tostring(Version or "N/A"), true)
    Executor:AddDivider()
    Executor:AddLabel("Status: Active & Protected", true)
end
