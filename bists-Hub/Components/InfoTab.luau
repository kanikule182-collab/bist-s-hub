return function(Window)
    local LatestChangelog = {
        "<font size='22' color='rgb(50, 255, 100)'><b>ALL FIXEEED!!!!</b></font>",
        "<font color='rgb(160, 255, 180)'>• Remote GitHub loader 100% repaired</font>",
        "<font color='rgb(160, 255, 180)'>• Clean UI (removed cross & diamond button)</font>",
        "<font color='rgb(160, 255, 180)'>• Toggle with [RightShift] or [Insert]</font>",
        "<font color='rgb(160, 255, 180)'>• Full Real executor optimization</font>",
        "<font color='rgb(160, 255, 180)'>• Anti-Scribble bypass (No paper damage & screen clean)</font>",
        "<font color='rgb(160, 255, 180)'>• Safe DOORS lobby initialization</font>",
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
