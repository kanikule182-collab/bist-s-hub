local Hub = (getgenv and (getgenv().OpenHub or getgenv().GeminiHub or getgenv().BistsHub)) or _G.OpenHub or _G.GeminiHub or _G.BistsHub
if not Hub then
    error("[Open Hub PS99] Hub instance not found in globals!")
end

if Hub.PS99Unload then
    pcall(Hub.PS99Unload)
    Hub.PS99Unload = nil
end
if getgenv and getgenv().PS99Unload then
    pcall(getgenv().PS99Unload)
    getgenv().PS99Unload = nil
end

local LoadStart = tick()
Hub.SavePath = "PetSimulator99/Main"

local Library = Hub.Interface.Library
local SaveManager = Hub.Interface.SaveManager
local ThemeManager = Hub.Interface.ThemeManager
local Toggles = Library.Toggles
local Options = Library.Options

local function CloneReference(Object)
    local env = Hub.Environment or (getgenv and getgenv()) or {}
    if env and env.cloneref then
        return env.cloneref(Object)
    elseif cloneref then
        return cloneref(Object)
    end
    return Object
end

local Services = setmetatable({}, {
    __index = function(_, Name)
        return CloneReference(game:GetService(Name))
    end
})

local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local Workspace = Services.Workspace

local LocalPlayer = Players.LocalPlayer
local Network = ReplicatedStorage:WaitForChild("Network", 10)

local Connections = {}
local Running = true

local function AddConnection(conn)
    table.insert(Connections, conn)
    return conn
end

local function UnloadAll()
    Running = false
    pcall(RemoveSafePlatform)
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    if Hub.ESPLibrary and Hub.ESPLibrary.Unload then
        pcall(function() Hub.ESPLibrary:Unload() end)
    end

    if Library and Library.Unload then
        pcall(function() Library:Unload() end)
    end

    pcall(function()
        local gethui = gethui or function() return game:GetService("CoreGui") end
        local h = gethui()
        if h then
            for _, child in ipairs(h:GetChildren()) do
                if child.Name:find("OpenHub") or child.Name:find("BistsHub") or child.Name:find("GeminiHub") or child.Name == "OpenHub_FloatToggle" then
                    child:Destroy()
                end
            end
        end
    end)
end

Hub.PS99Unload = UnloadAll
if getgenv then
    getgenv().PS99Unload = UnloadAll
end

-- ==============================================================
-- CORE HELPER FUNCTIONS (Declared first so all callbacks can see them)
-- ==============================================================

local function GetCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function DamageBreakable(uid)
    if not uid or not Network then return end
    local remote = Network:FindFirstChild("Breakables_PlayerDealDamage")
    if remote then
        remote:FireServer(tostring(uid))
    end
end

local function SafeSetText(label, text)
    if not label then return end
    pcall(function()
        if setthreadidentity then setthreadidentity(8)
        elseif setidentity then setidentity(8) end
        if label.SetText then
            label:SetText(text)
        elseif label.Text ~= nil then
            label.Text = text
        end
    end)
end

local function GetBestUnlockedEgg()
    local bestNum = 1
    local bestName = "Cracked Egg"
    local bestCap = nil

    pcall(function()
        local save = require(ReplicatedStorage.Library.Client.Save).Get()
        if save and save.MaximumAvailableEgg then
            bestNum = save.MaximumAvailableEgg
        end
    end)

    pcall(function()
        local dir = require(ReplicatedStorage.Library.Directory)
        if dir and dir.Eggs then
            for id, egg in pairs(dir.Eggs) do
                if egg.eggNumber == bestNum then
                    bestName = tostring(id)
                    break
                end
            end
        end
    end)

    local eggsMain = Workspace.__THINGS:FindFirstChild("Eggs") and Workspace.__THINGS.Eggs:FindFirstChild("Main")
    if eggsMain then
        bestCap = eggsMain:FindFirstChild(bestNum .. " - Egg Capsule")
    end

    return bestName, bestNum, bestCap
end

local function GetRealGoals()
    local goals = {}
    local rankNum = 1
    local starsNum = 0
    pcall(function()
        local save = require(ReplicatedStorage.Library.Client.Save).Get()
        if save then
            rankNum = save.Rank or 1
            starsNum = save.RankStars or 0
            if save.Goals then
                for k, g in pairs(save.Goals) do
                    table.insert(goals, {
                        Index = tostring(k),
                        Type = g.Type,
                        BreakableType = g.BreakableType,
                        Amount = g.Amount or 0,
                        Progress = g.Progress or 0,
                        Stars = g.Stars or 1
                    })
                end
            end
        end
    end)
    return goals, rankNum, starsNum
end

local function FindBreakablesByFilter(filter, maxCount)
    maxCount = maxCount or 1
    local things = Workspace:FindFirstChild("__THINGS")
    local breakables = things and things:FindFirstChild("Breakables")
    if not breakables then return {} end

    local char, root = GetCharacter()
    local rootPos = root and root.Position or Vector3.zero

    local results = {}
    for _, item in ipairs(breakables:GetChildren()) do
        if not (item:IsA("Model") or item:IsA("BasePart")) then
            continue
        end

        local id = (item:GetAttribute("BreakableID") or item.Name):lower()
        local matches = false

        if filter == "diamond" then
            matches = id:find("diamond") or id:find("gem")
        elseif filter == "safe" then
            matches = id:find("safe")
        elseif filter == "present" then
            matches = id:find("present")
        elseif filter == "pinata" then
            matches = id:find("pinata")
        elseif filter == "coin" then
            matches = id:find("coin") or id:find("crate") or id:find("default")
        elseif filter == "any" then
            matches = true
        end

        if matches then
            local pos = item:GetPivot().Position
            local d = (pos - rootPos).Magnitude
            table.insert(results, { item = item, dist = d })
        end
    end

    table.sort(results, function(a, b) return a.dist < b.dist end)

    local finalItems = {}
    for i = 1, math.min(#results, maxCount) do
        table.insert(finalItems, results[i].item)
    end
    return finalItems
end

local function HatchEgg(eggName, count)
    if not Network or not Network:FindFirstChild("Eggs_RequestPurchase") then return false end
    count = math.clamp(count or 1, 1, 3)

    local bestName, bestNum, bestCapsule = GetBestUnlockedEgg()
    if not eggName or eggName == "Latest Unlocked (Auto)" or eggName == "Best" then
        eggName = bestName
    end

    local eggCapsule = (eggName == bestName and bestCapsule) or nil
    if not eggCapsule then
        local eggsMain = Workspace.__THINGS:FindFirstChild("Eggs") and Workspace.__THINGS.Eggs:FindFirstChild("Main")
        if eggsMain then
            eggCapsule = eggsMain:FindFirstChild(bestNum .. " - Egg Capsule") or eggsMain:FindFirstChild("1 - Egg Capsule")
        end
    end

    local targetPos = eggCapsule and eggCapsule:GetPivot().Position or Vector3.new(95, 21, -155)
    local char, root = GetCharacter()
    if not root then return false end

    -- Only move to capsule if player is not near it
    if (root.Position - targetPos).Magnitude > 16 then
        root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 4))
        task.wait(0.35)
    end

    local success, res = pcall(function()
        return Network.Eggs_RequestPurchase:InvokeServer(eggName, count)
    end)

    return success and res
end

local SafePlatform = nil

local function RemoveSafePlatform()
    if SafePlatform then
        pcall(function() SafePlatform:Destroy() end)
        SafePlatform = nil
    end
end

local function EnsureSafePlatform(targetCFrame)
    if not SafePlatform or not SafePlatform.Parent then
        SafePlatform = Instance.new("Part")
        SafePlatform.Name = "OpenHub_SafePlatform"
        SafePlatform.Size = Vector3.new(28, 2, 28)
        SafePlatform.Anchored = true
        SafePlatform.CanCollide = true
        SafePlatform.Transparency = 0.5
        SafePlatform.Material = Enum.Material.ForceField
        SafePlatform.Color = Color3.fromRGB(0, 255, 170)
        SafePlatform.Parent = Workspace
    end
    SafePlatform.CFrame = targetCFrame
    return SafePlatform
end

local function IsInMinigame()
    local inInst = false
    local id = nil
    pcall(function()
        local client = ReplicatedStorage:FindFirstChild("Library") and ReplicatedStorage.Library:FindFirstChild("Client")
        local inst = client and client:FindFirstChild("InstancingCmds")
        if inst then
            local m = require(inst)
            inInst = (m.IsInInstance and m.IsInInstance()) or false
            id = (m.GetInstanceID and m.GetInstanceID()) or nil
        end
    end)
    return inInst, id
end

local function PlayerHasBomb()
    local char = LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- 1. Check tools or children in character
    for _, child in ipairs(char:GetChildren()) do
        local n = child.Name:lower()
        if n:find("pump") or n:find("bomb") or n:find("fire") or n:find("fuse") or n:find("tnt") or n:find("tag") then
            return true
        end
    end

    -- 2. Check attributes
    for k, v in pairs(LocalPlayer:GetAttributes()) do
        local n = tostring(k):lower()
        if (n:find("bomb") or n:find("pump") or n:find("hold") or n:find("it")) and v == true then
            return true
        end
    end
    for k, v in pairs(char:GetAttributes()) do
        local n = tostring(k):lower()
        if (n:find("bomb") or n:find("pump") or n:find("hold") or n:find("it")) and v == true then
            return true
        end
    end

    -- 3. Check Workspace HotPumpkin models and HotTag BillboardGui
    for _, child in ipairs(Workspace:GetChildren()) do
        local n = child.Name:lower()
        if (n:find("hotpumpkin") or n:find("pumpkin") or n:find("bomb")) and child:IsA("Model") then
            local tag = child:FindFirstChild("HotTag")
            if tag and tag:IsA("BillboardGui") and tag.Adornee and tag.Adornee:IsDescendantOf(char) then
                return true
            end
            local pPos = child:GetPivot().Position
            if (pPos - root.Position).Magnitude <= 5 then
                return true
            end
        end
    end

    -- 4. Check ScreenGuis for warnings
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, lbl in ipairs(gui:GetDescendants()) do
                    if lbl:IsA("TextLabel") and lbl.Visible then
                        local txt = lbl.Text:lower()
                        if txt:find("pass") or txt:find("run!") or txt:find("you have the") or txt:find("you're it") then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

local function GetNearestOtherPlayer(mode)
    mode = mode or "Nearest Player"
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local candidates = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                table.insert(candidates, { player = p, dist = d })
            end
        end
    end

    if #candidates == 0 then return nil end

    if mode == "Random Player" then
        return candidates[math.random(1, #candidates)].player
    elseif mode == "Furthest Player" then
        table.sort(candidates, function(a, b) return a.dist > b.dist end)
        return candidates[1].player
    else
        table.sort(candidates, function(a, b) return a.dist < b.dist end)
        return candidates[1].player
    end
end

-- ==============================================================
-- WINDOW & UI LAYOUT
-- ==============================================================

local Window = Library:CreateWindow({
    Title = "Open Hub",
    Footer = "Open Hub • Pet Simulator 99",
    NotifySide = "Right",
    ShowCustomCursor = false,
    AutoShow = true,
    Center = true,
    TabPadding = 3,
    MenuFadeTime = 0,
    CornerRadius = 2,
})

Hub.Interface.ApplyInfoTab(Window)

local Tabs = {
    Rank       = Window:AddTab("Real Auto Rank", "trophy"),
    Farm       = Window:AddTab("Auto Farm All", "coins"),
    Minigames  = Window:AddTab("Minigames", "gamepad"),
    Visuals    = Window:AddTab("Visuals", "eye"),
    Player     = Window:AddTab("Player", "user"),
}

local Groupboxes = {}

Groupboxes.Rank = Tabs.Rank:AddLeftGroupbox("Real Auto Rank")
Groupboxes.Quests = Tabs.Rank:AddRightGroupbox("Real Goals (Save Data)")

Groupboxes.Farm = Tabs.Farm:AddLeftGroupbox("AoE Farm & Nuke")
Groupboxes.Eggs = Tabs.Farm:AddRightGroupbox("Eggs & Hatching")

Groupboxes.Minigames = Tabs.Minigames:AddLeftGroupbox("Minigame God Mode & Auto")
Groupboxes.Bomb      = Tabs.Minigames:AddRightGroupbox("Pass The Bomb (Hot Potato)")

Groupboxes.Visuals = Tabs.Visuals:AddLeftGroupbox("ESP")
Groupboxes.Player = Tabs.Player:AddLeftGroupbox("Movement")

local QuestLabels = {
    Goal1 = Groupboxes.Quests:AddLabel("Goal 1: Loading..."),
    Goal2 = Groupboxes.Quests:AddLabel("Goal 2: Loading..."),
    Goal3 = Groupboxes.Quests:AddLabel("Goal 3: Loading..."),
    RankInfo = Groupboxes.Quests:AddLabel("Rank: Loading..."),
}

local StatusLabel = Groupboxes.Rank:AddLabel("Status: Idle")
local MinigameStatusLabel = Groupboxes.Minigames:AddLabel("Minigame: Idle (Waiting for round)")
local BombStatusLabel     = Groupboxes.Bomb:AddLabel("Bomb Status: Clean (No Bomb)")

Groupboxes.Rank:AddToggle("AutoRank", {
    Text = "Enable Real Auto Rank",
    Default = true,
    Tooltip = "Reads real Save.Goals: hatches latest unlocked egg, breaks Safes, Presents, Diamonds, and auto-levels."
})

Groupboxes.Rank:AddToggle("AutoClaimRank", {
    Text = "Auto Claim Stars & Rewards",
    Default = true,
})

Groupboxes.Rank:AddDivider()

Groupboxes.Rank:AddButton({
    Text = "Claim All Rank Rewards Now",
    Func = function()
        if setthreadidentity then setthreadidentity(8)
        elseif setidentity then setidentity(8) end

        if Network then
            if Network:FindFirstChild("Ranks_ClaimAll") then
                pcall(function() Network.Ranks_ClaimAll:FireServer() end)
            end
            if Network:FindFirstChild("Ranks_ClaimReward") then
                for i = 1, 25 do
                    pcall(function() Network.Ranks_ClaimReward:FireServer(i) end)
                end
            end
            local giftRem = Network:FindFirstChild("Redeem Free Gift")
            if giftRem then
                for i = 1, 12 do
                    pcall(function() giftRem:InvokeServer(i) end)
                end
            end
        end
        pcall(function() Library:Notify("Claimed all rank track rewards & stars!", 4) end)
    end
})

Groupboxes.Rank:AddButton({
    Text = "Trigger Rank Up Now",
    Func = function()
        if setthreadidentity then setthreadidentity(8)
        elseif setidentity then setidentity(8) end

        local curStars = 0
        local neededStars = 25
        pcall(function()
            local save = require(ReplicatedStorage.Library.Client.Save).Get()
            curStars = save.RankStars or 0
            local rUtil = require(ReplicatedStorage.Library.Util.RanksUtil)
            local id = rUtil.RankIDFromNumber(save.Rank or 2)
            local dir = require(ReplicatedStorage.Library.Directory)
            local rData = dir.Ranks[id]
            if rData and rData.Rewards then
                local s = 0
                for _, rw in ipairs(rData.Rewards) do s = s + (rw.StarsRequired or 0) end
                neededStars = s
            end
        end)

        if Network and Network:FindFirstChild("Ranks_RankUp") then
            Network.Ranks_RankUp:FireServer()
        end

        pcall(function()
            if curStars >= neededStars then
                Library:Notify("Rank Up request sent! (" .. curStars .. "/" .. neededStars .. " stars)", 4)
            else
                Library:Notify("Need " .. (neededStars - curStars) .. " more stars for next Rank! (" .. curStars .. "/" .. neededStars .. ")", 4)
            end
        end)
    end
})

Groupboxes.Farm:AddButton({
    Text = "⚡ Моментально сломать всё (Nuke Area)",
    Tooltip = "Instantly deals massive damage to all breakables in your zone and magnets all orbs & loot.",
    Func = function()
        if setthreadidentity then setthreadidentity(8)
        elseif setidentity then setidentity(8) end

        local b = Workspace:FindFirstChild("__THINGS") and Workspace.__THINGS:FindFirstChild("Breakables")
        if not b then return end
        local remote = Network and Network:FindFirstChild("Breakables_PlayerDealDamage")
        if not remote then return end

        local char, root = GetCharacter()
        local rootPos = root and root.Position or Vector3.zero
        local count = 0

        for _, item in ipairs(b:GetChildren()) do
            if item:IsA("Model") or item:IsA("BasePart") then
                local pos = item:GetPivot().Position
                if (pos - rootPos).Magnitude <= 220 then
                    local uid = item:GetAttribute("BreakableUID") or item.Name
                    for _ = 1, 6 do
                        remote:FireServer(uid)
                    end
                    count = count + 1
                end
            end
        end

        task.wait(0.1)
        local things = Workspace.__THINGS
        if things:FindFirstChild("Orbs") then
            for _, orb in ipairs(things.Orbs:GetChildren()) do
                pcall(function() orb:PivotTo(root.CFrame) end)
            end
        end
        if things:FindFirstChild("Lootbags") then
            for _, bag in ipairs(things.Lootbags:GetChildren()) do
                pcall(function() bag:PivotTo(root.CFrame) end)
            end
        end

        pcall(function() Library:Notify("Shattered " .. count .. " breakables & collected all loot!", 3) end)
    end
})

Groupboxes.Farm:AddToggle("ContinuousNuke", {
    Text = "Ultra Nuke Loop (Non-Stop)",
    Default = false,
    Tooltip = "Continuously destroys every object in the entire zone as soon as it spawns."
})

Groupboxes.Farm:AddToggle("AoEFarm", {
    Text = "AoE Breakables Multi-Farm",
    Default = true,
})

Groupboxes.Farm:AddToggle("AutoCollect", {
    Text = "Hyper Magnet (Orbs & Lootbags)",
    Default = true,
})

Groupboxes.Farm:AddToggle("AutoFreeGifts", {
    Text = "Auto Claim Free Gifts",
    Default = true,
})

Groupboxes.Farm:AddToggle("AutoEquipBest", {
    Text = "Auto Equip Best Pets",
    Default = true,
})

Groupboxes.Eggs:AddToggle("AutoHatch", {
    Text = "Auto Hatch Eggs",
    Default = false,
})

Groupboxes.Eggs:AddDropdown("EggSelect", {
    Text = "Select Egg",
    Values = { "Latest Unlocked (Auto)", "Cracked Egg", "Spotted Egg", "Wood Egg" },
    Default = 1,
    Multi = false,
})

Groupboxes.Eggs:AddSlider("HatchDelaySlider", {
    Text = "Hatch Delay (Seconds)",
    Min = 1.5,
    Max = 6,
    Default = 2.5,
    Rounding = 1,
    Tooltip = "Matches server debounce so no rollbacks happen."
})

Groupboxes.Eggs:AddSlider("HatchAmount", {
    Text = "Hatch Amount",
    Min = 1,
    Max = 3,
    Default = 1,
    Rounding = 0,
})

Groupboxes.Minigames:AddToggle("MinigameGodMode", {
    Text = "God Mode (Under Map Safe Floor)",
    Default = true,
    Tooltip = "Builds an invincible platform under the arena floor and anchors you there. Immune to sweepers, monsters, and traps."
})

Groupboxes.Minigames:AddDropdown("MinigamePosition", {
    Text = "Safe Floor Position",
    Values = { "Under Map (-14 Studs)", "Above Arena (+32 Studs)" },
    Default = 1,
    Multi = false,
})

Groupboxes.Minigames:AddToggle("MinigameAutoWin", {
    Text = "Auto Complete Obbies & Mazes",
    Default = true,
    Tooltip = "Detects bridge endpoints and portals to automatically complete minigames."
})

Groupboxes.Bomb:AddToggle("AutoPassBomb", {
    Text = "⚡ Instant Pass Bomb / Hot Pumpkin",
    Default = true,
    Tooltip = "When the lit bomb is attached to you, instantaneously teleports into the nearest player to pass it, then retreats safely!"
})

Groupboxes.Bomb:AddDropdown("BombTargetMode", {
    Text = "Target Selection",
    Values = { "Nearest Player", "Furthest Player", "Random Player" },
    Default = 1,
    Multi = false,
})

Groupboxes.Bomb:AddSlider("BombRetreatHeight", {
    Text = "Retreat Height (Studs)",
    Min = 15,
    Max = 60,
    Default = 28,
    Rounding = 0,
})

Groupboxes.Bomb:AddButton({
    Text = "Pass Bomb Now (Manual Trigger)",
    Func = function()
        if setthreadidentity then setthreadidentity(8)
        elseif setidentity then setidentity(8) end

        local targetPlr = GetNearestOtherPlayer(Options.BombTargetMode and Options.BombTargetMode.Value)
        local char, root = GetCharacter()
        if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") and root then
            root.CFrame = targetPlr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -1.0)
            pcall(function() Library:Notify("Teleported into " .. targetPlr.DisplayName .. " to pass bomb!", 3) end)
        else
            pcall(function() Library:Notify("No eligible players found!", 3) end)
        end
    end
})

Groupboxes.Visuals:AddToggle("BreakablesESP", {
    Text = "ESP Rare Breakables",
    Default = false,
})

Groupboxes.Player:AddSlider("WalkSpeedSlider", {
    Text = "Speed Boost",
    Min = 16,
    Max = 120,
    Default = 16,
    Rounding = 0,
})

Groupboxes.Player:AddToggle("WalkSpeedToggle", {
    Text = "Enable Speed Boost",
    Default = false,
})

Groupboxes.Player:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
})

-- ==============================================================
-- BACKGROUND LOOPS
-- ==============================================================

local MinigameArenaFloorY = nil
local LastBombPassTick = 0

task.spawn(function()
    if setthreadidentity then setthreadidentity(8)
    elseif setidentity then setidentity(8) end

    while Running do
        task.wait(0.12)
        local inMinigame, gameId = IsInMinigame()
        local char, root = GetCharacter()

        if inMinigame and root then
            -- 1. Determine arena floor Y level
            if not MinigameArenaFloorY then
                local floor = Workspace:FindFirstChild("Floor", true) or Workspace:FindFirstChild("PlayArea", true) or Workspace:FindFirstChild("Bounds", true)
                if floor and floor:IsA("BasePart") then
                    MinigameArenaFloorY = floor.Position.Y
                else
                    MinigameArenaFloorY = root.Position.Y
                end
            end

            -- 2. Check if player has the bomb / hot pumpkin
            local hasBomb = PlayerHasBomb()

            if hasBomb and Toggles.AutoPassBomb and Toggles.AutoPassBomb.Value then
                SafeSetText(BombStatusLabel, "Bomb: ⚠️ YOU HAVE BOMB! Passing...")
                SafeSetText(MinigameStatusLabel, "Minigame: Passing Bomb to nearest player!")

                local targetMode = (Options.BombTargetMode and Options.BombTargetMode.Value) or "Nearest Player"
                local targetPlr = GetNearestOtherPlayer(targetMode)

                if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") then
                    local targetRoot = targetPlr.Character.HumanoidRootPart
                    -- Teleport directly onto the target player
                    root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -1.0)
                    root.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.14)

                    -- Check if bomb successfully passed
                    if not PlayerHasBomb() then
                        LastBombPassTick = tick()
                        SafeSetText(BombStatusLabel, "Bomb: ✅ Passed to " .. targetPlr.DisplayName .. "!")

                        -- Immediately retreat to safety!
                        if Toggles.MinigameGodMode and Toggles.MinigameGodMode.Value and SafePlatform then
                            root.CFrame = SafePlatform.CFrame + Vector3.new(0, 3.5, 0)
                        else
                            local retreatY = (Options.BombRetreatHeight and Options.BombRetreatHeight.Value) or 28
                            root.CFrame = root.CFrame + Vector3.new(0, retreatY, 0)
                        end
                        task.wait(0.35)
                    end
                else
                    SafeSetText(BombStatusLabel, "Bomb: ⚠️ No target player available!")
                end
            else
                SafeSetText(BombStatusLabel, "Bomb: Clean (No Bomb)")

                -- 3. Minigame God Mode (Under Map Safe Floor)
                if Toggles.MinigameGodMode and Toggles.MinigameGodMode.Value then
                    local posMode = (Options.MinigamePosition and Options.MinigamePosition.Value) or "Under Map (-14 Studs)"
                    local targetY = MinigameArenaFloorY - 14
                    if posMode == "Above Arena (+32 Studs)" then
                        targetY = MinigameArenaFloorY + 32
                    end

                    local safeCF = CFrame.new(root.Position.X, targetY, root.Position.Z)
                    local plat = EnsureSafePlatform(safeCF)

                    -- Keep player anchored safely on top of platform
                    if math.abs(root.Position.Y - (targetY + 3.5)) > 2.5 then
                        root.CFrame = plat.CFrame + Vector3.new(0, 3.5, 0)
                    end
                    root.AssemblyLinearVelocity = Vector3.zero

                    -- Disable collision on limbs to avoid sweepers and monsters
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.CanCollide = false
                        end
                    end

                    SafeSetText(MinigameStatusLabel, "Minigame: " .. tostring(gameId or "Active") .. " (God Mode Active)")
                else
                    RemoveSafePlatform()
                    SafeSetText(MinigameStatusLabel, "Minigame: " .. tostring(gameId or "Active") .. " (God Mode Off)")
                end

                -- 4. Auto Complete Obbies & Mazes
                if Toggles.MinigameAutoWin and Toggles.MinigameAutoWin.Value then
                    local teleports = Workspace:FindFirstChild("__THINGS") and Workspace.__THINGS:FindFirstChild("Instances")
                    local hg = teleports and teleports:FindFirstChild("HalloweenGames")
                    local tpModel = hg and hg:FindFirstChild("Teleports")
                    if tpModel then
                        local leave = tpModel:FindFirstChild("Leave") or tpModel:FindFirstChild("LeaveTeleport")
                        if leave and (root.Position - leave:GetPivot().Position).Magnitude > 30 then
                            local goalPart = Workspace:FindFirstChild("Goal", true) or Workspace:FindFirstChild("Finish", true) or Workspace:FindFirstChild("WinPlatform", true)
                            if goalPart and goalPart:IsA("BasePart") then
                                root.CFrame = goalPart.CFrame + Vector3.new(0, 4, 0)
                            end
                        end
                    end
                end
            end
        else
            -- Outside minigame: reset state
            if MinigameArenaFloorY then
                MinigameArenaFloorY = nil
                RemoveSafePlatform()
            end
            SafeSetText(MinigameStatusLabel, "Minigame: Idle (Waiting for round)")
            SafeSetText(BombStatusLabel, "Bomb: Idle (Not in minigame)")
        end
    end
end)

task.spawn(function()
    while Running do
        task.wait(0.2)
        if Toggles.AutoCollect and Toggles.AutoCollect.Value then
            local char, root = GetCharacter()
            if root then
                local things = Workspace:FindFirstChild("__THINGS")
                if things then
                    if things:FindFirstChild("Orbs") then
                        for _, orb in ipairs(things.Orbs:GetChildren()) do
                            pcall(function() orb:PivotTo(root.CFrame) end)
                        end
                    end
                    if things:FindFirstChild("Lootbags") then
                        for _, bag in ipairs(things.Lootbags:GetChildren()) do
                            pcall(function() bag:PivotTo(root.CFrame) end)
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while Running do
        task.wait(0.18)
        if Toggles.ContinuousNuke and Toggles.ContinuousNuke.Value then
            local targets = FindBreakablesByFilter("any", 35)
            for _, target in ipairs(targets) do
                local uid = target:GetAttribute("BreakableUID") or target.Name
                for _ = 1, 4 do DamageBreakable(uid) end
            end
        elseif Toggles.AoEFarm and Toggles.AoEFarm.Value then
            local targets = FindBreakablesByFilter("any", 12)
            for _, target in ipairs(targets) do
                local uid = target:GetAttribute("BreakableUID") or target.Name
                DamageBreakable(uid)
            end
        end
    end
end)

task.spawn(function()
    while Running do
        task.wait(15)
        if Toggles.AutoFreeGifts and Toggles.AutoFreeGifts.Value and Network then
            local rem = Network:FindFirstChild("Redeem Free Gift")
            if rem then
                for i = 1, 12 do
                    pcall(function() rem:InvokeServer(i) end)
                end
            end
        end
    end
end)

task.spawn(function()
    while Running do
        task.wait(8)
        if Toggles.AutoEquipBest and Toggles.AutoEquipBest.Value and Network then
            if Network:FindFirstChild("Pets_EquipBest") then
                pcall(function() Network.Pets_EquipBest:FireServer() end)
            end
        end
    end
end)

task.spawn(function()
    while Running do
        local delay = (Options.HatchDelaySlider and Options.HatchDelaySlider.Value) or 2.5
        task.wait(delay)
        if Toggles.AutoHatch and Toggles.AutoHatch.Value then
            local eggName = (Options.EggSelect and Options.EggSelect.Value) or "Latest Unlocked (Auto)"
            local amt = (Options.HatchAmount and Options.HatchAmount.Value) or 1
            HatchEgg(eggName, amt)
        end
    end
end)

local LastHatchTick = 0

task.spawn(function()
    if setthreadidentity then setthreadidentity(8)
    elseif setidentity then setidentity(8) end

    while Running do
        task.wait(0.4)
        local goals, rankNum, starsNum = GetRealGoals()

        SafeSetText(QuestLabels.RankInfo, "Rank: " .. tostring(rankNum) .. " | Stars: " .. tostring(starsNum))

        for i = 1, 3 do
            local g = goals[i]
            local label = QuestLabels["Goal" .. i]
            if label then
                if g then
                    local desc = (g.BreakableType and ("Break " .. g.BreakableType)) or (g.Type == 20 and "Hatch Best Eggs") or ("Type " .. tostring(g.Type))
                    SafeSetText(label, "Goal " .. i .. ": " .. desc .. " (" .. g.Progress .. "/" .. g.Amount .. ") ⭐" .. g.Stars)
                else
                    SafeSetText(label, "Goal " .. i .. ": Completed")
                end
            end
        end

        if Toggles.AutoClaimRank and Toggles.AutoClaimRank.Value and Network then
            if Network:FindFirstChild("Ranks_ClaimAll") then
                pcall(function() Network.Ranks_ClaimAll:FireServer() end)
            end
            if Network:FindFirstChild("Ranks_ClaimReward") then
                for i = 1, 20 do
                    pcall(function() Network.Ranks_ClaimReward:FireServer(i) end)
                end
            end
            if Network:FindFirstChild("Ranks_RankUp") then
                pcall(function() Network.Ranks_RankUp:FireServer() end)
            end
        end

        if Toggles.AutoRank and Toggles.AutoRank.Value then
            local handled = false

            for _, g in ipairs(goals) do
                if g.Progress < g.Amount then
                    -- Check if it's an Egg hatching goal (Type == 20)
                    if g.Type == 20 then
                        local bestName, bestNum = GetBestUnlockedEgg()
                        SafeSetText(StatusLabel, "Status: Hatching " .. bestName .. " (#" .. bestNum .. ")")
                        local hatchDelay = (Options.HatchDelaySlider and Options.HatchDelaySlider.Value) or 2.5
                        if tick() - LastHatchTick >= hatchDelay then
                            LastHatchTick = tick()
                            HatchEgg(bestName, 1)
                        end
                        handled = true
                        break
                    elseif g.BreakableType == "Safe" then
                        SafeSetText(StatusLabel, "Status: Crushing Safes (" .. g.Progress .. "/" .. g.Amount .. ")")
                        local targets = FindBreakablesByFilter("safe", 6)
                        if #targets > 0 then
                            for _, t in ipairs(targets) do
                                local uid = t:GetAttribute("BreakableUID") or t.Name
                                for _ = 1, 3 do DamageBreakable(uid) end
                            end
                            handled = true
                            break
                        end
                    elseif g.BreakableType == "Present" then
                        SafeSetText(StatusLabel, "Status: Crushing Presents (" .. g.Progress .. "/" .. g.Amount .. ")")
                        local targets = FindBreakablesByFilter("present", 6)
                        if #targets > 0 then
                            for _, t in ipairs(targets) do
                                local uid = t:GetAttribute("BreakableUID") or t.Name
                                for _ = 1, 3 do DamageBreakable(uid) end
                            end
                            handled = true
                            break
                        end
                    elseif g.Type == 9 then
                        SafeSetText(StatusLabel, "Status: Crushing Diamonds (" .. g.Progress .. "/" .. g.Amount .. ")")
                        local targets = FindBreakablesByFilter("diamond", 6)
                        if #targets > 0 then
                            for _, t in ipairs(targets) do
                                local uid = t:GetAttribute("BreakableUID") or t.Name
                                for _ = 1, 3 do DamageBreakable(uid) end
                            end
                            handled = true
                            break
                        end
                    elseif g.BreakableType == "Coin" or g.Type == 1 then
                        SafeSetText(StatusLabel, "Status: Crushing Coins (" .. g.Progress .. "/" .. g.Amount .. ")")
                        local targets = FindBreakablesByFilter("coin", 8)
                        if #targets > 0 then
                            for _, t in ipairs(targets) do
                                local uid = t:GetAttribute("BreakableUID") or t.Name
                                for _ = 1, 2 do DamageBreakable(uid) end
                            end
                            handled = true
                            break
                        end
                    end
                end
            end

            if not handled then
                SafeSetText(StatusLabel, "Status: AoE Farming objects...")
                local targets = FindBreakablesByFilter("any", 10)
                for _, t in ipairs(targets) do
                    local uid = t:GetAttribute("BreakableUID") or t.Name
                    DamageBreakable(uid)
                end
            end
        else
            SafeSetText(StatusLabel, "Status: Auto Rank Idle")
        end
    end
end)

AddConnection(RunService.Heartbeat:Connect(function()
    if Toggles.WalkSpeedToggle and Toggles.WalkSpeedToggle.Value then
        local _, _, hum = GetCharacter()
        if hum and Options.WalkSpeedSlider then
            hum.WalkSpeed = Options.WalkSpeedSlider.Value
        end
    end
end))

AddConnection(UserInputService.JumpRequest:Connect(function()
    if Toggles.InfiniteJump and Toggles.InfiniteJump.Value then
        local _, _, hum = GetCharacter()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

local ESPTracked = {}
task.spawn(function()
    while Running do
        task.wait(1.5)
        if Toggles.BreakablesESP and Toggles.BreakablesESP.Value and Hub.ESPLibrary then
            local things = Workspace:FindFirstChild("__THINGS")
            local breakables = things and things:FindFirstChild("Breakables")
            if breakables then
                for _, item in ipairs(breakables:GetChildren()) do
                    if item:IsA("Model") or item:IsA("BasePart") then
                        local id = (item:GetAttribute("BreakableID") or item.Name):lower()
                        if id:find("present") or id:find("diamond") or id:find("pinata") or id:find("safe") then
                            if not ESPTracked[item] then
                                ESPTracked[item] = true
                                pcall(function()
                                    Hub.ESPLibrary:AddESP({
                                        Target = item,
                                        Name = item:GetAttribute("BreakableID") or item.Name,
                                        Color = Color3.fromRGB(255, 215, 0),
                                        MaxDistance = 400
                                    })
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

Hub.Interface.ApplySettingsTab(Window)

pcall(function()
    Library:Notify("Open Hub loaded with Nuke Area & Fixed Buttons in " .. math.floor((tick() - LoadStart) * 1000) / 1000 .. "s", 5)
end)
