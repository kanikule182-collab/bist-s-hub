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
    Rank    = Window:AddTab("Auto Rank", "trophy"),
    Farm    = Window:AddTab("Farming", "coins"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Player  = Window:AddTab("Player", "user"),
}

local Groupboxes = {}

Groupboxes.Rank = Tabs.Rank:AddLeftGroupbox("Auto Rank")
Groupboxes.Quests = Tabs.Rank:AddRightGroupbox("Active Quests")

Groupboxes.Farm = Tabs.Farm:AddLeftGroupbox("Auto Farm")
Groupboxes.Eggs = Tabs.Farm:AddRightGroupbox("Eggs & Hatching")

Groupboxes.Visuals = Tabs.Visuals:AddLeftGroupbox("ESP")
Groupboxes.Player = Tabs.Player:AddLeftGroupbox("Movement")

local QuestLabels = {
    Hard = Groupboxes.Quests:AddLabel("Hard: Loading..."),
    Medium = Groupboxes.Quests:AddLabel("Medium: Loading..."),
    Easy = Groupboxes.Quests:AddLabel("Easy: Loading..."),
}

local StatusLabel = Groupboxes.Rank:AddLabel("Status: Idle")

Groupboxes.Rank:AddToggle("AutoRank", {
    Text = "Enable Auto Rank",
    Default = false,
    Tooltip = "Automatically solves rank quests, hatches required eggs, breaks targets, and levels up."
})

Groupboxes.Rank:AddToggle("AutoClaimRank", {
    Text = "Auto Claim Stars & Rewards",
    Default = true,
    Tooltip = "Continuously claims stars and rank-up progression."
})

Groupboxes.Rank:AddDivider()

Groupboxes.Rank:AddButton({
    Text = "Claim All Rank Rewards",
    Tooltip = "Fires Ranks_ClaimAll to claim all available stars and items.",
    Func = function()
        if Network and Network:FindFirstChild("Ranks_ClaimAll") then
            Network.Ranks_ClaimAll:FireServer()
            Library:Notify("Claimed all rank rewards!", 3)
        end
    end
})

Groupboxes.Rank:AddButton({
    Text = "Trigger Rank Up",
    Tooltip = "Attempts to rank up if star requirements are met.",
    Func = function()
        if Network and Network:FindFirstChild("Ranks_RankUp") then
            Network.Ranks_RankUp:FireServer()
            Library:Notify("Fired Rank Up request!", 3)
        end
    end
})

Groupboxes.Farm:AddToggle("AutoFarm", {
    Text = "Auto Farm Breakables",
    Default = false,
    Tooltip = "Rapidly deals damage to breakables around the character."
})

Groupboxes.Farm:AddToggle("AutoCollect", {
    Text = "Auto Collect Orbs & Lootbags",
    Default = true,
    Tooltip = "Magnetizes all dropped coins, gems, and lootbags directly to you."
})

Groupboxes.Farm:AddToggle("AutoEquipBest", {
    Text = "Auto Equip Best Pets",
    Default = true,
    Tooltip = "Periodically equips your strongest pets."
})

Groupboxes.Eggs:AddToggle("AutoHatch", {
    Text = "Auto Hatch Eggs",
    Default = false,
    Tooltip = "Continuously buys and hatches the selected egg."
})

Groupboxes.Eggs:AddDropdown("EggSelect", {
    Text = "Select Egg",
    Values = { "Cracked Egg", "Spotted Egg", "Wood Egg", "Grass Egg", "Stone Egg" },
    Default = 1,
    Multi = false,
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
    Tooltip = "Highlights Presents, Safes, Pinatas, and Diamond Piles."
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

local function GetQuestsList()
    local quests = {}
    local holder = LocalPlayer.PlayerGui:FindFirstChild("GoalsSide")
    local qHolder = holder and holder:FindFirstChild("QuestsHolder", true)
    if not qHolder then return quests end

    for _, child in ipairs(qHolder:GetChildren()) do
        if child:IsA("GuiObject") and child.Visible then
            local title = child:FindFirstChild("Title", true) or child:FindFirstChild("TextLabel", true)
            local progress = child:FindFirstChild("Progress", true) or child:FindFirstChild("Amount", true)
            table.insert(quests, {
                Name = child.Name,
                Title = title and title.Text or "",
                Progress = progress and progress.Text or "",
                Lower = (title and title.Text:lower()) or ""
            })
        end
    end
    return quests
end

local function FindBreakableByFilter(filter)
    local things = Workspace:FindFirstChild("__THINGS")
    local breakables = things and things:FindFirstChild("Breakables")
    if not breakables then return nil end

    local char, root = GetCharacter()
    local rootPos = root and root.Position or Vector3.zero

    local bestItem = nil
    local bestDist = math.huge

    for _, item in ipairs(breakables:GetChildren()) do
        local id = (item:GetAttribute("BreakableID") or item.Name):lower()
        local matches = false

        if filter == "diamond" then
            matches = id:find("diamond") or id:find("gem")
        elseif filter == "present" then
            matches = id:find("present")
        elseif filter == "pinata" then
            matches = id:find("pinata")
        elseif filter == "safe" then
            matches = id:find("safe")
        elseif filter == "coin" then
            matches = id:find("coin") or id:find("crate")
        elseif filter == "any" then
            matches = true
        end

        if matches then
            local pos = item:GetPivot().Position
            local d = (pos - rootPos).Magnitude
            if d < bestDist then
                bestDist = d
                bestItem = item
            end
        end
    end

    return bestItem
end

local function HatchEgg(eggName, count)
    if not Network or not Network:FindFirstChild("Eggs_RequestPurchase") then return false end
    count = math.clamp(count or 1, 1, 3)
    eggName = eggName or "Cracked Egg"

    local eggCapsule = Workspace.__THINGS:FindFirstChild("Eggs") and Workspace.__THINGS.Eggs:FindFirstChild("Main") and Workspace.__THINGS.Eggs.Main:FindFirstChild("1 - Egg Capsule")
    local targetPos = eggCapsule and eggCapsule:GetPivot().Position or Vector3.new(95, 21, -155)

    local char, root = GetCharacter()
    if not root then return false end

    local oldPos = root.CFrame
    root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 4))
    task.wait(0.18)

    local success, res = pcall(function()
        return Network.Eggs_RequestPurchase:InvokeServer(eggName, count)
    end)

    task.wait(0.12)
    root.CFrame = oldPos
    return success and res
end

task.spawn(function()
    while Running do
        task.wait(0.4)
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
        task.wait(0.25)
        if Toggles.AutoFarm and Toggles.AutoFarm.Value then
            local target = FindBreakableByFilter("any")
            if target then
                local uid = target:GetAttribute("BreakableUID") or target.Name
                DamageBreakable(uid)
            end
        end
    end
end)

task.spawn(function()
    while Running do
        task.wait(6)
        if Toggles.AutoEquipBest and Toggles.AutoEquipBest.Value then
            if Network and Network:FindFirstChild("Pets_EquipBest") then
                pcall(function() Network.Pets_EquipBest:FireServer() end)
            end
        end
    end
end)

task.spawn(function()
    while Running do
        task.wait(0.8)
        if Toggles.AutoHatch and Toggles.AutoHatch.Value then
            local eggName = (Options.EggSelect and Options.EggSelect.Value) or "Cracked Egg"
            local amt = (Options.HatchAmount and Options.HatchAmount.Value) or 1
            HatchEgg(eggName, amt)
        end
    end
end)

task.spawn(function()
    while Running do
        task.wait(0.7)
        local quests = GetQuestsList()

        if QuestLabels.Hard then
            QuestLabels.Hard:SetText("Hard: " .. (quests[1] and (quests[1].Title .. " (" .. quests[1].Progress .. ")") or "Completed"))
        end
        if QuestLabels.Medium then
            QuestLabels.Medium:SetText("Medium: " .. (quests[2] and (quests[2].Title .. " (" .. quests[2].Progress .. ")") or "Completed"))
        end
        if QuestLabels.Easy then
            QuestLabels.Easy:SetText("Easy: " .. (quests[3] and (quests[3].Title .. " (" .. quests[3].Progress .. ")") or "Completed"))
        end

        if Toggles.AutoClaimRank and Toggles.AutoClaimRank.Value then
            if Network then
                if Network:FindFirstChild("Ranks_ClaimAll") then
                    pcall(function() Network.Ranks_ClaimAll:FireServer() end)
                end
                if Network:FindFirstChild("Ranks_RankUp") then
                    pcall(function() Network.Ranks_RankUp:FireServer() end)
                end
            end
        end

        if Toggles.AutoRank and Toggles.AutoRank.Value then
            StatusLabel:SetText("Status: Analyzing quests...")

            local handled = false
            for _, q in ipairs(quests) do
                local text = q.Lower

                if text:find("hatch") or text:find("egg") then
                    StatusLabel:SetText("Status: Hatching eggs for quest...")
                    HatchEgg("Cracked Egg", 1)
                    handled = true
                    break
                elseif text:find("present") then
                    StatusLabel:SetText("Status: Targeting Presents...")
                    local p = FindBreakableByFilter("present")
                    if p then
                        local uid = p:GetAttribute("BreakableUID") or p.Name
                        for _ = 1, 4 do DamageBreakable(uid) end
                        handled = true
                        break
                    end
                elseif text:find("diamond") or text:find("gem") then
                    StatusLabel:SetText("Status: Targeting Diamonds...")
                    local d = FindBreakableByFilter("diamond")
                    if d then
                        local uid = d:GetAttribute("BreakableUID") or d.Name
                        for _ = 1, 4 do DamageBreakable(uid) end
                        handled = true
                        break
                    end
                elseif text:find("coin") or text:find("break") then
                    StatusLabel:SetText("Status: Breaking coins/breakables...")
                    local c = FindBreakableByFilter("coin") or FindBreakableByFilter("any")
                    if c then
                        local uid = c:GetAttribute("BreakableUID") or c.Name
                        for _ = 1, 4 do DamageBreakable(uid) end
                        handled = true
                        break
                    end
                elseif text:find("unlock") or text:find("area") or text:find("zone") then
                    StatusLabel:SetText("Status: Requesting zone unlock...")
                    if Network and Network:FindFirstChild("Zones_RequestPurchase") then
                        pcall(function()
                            Network.Zones_RequestPurchase:InvokeServer("Colorful Forest")
                            Network.Zones_RequestPurchase:InvokeServer("Castle")
                        end)
                    end
                    handled = true
                    break
                end
            end

            if not handled then
                StatusLabel:SetText("Status: Farming nearby objects...")
                local target = FindBreakableByFilter("any")
                if target then
                    local uid = target:GetAttribute("BreakableUID") or target.Name
                    DamageBreakable(uid)
                end
            end
        else
            StatusLabel:SetText("Status: Auto Rank Idle")
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
end)

Hub.Interface.ApplySettingsTab(Window)

pcall(function()
    Library:Notify("Open Hub loaded for Pet Simulator 99 in " .. math.floor((tick() - LoadStart) * 1000) / 1000 .. "s", 5)
end)
