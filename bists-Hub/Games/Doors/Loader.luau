local Hub = (getgenv and (getgenv().OpenHub or getgenv().GeminiHub or getgenv().BistsHub)) or _G.OpenHub or _G.GeminiHub or _G.BistsHub or GeminiHub
if game.PlaceId ~= 6516141723 then
    Hub.LoadModule("Games/Doors/Main.luau")
else
    Hub.LoadModule("Games/Doors/Lobby.luau")
end
