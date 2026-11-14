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
    Rank    = Window:AddTab("Real Auto Rank", "trophy"),
    Farm    = Window:AddTab("Auto Farm All", "coins"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Player  = Window:AddTab("Player", "user"),
}

local Groupboxes = {}

Groupboxes.Rank = Tabs.Rank:AddLeftGroupbox("Real Auto Rank")
Groupboxes.Quests = Tabs.Rank:AddRightGroupbox("Real Goals (Save Data)")

Groupboxes.Farm = Tabs.Farm:AddLeftGroupbox("AoE Farm & Free Gifts")
Groupboxes.Eggs = Tabs.Farm:AddRightGroupbox("Eggs & Hatching")

Groupboxes.Visuals = Tabs.Visuals:AddLeftGroupbox("ESP")
Groupboxes.Player = Tabs.Player:AddLeftGroupbox("Movement")

local QuestLabels = {
    Goal1 = Groupboxes.Quests:AddLabel("Goal 1: Loading..."),
    Goal2 = Groupboxes.Quests:AddLabel("Goal 2: Loading..."),
    Goal3 = Groupboxes.Quests:AddLabel("Goal 3: Loading..."),
    RankInfo = Groupboxes.Quests:AddLabel("Rank: Loading..."),
}

local StatusLabel = Groupboxes.Rank:AddLabel("Status: Idle")

Groupboxes.Rank:AddToggle("AutoRank", {
    Text = "Enable Real Auto Rank",
    Default = true,
    Tooltip = "Reads real Save.Goals: hatches latest unlocked egg without rollbacks, breaks Safes, Presents, Diamonds, and auto-levels."
})

Groupboxes.Rank:AddToggle("AutoClaimRank", {
    Text = "Auto Claim Stars & Rewards",
    Default = true,
})

Groupboxes.Rank:AddDivider()

Groupboxes.Rank:AddButton({
    Text = "Claim All Rank Rewards Now",
    Func = function()
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
        Library:Notify("Claimed all rank track rewards & stars!", 4)
    end
})

Groupboxes.Rank:AddButton({
    Text = "Trigger Rank Up Now",
    Func = function()
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

        if curStars >= neededStars then
            Library:Notify("Rank Up request sent! (" .. curStars .. "/" .. neededStars .. " stars)", 4)
        else
            Library:Notify("Need " .. (neededStars - curStars) .. " more stars for next Rank! (" .. curStars .. "/" .. neededStars .. ")", 4)
        end
    end
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

    -- NO TELEPORT BACK! Player stays at egg to avoid server cancel / rollback!
    return success and res
end

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
        if Toggles.AoEFarm and Toggles.AoEFarm.Value then
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
    Library:Notify("Open Hub Real Auto loaded in " .. math.floor((tick() - LoadStart) * 1000) / 1000 .. "s", 5)
end)
