local Network = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/Network.lua"))()
local SuffixLib = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/SuffixLib.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = {
    Remotes = {
        MineEvent = ReplicatedStorage.Remotes.mineEvent,
        JoinEvent = ReplicatedStorage.Remotes.joinEvent,
        RequestLeave = ReplicatedStorage.Remotes.requestLeave,
        UpgradeEvent = ReplicatedStorage.Remotes.upgradeEvent,
        RequestEgg = ReplicatedStorage.Remotes.requestEgg,
        PickaxeEvent = ReplicatedStorage.Remotes.pickaxeEvent,
    },
    PlayerData = {
        PickaxeData = LocalPlayer.Data.Pickaxes,
        CoinsData = LocalPlayer.Data.Coins,
        WinsData = LocalPlayer.Data.Wins,
    },
    Frames = {
        LeaveFrame = PlayerGui.UIs.UIs.readyFrame.Leave,
        MineFrame = PlayerGui.UIs.UIs.upgradeFrame.mineFrame,
        PickaxeFrame = PlayerGui.UIs.UIs.upgradeFrame.pickaxeFrame,
    },
    Upgrades = {
        "Cooldown";
        "Dig";
    },
}

local Eggs = {};
for _, Egg in next, PlayerGui.UIs.Eggs:GetChildren() do
    if Egg:IsA("BillboardGui") and not string.match(Egg.Name, "-") then
        table.insert(Eggs, Egg.TextLabel.Text)
    end
end

table.sort(Eggs, function(a, b)
    return SuffixLib:ConvertToNumber(a) < SuffixLib:ConvertToNumber(b)
end)

local Pickaxes = {};
for _, Pickaxe in next, PlayerGui.UIs.UIs.inventoryFrame.ScrollingFrame:GetChildren() do
    if Pickaxe:IsA("ImageLabel") then
        table.insert(Pickaxes, Pickaxe.TextLabel.Text)
    end
end

function GetEgg(Egg)
    for i = 1, #Eggs do
        if Eggs[i] == Egg then
            return tostring(i - 1)
        end
    end
end

local MarketplaceService = game:GetService("MarketplaceService")
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
local Window = Rayfield:CreateWindow({
    Name = GameName,
    LoadingTitle = GameName,
    LoadingSubtitle = "By: Kaoru~#6438",
    Discord = {
        Enabled = true,
        Invite = "JdzPVMNFwY",
        RememberJoins = true,
     },
})

local Main = Window:CreateTab('Main')
Main:CreateSection('Auto Mine')

Main:CreateToggle({
    Name = 'Auto Mine',
    Callback = function(AutoMine)
        shared.AutoMine = AutoMine
        if AutoMine then
            task.spawn(function()
                while shared.AutoMine do task.wait(0.1)
                    if Client.Frames.LeaveFrame.Visible == false then
                        Network:Send(Client.Remotes.JoinEvent, "Join")
                    elseif Client.Frames.LeaveFrame.Visible then
                        Network:Send(Client.Remotes.MineEvent, "Mine")
                    end
                end
            end)
        else
            Network:Send(Client.Remotes.RequestLeave, "LEAVE")
        end
    end
})

Main:CreateSection('Auto Upgrade')

Main:CreateToggle({
    Name = 'Auto Buy Upgrades',
    Callback = function(AutoUpgrade)
        shared.AutoUpgrade = AutoUpgrade
        if AutoUpgrade then
            task.spawn(function()
                while shared.AutoUpgrade do task.wait(0.5)
                    for _, Upgrade in next, Client.Upgrades do
                        Network:Send(Client.Remotes.UpgradeEvent, Upgrade)
                    end
                end
            end)
        end
    end
})

Main:CreateSection('Auto Equip')

Main:CreateToggle({
    Name = 'Auto Equip Best Pickaxe',
    Callback = function(AutoEquip)
        shared.AutoEquip = AutoEquip
        if AutoEquip then
            task.spawn(function()
                while shared.AutoEquip do task.wait(0.5)
                    local Best = 0
                    for _, Pickaxe in next, Client.PlayerData.PickaxeData:GetChildren() do
                        local PickaxeNum = tonumber(Pickaxe.Name)
                        if PickaxeNum > Best then
                            Best = PickaxeNum
                        end
                    end
                    Pickaxe = Client.PlayerData.PickaxeData[tostring(Best)]
                    Network:Send(Client.Remotes.PickaxeEvent, "EQUIP", Pickaxe)
                end
            end)
        end
    end
})

local Egg = Window:CreateTab('Eggs')
Egg:CreateSection('Auto Buy Eggs')

Egg:CreateDropdown({
    Name = 'Egg',
    Options = Eggs,
    CurrentOption = Eggs[1],
    Callback = function(Egg)
        shared.Egg = Egg
    end
})

Egg:CreateToggle({
    Name = 'Auto Buy Egg',
    Callback = function(AutoBuyEgg)
        shared.AutoBuyEgg = AutoBuyEgg
        shared.Egg = shared.Egg or Eggs[1]
        if AutoBuyEgg then
            task.spawn(function()
                while shared.AutoBuyEgg do task.wait(0.5)
                    local Egg = GetEgg(shared.Egg)
                    Network:Send(Client.Remotes.RequestEgg, "Open", workspace.Eggs[tostring(Egg)])
                end
            end)
        end
    end
})

local Obby = Window:CreateTab('Obby')
Obby:CreateSection('Complete Obby')

Obby:CreateButton({
    Name = 'Complete Obby',
    Callback = function()
        for _, Obby in next, workspace:GetChildren() do
            local OldPos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
            if Obby:FindFirstChild("ProximityPrompt") then
                if Obby.Name ~= "RewardsChest" then
                    Network:TeleportTo(Obby.CFrame)
                    task.wait(0.25)
                    fireproximityprompt(Obby.ProximityPrompt)
                    task.wait(0.25)
                end
            end
            Network:TeleportTo(OldPos)
        end
    end
})

Rayfield:Notify({
    Title = "Loaded",
    Content = string.format("Successfully Loaded AlphaZero for %s!", GameName),
    Duration = 5,
    Image = 4483362458,
})
