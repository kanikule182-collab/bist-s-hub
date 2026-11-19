local Hub = (getgenv and (getgenv().OpenHub or getgenv().GeminiHub or getgenv().BistsHub)) or _G.OpenHub or _G.GeminiHub or _G.BistsHub

local function LoadModule(relPath)
    if Hub and Hub.LoadModule then
        return Hub.LoadModule(relPath)
    end
    local localPaths = {
        "Open-Hub/" .. relPath,
        "Bists-Hub/" .. relPath,
        "Gemini-Hub/" .. relPath,
        relPath
    }
    if isfile and readfile then
        for _, path in ipairs(localPaths) do
            if isfile(path) then
                return loadstring(readfile(path), relPath)()
            end
        end
    end
    local url = "https://raw.githubusercontent.com/kanikule182-collab/bist-s-hub/main/bists-Hub/" .. relPath
    return loadstring(game:HttpGet(url .. "?t=" .. tick()), relPath)()
end

LoadModule("Games/PetSimulator99/Main.luau")
