-- Gemini Hub: Local Analytics & Session Stats (No external telemetry)
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

local Player = Services.Players.LocalPlayer
local SessionData = {
    Account = Player and Player.Name or "Unknown",
    Executor = GeminiHub.Environment.identifyexecutor and GeminiHub.Environment.identifyexecutor() or "Unknown",
    Executions = tonumber(GeminiHub.TotalExecutions) or 1,
    PlaceId = tostring(game.PlaceId),
    StartTime = tick(),
}

GeminiHub.SessionData = SessionData
print("[Gemini Hub] Session initialized for " .. SessionData.Account .. " on " .. SessionData.Executor)
return SessionData
