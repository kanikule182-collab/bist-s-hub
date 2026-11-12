return function(Window)
    local LatestChangelog = {
        "12/11/2026",
        "<font color='rgb(0, 200, 255)'>+ Bist's Hub DOORS Edition initialized</font>",
        "<font color='rgb(0, 255, 100)'>+ Full The Archives subfloor bypasses & ESP</font>",
        "<font color='rgb(0, 255, 100)'>+ Noise TV physical topple flip in The Stairwell</font>",
        "<font color='rgb(0, 255, 100)'>+ Smart Anti-Sit seat blacklist</font>",
        "<font color='rgb(0, 255, 100)'>+ Auto Padlock Solver & Breaker Solver</font>",
        "<font color='rgb(0, 255, 100)'>+ Next Progression Door ESP</font>",
    }

    local function CloneReference(Object)
        local env = (GeminiHub and GeminiHub.Environment) or (getgenv and getgenv()) or {}
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
    })

    local Library = GeminiHub.Interface.Library
    local SaveManager = GeminiHub.Interface.SaveManager
    local ThemeManager = GeminiHub.Interface.ThemeManager

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
    User:AddLabel("Total Executions: " .. (GeminiHub.TotalExecutions and GeminiHub.TotalExecutions or "1"), true)

    local Changelog = InfoTab:AddRightGroupbox("Changelog")
    for Index, Change in pairs(LatestChangelog) do
        Changelog:AddLabel(Change, true)
    end

    local Name, Version = "Unknown", "N/A"
    if GeminiHub.Environment and GeminiHub.Environment.identifyexecutor then
        Name, Version = GeminiHub.Environment.identifyexecutor()
    end
    local Executor = InfoTab:AddRightGroupbox("Executor Info")
    Executor:AddLabel("Name: " .. tostring(Name), true)
    Executor:AddLabel("Version: " .. tostring(Version or "N/A"), true)
    Executor:AddDivider()
    Executor:AddLabel("Status: Active & Protected", true)
end
