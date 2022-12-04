local Network = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/Network.lua"))()
local SuffixLib = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/SuffixLib.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local GameNetwork = require(ReplicatedStorage.Modules.Network)
local Microtransactions = require(ReplicatedStorage.Modules.Microtransactions)

local MarketplaceService = game:GetService("MarketplaceService")
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char
	Humanoid = Char:WaitForChild("Humanoid")
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0,0))
end)

hookfunction(Microtransactions.CheckIfOwnsGamepass, function()
    return true
end)

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
local Window = Rayfield:CreateWindow({
    Name = string.format("Project: AlphaZero | %s", GameName),
    LoadingTitle = string.format("Project: AlphaZero | %s", GameName),
    LoadingSubtitle = "By: Kaoru~#6438 and Sw1ndler#7733",
    Discord = {
        Enabled = true,
        Invite = "JdzPVMNFwY",
        RememberJoins = true,
     },
})

local Main = Window:CreateTab('Main')
local Egg = Window:CreateTab('Eggs')
local Credits = Window:CreateTab('Credits')

Main:CreateSection("Auto Collect")

Main:CreateToggle({
    Name = "Auto Collect Orbs";
    CurrentValue = true;
    Callback = function(AutoCollectOrbs)
        if AutoCollectOrbs then
            GameNetwork.send("changesetting", "AutoCollect", "On")
        else
            GameNetwork.send("changesetting", "AutoCollect", "Off")
        end
    end;
})

Main:CreateSection("Auto Win")

local SelectedWorld, SelectedLandSpot = "1", workspace.LandSpots1;
local SelectedWorldToggle = Main:CreateDropdown({
    Name = "Worlds";
    Options = {
        "Normal World",
        "Space",
        "Paradise",
        "Candy",
    };
    CurrentOption = "Select World";
    Callback = function(Option)
        local Worlds = ReplicatedStorage.Worlds:GetChildren()
        local Places = {}

        for Int, World in Worlds do
            local Config = require(World.Config)
            Places[Int] = Config.Title
        end

        for Int, Place in Places do
            if Option == Place then
                SelectedWorld = Int
                SelectedLandSpot = workspace["LandSpots"..Int]
            end
        end
    end;
})

local DynamicWorldToggle;
Main:CreateToggle({
    Name = "Dynamic World";
    CurrentValue = false;
    Callback = function(DynamicWorld)
        DynamicWorldToggle = DynamicWorld
        if DynamicWorld then
            task.spawn(function()
                while DynamicWorldToggle do task.wait(0.05)
                    local ClosestWorld = nil;
                    local ClosestDistance = math.huge;
            
                    for _, World in next, workspace.Worlds:GetChildren() do
                        if World:IsA("Folder") then
                            local Distance = (HumanoidRootPart.Position - World.Launch.Position).Magnitude
                            if Distance < ClosestDistance then
                                ClosestDistance = Distance
                                ClosestWorld = World
                            end
                        end
                    end
            
                    if ClosestWorld then
                        local Worlds = ReplicatedStorage.Worlds:GetChildren()
                        local Places = {}

                        for Int, World in Worlds do
                            local Config = require(World.Config)
                            Places[Int] = Config.Title
                        end

                        for Int, Place in Places do
                            if ClosestWorld.Name == tostring(Int) then
                                SelectedWorldToggle:Set(Place)
                            end
                        end
                    end
                end
            end)
        end            
    end;
})

local AutoWinToggle;
Main:CreateToggle({
    Name = "Auto Win";
    CurrentValue = false;
    Callback = function(AutoWin)
        AutoWinToggle = AutoWin
        if AutoWin then
            task.spawn(function()
                while AutoWinToggle do task.wait()
                    if LocalPlayer.IsFlying.Value then
                        HumanoidRootPart.CFrame = SelectedLandSpot.End.CFrame
                    elseif LocalPlayer.IsFlying.Value == false then
                        HumanoidRootPart.CFrame = workspace.Worlds[SelectedWorld].Launch.CFrame
                    end
                end
            end)
        end
    end;
})

Main:CreateSection("Auto Rebirth")

Main:CreateToggle({
    Name = "Auto Rebirth";
    CurrentValue = true;
    Callback = function(AutoRebirth)
        if AutoRebirth then
            GameNetwork.send("changesetting", "AutoRebirth", "On")
        else
            GameNetwork.send("changesetting", "AutoRebirth", "Off")
        end
    end;
})

Egg:CreateSection("Auto Buy Eggs")

local Eggs = {};
for _, Egg in next, workspace.Eggs:GetChildren() do
    if Egg:IsA("Model") and not table.find(Eggs, Egg.Name) then
        table.insert(Eggs, Egg.Name)
    end
end

local EggPrediction = Egg:CreateLabel(string.format("Eggs you can buy: %s", "Awaiting Toggle..."))

local SelectedEgg = Eggs[1]
Egg:CreateDropdown({
    Name = "Egg";
    Options = Eggs;
    CurrentOption = Eggs[1];
    Callback = function(EggSlected)
        SelectedEgg = EggSlected
        Network:TeleportTo(workspace.Eggs[SelectedEgg].UIanchor.CFrame)
    end;
})

local AutoBuyEggsToggle;
Egg:CreateToggle({
    Name = "Auto Buy Eggs";
    CurrentValue = false;
    Callback = function(AutoBuyEggs)
        AutoBuyEggsToggle = AutoBuyEggs
        if AutoBuyEggs then
            task.spawn(function()
                while AutoBuyEggsToggle do task.wait(1)
                    Network:Invoke(ReplicatedStorage.RemoteEvents.EggOpened, SelectedEgg, "Single")

                    local EggCost = workspace.Eggs[SelectedEgg].PriceBrick.SurfaceGui.Cost
                    local TotalStuds = LocalPlayer.Stats["\xF0\x9F\x8F\x86 Studs"]
                    local CanBuy = math.floor(tonumber(TotalStuds.Value) / SuffixLib:ConvertToNumber(EggCost.Text:split(" ")[2]))

                    EggPrediction:Set(string.format("Eggs you can buy: %s", tostring(SuffixLib:ConvertToSuffix(CanBuy))))

                    if not AutoBuyEggsToggle then
                        EggPrediction:Set(string.format("Eggs you can buy: %s", "Awaiting Toggle..."))
                    end
                end
            end)
        else
            EggPrediction:Set(string.format("Eggs you can buy: %s", "Awaiting Toggle..."))
        end
    end;
})

Egg:CreateSection("Pet Settings")

Egg:CreateToggle({
    Name = "Auto Equip Best";
    CurrentValue = true;
    Callback = function(AutoEquipBest)
        if AutoEquipBest then
            GameNetwork.send("changesetting", "AutoEquipBest", "On")
        else
            GameNetwork.send("changesetting", "AutoEquipBest", "Off")
        end
    end;
})

local AutoCraftToggle;
Egg:CreateToggle({
    Name = "Auto Craft";
    CurrentValue = false;
    Callback = function(AutoCraft)
        AutoCraftToggle = AutoCraft
        if AutoCraft then
            task.spawn(function()
                while AutoCraftToggle do task.wait(1)
                    for _, Pet in next, LocalPlayer.Pets:GetChildren() do
                        if Pet:IsA("Folder") and Pet:WaitForChild("Type").Value == "Normal" then
                            local PetCount = 0;
                            local PetId = {
                                ["PetID"] = nil
                            };

                            for _, Pet2 in next, LocalPlayer.Pets:GetChildren() do
                                if Pet2:IsA("Folder") and Pet2:WaitForChild("Type").Value == "Normal" and Pet2.Name == Pet.Name then
                                    PetCount = PetCount + 1
                                    if PetCount >= 5 then
                                        PetId.PetID = Pet2.PetID.Value
                                        Network:Invoke(ReplicatedStorage.RemoteEvents.PetActionRequest, "Craft", PetId)
                                        PetCount = 0;
                                    end
                                end
                            end

                        end
                    end
                end
            end)
        end
    end;
})

Credits:CreateParagraph({
    Title = "Who made this script?",
    Content = "Main Devs: Kaoru#6438 and Sw1ndler#7733; UI Dev: shlex#9425",
})

Credits:CreateSection('Discord')
Credits:CreateButton({
    Name = 'Join Discord',
    Callback = function()
        Network:SendInvite("JdzPVMNFwY")
    end
})

Rayfield:Notify({
    Title = "Loaded",
    Content = string.format("Successfully Loaded AlphaZero for %s!", GameName),
    Duration = 5,
    Image = 4483362458,
})