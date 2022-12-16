local FolderName = "AlphaZero/Bee Swarm Simulator";
if not isfolder("AlphaZero") then
    makefolder("AlphaZero")

    if not isfolder("AlphaZero/Bee Swarm Simulator") then
        makefolder("AlphaZero/Bee Swarm Simulator")
    end
end

local Utils = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/AllUtils.lua")))();
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local Humanoid = Character:WaitForChild("Humanoid");
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart");
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local VirtualUser = game:GetService("VirtualUser");
local Camera = workspace.CurrentCamera;

local WebhookSendInfo, WebhookURL = false, nil;
local GotoMethod = "Pathfinding";
local Halt, BeingAttacked = false, false;
local Dead, DeadOldPosition = false, nil;

local GoingBackToPos = false;

local MarketplaceService = game:GetService("MarketplaceService");
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name;

LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char
	Humanoid = Char:WaitForChild("Humanoid")
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")

    Humanoid.Died:Connect(function()
        if WebhookSendInfo then
            Utils.Webhook:Send(WebhookURL, string.format("RIP! Your player: **%s** died.", LocalPlayer.Name));
        end
        Utils.Network:Notify("RIP!", "You died! Respawning in 6 seconds.", 6);
        Dead = true;
    end)
end)

Humanoid.Died:Connect(function()
    if WebhookSendInfo then
        Utils.Webhook:Send(WebhookURL, string.format("RIP! Your player: **%s** died.", LocalPlayer.Name));
    end
    Utils.Network:Notify("RIP!", "You died! Respawning in 6 seconds.", 6);
    Dead = true;
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0,0))
end)

for _, Honeycomb in next, workspace.Honeycombs:GetDescendants() do
    if Honeycomb:IsA("Model") and Honeycomb:FindFirstChild("patharrow") then
        Utils.Network:Send(ReplicatedStorage.Events.ClaimHive, tonumber(Honeycomb.HiveID.Value))
    end
end

workspace.Collectibles:ClearAllChildren();
LocalPlayer:WaitForChild("Honeycomb");

function GetTool()
    local Tool = Character:FindFirstChildOfClass("Tool");

    if Tool and Tool:FindFirstChild("ClickEvent") then
        return Tool;
    end
end

function GetPlayersHive()
    local PlayersHive = nil;
    local HiveName = LocalPlayer.Honeycomb.Value;

    for _, Honeycomb in next, workspace.HivePlatforms:GetChildren() do
        if Honeycomb:FindFirstChild("Hive") and Honeycomb.Hive.Value == HiveName then
            PlayersHive = Honeycomb;
            break;
        end
    end

    return PlayersHive;
end

function GetCollectibles()
    local Collectibles = {};

    for _, Collectible in next, workspace.Collectibles:GetChildren() do
        table.insert(Collectibles, Collectible);
    end

    return Collectibles;
end

function GetClosestCollectible()
    local Collectibles = GetCollectibles();
    local ClosestCollectible = nil;
    local ClosestDistance = 100;

    for _, Collectible in next, Collectibles do
        local Distance = (HumanoidRootPart.Position - Collectible.Position).Magnitude;

        if Distance <= ClosestDistance then
            ClosestCollectible = Collectible;
            ClosestDistance = Distance;
        end
    end

    return ClosestCollectible;
end

function Goto(Position, Wait)
    local Methods = {
        ["Pathfinding"] = function()
            local Distance = (HumanoidRootPart.Position - Position).Magnitude;

            if Distance < 500 then
                Utils.Pathfinding:DrawPath(Position, Wait);
                Utils.Pathfinding:MoveTo(Position, Wait);
            elseif Distance >= 500 then
                Utils.Network:TeleportTo(CFrame.new(Position));
            end
        end;
        ["Teleport"] = function()
            Utils.Network:TeleportTo(CFrame.new(Position));
        end;
        ["Tween"] = function()
            Utils.Pathfinding:DrawPath(Position, Wait);
            Utils.Pathfinding:TweenTo(Position, Wait);
        end;
    };

    Methods[GotoMethod]();
end

function SortFromClosestToFarthest(Areas, From)
    local SortedAreas = {}

    for _, Area in next, Areas do
        table.insert(SortedAreas, {Area, (From.Position - workspace.FlowerZones[Area].Position).Magnitude})
    end

    table.sort(SortedAreas, function(a, b)
        return a[2] < b[2]
    end)

    local NewSortedAreas = {}

    for _, Area in next, SortedAreas do
        table.insert(NewSortedAreas, Area[1])
    end

    return NewSortedAreas
end

function GetMonsters()
    local Monsters = {};
    for _, Monster in next, workspace.Monsters:GetChildren() do
        if Monster:IsA("Model") then
            table.insert(Monsters, Monster);
        end
    end

    return Monsters;
end

function GetClosestMonster()
    local Monsters = GetMonsters();
    local ClosestMonster = nil;
    local ClosestDistance = 125;

    for _, Monster in next, Monsters do
        local Distance = (HumanoidRootPart.Position - Monster:WaitForChild("HumanoidRootPart").Position).Magnitude;

        if Distance < ClosestDistance then
            ClosestMonster = Monster;
            ClosestDistance = Distance;
        end
    end

    return ClosestMonster;
end

local Client = {
    Locals = {
        PollenCapacity = LocalPlayer.CoreStats.Capacity;
        CurrentPollen = LocalPlayer.CoreStats.Pollen;
        CurrentHoney = LocalPlayer.CoreStats.Honey;
        PlayersHive = GetPlayersHive().Circle;
    };
    Arguments = {
        MakeHoney = "ToggleHoneyMaking";
    };
    Remotes = {
        ClickEvent = GetTool().ClickEvent;
        PlayerHiveCommand = ReplicatedStorage.Events.PlayerHiveCommand;
    };
};

Character.ChildAdded:Connect(function(Child)
    if Child:IsA("Tool") then
        Client.Remotes.ClickEvent = Child.ClickEvent;
    end
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

task.spawn(function()
    while true do task.wait()
        if Dead == false then
            DeadOldPosition = HumanoidRootPart.Position;
        end

        if Dead then
            Dead = false;

            if DeadOldPosition ~= nil then
                task.wait(6);

                Client = {
                    Locals = {
                        PollenCapacity = LocalPlayer.CoreStats.Capacity;
                        CurrentPollen = LocalPlayer.CoreStats.Pollen;
                        PlayersHive = GetPlayersHive().Circle;
                    };
                    Arguments = {
                        MakeHoney = "ToggleHoneyMaking";
                    };
                    Remotes = {
                        ClickEvent = GetTool().ClickEvent;
                        PlayerHiveCommand = ReplicatedStorage.Events.PlayerHiveCommand;
                    };
                };

                Utils.Network:Notify("Respawned!", "Going back to old position...", 5);

                if WebhookSendInfo then
                    Utils.Webhook:Send(WebhookURL, "Respawned! Going back to old position...");
                end

                Goto(DeadOldPosition, true)

                Utils.Network:Notify("Yay!", "You're back at your old position!", 5);

                if WebhookSendInfo then
                    Utils.Webhook:Send(WebhookURL, "Yay! You're back at your old position!");
                end
            end

            DeadOldPosition = nil;
        end
    end
end)

local Main = Window:CreateTab('Main')
local AttackTab = Window:CreateTab('Attack')
local Teleport = Window:CreateTab('Teleport')
local Misc = Window:CreateTab('Misc')
local Credits = Window:CreateTab('Credits')

Main:CreateSection('Auto Farming')

local Zones = {};
for _, Zone in next, workspace.FlowerZones:GetChildren() do
    if Zone:IsA("Part") and not table.find(Zones, Zone) then
        table.insert(Zones, Zone.Name);
    end
end

local SortedZones = SortFromClosestToFarthest(Zones, Client.Locals.PlayersHive);

local FarmingTeleport = SortedZones[1];
Main:CreateDropdown({
    Name = "Zone To Farm";
    Options = SortedZones;
    CurrentOption = SortedZones[1];
    Callback = function(ZoneFarm)
        FarmingTeleport = ZoneFarm;
    end;
})

Main:CreateDropdown({
    Name = "Goto Method";
    Options = {"Pathfinding", "Teleport", "Tween"};
    CurrentOption = "Pathfinding";
    Callback = function(Method)
        GotoMethod = Method;
    end;
})

local AutoFarmToggle, GoingToOld = false, false;
Main:CreateToggle({
    Name = "Auto Farm";
    CurrentValue = false;
    Callback = function(AutoFarm)
        AutoFarmToggle = AutoFarm;

        task.spawn(function()
            while AutoFarmToggle do task.wait(1)
                if FarmingTeleport then
                    local Zone = workspace.FlowerZones[FarmingTeleport];
                    local DistanceFrom = (HumanoidRootPart.Position - Zone.Position).Magnitude;

                    if DistanceFrom > 150 and (Halt == false and GoingToOld == false and GoingBackToPos == false) then
                        Halt = true;

                        if WebhookSendInfo then
                            Utils.Webhook:Send(WebhookURL, "We've noticed that you aren't at your selected farming zone... Teleporting now.")
                        end
                        Utils.Network:Notify("???", "We've noticed that you aren't at your selected farming zone... Teleporting now.", 5)

                        Goto(Zone.Position, true)

                        if WebhookSendInfo then
                            Utils.Webhook:Send(WebhookURL, "You're now back at your selected farming zone.")
                        end
                        Utils.Network:Notify("Yay!", "You're now back at your selected farming zone.", 5)

                        Halt = false;
                    end
                end
            end
        end)
    end;
})

local GotoCollectable = false;
Main:CreateToggle({
    Name = "Goto Collectable";
    CurrentValue = false;
    Callback = function(GotoCollectableToggle)
        GotoCollectable = GotoCollectableToggle;

        task.spawn(function()
            while GotoCollectable do task.wait()
                local Collectable = GetClosestCollectible();

                if Humanoid.WalkSpeed ~= 46 then
                    Humanoid.WalkSpeed = 46;
                end

                if Collectable then
                    local Distance = (HumanoidRootPart.Position - Collectable.Position).Magnitude;

                    if Distance <= 25 and (Halt == false and GoingBackToPos == false) then
                        Goto(Collectable.Position, false);
                    end
                end

                if not GotoCollectable then
                    Humanoid.WalkSpeed = 23;
                    break;
                end
            end
        end)
    end;
})

function TableToString(Table)
    local String = "";

    for Index, Value in next, Table do
        if Index == #Table then
            String = string.format("%s%s, ", String, Value);
        else
            String = string.format("%s%s, ", String, Value);
        end
    end

    return String;
end

local Averages = {
    ["Honey"] = {};
};

function AverageHoney()
    local Honey = 0;

    for _, HoneyAmount in next, Averages["Honey"] do
        Honey = Honey + HoneyAmount;
    end

    return Honey / #Averages["Honey"];
end

task.spawn(function()
    if isfile(string.format("%s/Honey.txt", FolderName)) then
        local HoneyTable = readfile(string.format("%s/Honey.txt", FolderName));

        if HoneyTable == "{}" then
            return;
        end

        Utils.Network:Notify("File Found!", "Found a file with honey averages!", 5);

        for _, Content in next, {HoneyTable} do
            local NewString = Content:gsub("{", ""):gsub("}", ""):split(",")
            for _, Number in next, NewString do
                table.insert(Averages["Honey"], tonumber(Number));
            end
        end
    end
end)

local AutoMakeHoney, HoneyOldPosition = false, nil;
Main:CreateToggle({
    Name = "Auto Make Honey";
    CurrentValue = false;
    Callback = function(AutoMakeHoneyToggle)
        AutoMakeHoney = AutoMakeHoneyToggle;

        task.spawn(function()
            while AutoMakeHoney do task.wait(0.1)
                local CurrentPollen = tonumber(Client.Locals.CurrentPollen.Value);
                local PollenCapacity = tonumber(Client.Locals.PollenCapacity.Value);

                if CurrentPollen >= PollenCapacity then
                    local Distance = (HumanoidRootPart.Position - Client.Locals.PlayersHive.Position).Magnitude;
                    local MakeHoney = PlayerGui.ScreenGui.ActivateButton;
                    Halt = true;

                    if Distance <= 5 and MakeHoney.TextBox.Text ~= "Stop Making Honey" then
                        Halt = true;

                        if WebhookSendInfo then
                            Utils.Webhook:Send(WebhookURL, "Making honey...");
                        end

                        Utils.Network:Send(Client.Remotes.PlayerHiveCommand, Client.Arguments.MakeHoney)
                        task.wait(5);
                    elseif Distance > 10 then
                        HoneyOldPosition = HumanoidRootPart.Position;

                        Halt = true;

                        if WebhookSendInfo then
                            Utils.Webhook:Send(WebhookURL, "Going to your hive...");
                        end

                        Goto(Client.Locals.PlayersHive.Position, true);
                    end
                end
            end
        end)

        task.spawn(function()
            while AutoMakeHoney do task.wait(0.1)
                local CurrentPollen = tonumber(Client.Locals.CurrentPollen.Value);

                if CurrentPollen == 0 and HoneyOldPosition and Halt then

                    pcall(function()
                        table.insert(Averages["Honey"], Utils.Suffix:ConvertFromSN(Client.Locals.CurrentHoney.Value));
                    end)
                    workspace.Collectibles:ClearAllChildren();

                    Halt = false;
                    GoingToOld = true;

                    if WebhookSendInfo then
                        Utils.Webhook:Send(WebhookURL, string.format("Finished making honey! Average honey you are making: *%s*.\nGoing back to old position...",
                            AverageHoney()
                        ));
                    end

                    Goto(HoneyOldPosition, true);

                    if WebhookSendInfo then
                        Utils.Webhook:Send(WebhookURL, "Finished going back to old position!");
                    end

                    GoingToOld = false;
                    HoneyOldPosition = nil;
                end
            end
        end)
    end;
})

local AutoCollectFlowers = false;
Main:CreateToggle({
    Name = "Auto Collect Pollen";
    CurrentValue = false;
    Callback = function(AutoCollectFlowersToggle)
        AutoCollectFlowers = AutoCollectFlowersToggle;

        task.spawn(function()
            while AutoCollectFlowers do task.wait(0.1)
                if Halt == false then
                    Utils.Network:Send(Client.Remotes.ClickEvent, Client.Arguments.MakeHoney);
                end
            end
        end)
    end;
})

AttackTab:CreateSection('Attack Handling')

local AttackInfo = AttackTab:CreateLabel("Current Monster(s) Attacking: Awaiting Toggle...")

local GetAttackInfo = false;
AttackTab:CreateToggle({
    Name = "Attack Info";
    CurrentValue = false;
    Callback = function(AutoAttackToggle)
        GetAttackInfo = AutoAttackToggle;

        task.spawn(function()
            while GetAttackInfo do task.wait(0.1)
                local Monsters = GetMonsters();

                if #Monsters > 0 then
                    local EnemyMonsters = {};

                    for _, Monster in next, Monsters do
                        if Monster:FindFirstChild("HumanoidRootPart") then
                            local Target = Monster:WaitForChild("Target");

                            if tostring(Target.Value) == tostring(LocalPlayer.Name) then
                                table.insert(EnemyMonsters, Monster.Name);
                            end
                        end
                    end

                    if #EnemyMonsters > 0 then
                        AttackInfo:Set(string.format("Current Monster(s) Attacking: %s", table.concat(EnemyMonsters, ", ")));
                    else
                        AttackInfo:Set("Current Monster(s) Attacking: None");
                    end
                else
                    AttackInfo:Set("Current Monster(s) Attacking: Awaiting Monster To Spawn...");
                end

                if not GetAttackInfo then
                    AttackInfo:Set("Current Monster(s) Attacking: Awaiting Toggle...");
                    break;
                end
            end
        end)
    end;
})

-- local AutoAttack = false;
-- AttackTab:CreateToggle({
--     Name = "Auto Attack";
--     CurrentValue = false;
--     Callback = function(AutoAttackToggle)
--         AutoAttack = AutoAttackToggle;

--         task.spawn(function()
--             while AutoAttack do task.wait()
--                 local ClosestMonster = GetClosestMonster();

--                 if ClosestMonster then
--                     local Distance = (HumanoidRootPart.Position - ClosestMonster:WaitForChild("HumanoidRootPart").Position).Magnitude;

--                     if Distance <= 50 then
--                         BeingAttacked = true;

--                         if Humanoid.WalkSpeed ~= 46 then
--                             Humanoid.WalkSpeed = 46;
--                         end

--                         for i = 1, 360, 10 do
--                             local Angle = math.rad(i);
--                             local NewDirection = Vector3.new(math.cos(Angle), 0, math.sin(Angle));
--                             local NewPosition = ClosestMonster:WaitForChild("HumanoidRootPart").Position + (NewDirection * 30);

--                             Goto(NewPosition, false);
--                         end
--                     else
--                         BeingAttacked = false;
--                     end
--                 else
--                     BeingAttacked = false;
--                 end

--                 if not AutoAttack then
--                     BeingAttacked = false;

--                     Humanoid.WalkSpeed = 23;
--                     break;
--                 end
--             end
--         end)
--     end;
-- })

Teleport:CreateSection('Zones')

local ZoneTeleport = SortedZones[1];
Teleport:CreateDropdown({
    Name = "Zone";
    Options = SortedZones;
    CurrentOption = SortedZones[1];
    Callback = function(Zone)
        ZoneTeleport = Zone;
    end;
})

Teleport:CreateButton({
    Name = "Teleport";
    Callback = function()
        local Zone = workspace.FlowerZones[ZoneTeleport];
        
        if Zone then

            if Humanoid.WalkSpeed ~= 46 then
                Humanoid.WalkSpeed = 46;
            end

            Utils.Network:Notify("Cool!", string.format("Teleporting to %s...", Zone.Name));

            if WebhookSendInfo then
                Utils.Webhook:Send(WebhookURL, string.format("Teleporting to %s...", Zone.Name));
            end

            Goto(Zone.Position, true);

            Utils.Network:Notify("Yay!", string.format("You're now at %s!", Zone.Name));

            if WebhookSendInfo then
                Utils.Webhook:Send(WebhookURL, string.format("You're now at %s!", Zone.Name));
            end

            Humanoid.WalkSpeed = 23;
        end
    end;
})

Misc:CreateSection('Walkspeed')

Misc:CreateSlider({
    Name = "Walkspeed";
    Range = {23, 1000};
    Increment = 1;
    Suffix = "Studs";
    CurrentValue = 23;
    Callback = function(WalkspeedSlider)
        Humanoid.WalkSpeed = tonumber(WalkspeedSlider);
    end;
})

Misc:CreateSection('Jump Power')

Misc:CreateSlider({
    Name = "Jump Power";
    Range = {50, 1000};
    Increment = 1;
    Suffix = "Studs";
    CurrentValue = 50;
    Callback = function(JumpPowerSlider)
        Humanoid.JumpPower = tonumber(JumpPowerSlider);
    end;
})

Misc:CreateSection('Webhook')

local WebhookStatus = Misc:CreateLabel("Webhook Status: Webhook Not Set!")

local Webhook, Exists = Utils.Webhook:LoadWebhook(string.format("%s/SavedWebhook.txt", FolderName));
if Exists then
    WebhookURL = Webhook;
    WebhookStatus:Set("Webhook Status: Webhook Set!")
end

Misc:CreateInput({
    Name = "Webhook URL";
    PlaceholderText = "Webhook URL Here: (Remeber To Press Enter!)";
    RemoveTextAfterFocusLost = false;
    Callback = function(WebhookURLInput)
        if WebhookURLInput:match("https://discord.com/api/webhooks/%d+/%w+") then
            WebhookURL = WebhookURLInput;
            WebhookStatus:Set("Webhook Status: Webhook Set!")
            Utils.Network:Notify("Success", "Webhook Set!", 5)
        else
            Utils.Network:Notify("Error", "Invalid Webhook URL!", 5)
        end
    end;
})

Misc:CreateButton({
    Name = "Send Test Webhook";
    Callback = function()
        Utils.Webhook:Send(WebhookURL, "This is a test!")
    end;
})

Misc:CreateSection('Webhook Settings')

Misc:CreateButton({
    Name = "Save Webhook";
    Callback = function()
        Utils.Webhook:SaveWebhook(FolderName, WebhookURL)
    end;
})

Misc:CreateToggle({
    Name = "Use @everyone";
    CurrentValue = false;
    Callback = function(WebhookEveryoneToggle)
        Utils.Webhook:ChangeSettings("@everyone", WebhookEveryoneToggle);
    end;
})

function DashAdder(Number)
    local Dash = ""
    for _ = 1, Number do
        Dash ..= "-"
    end
    return Dash
end

Misc:CreateToggle({
    Name = "Send Info On Important Events";
    CurrentValue = false;
    Callback = function(WebhookSendInfoToggle)
        WebhookSendInfo = WebhookSendInfoToggle;

        if WebhookSendInfoToggle == true then
            Utils.Webhook:Send(WebhookURL, string.format("%s\nConnected on *%s*, Webhook has been toggled on!", DashAdder(197), game.JobId))
        else
            Utils.Webhook:Send(WebhookURL, "**Webhook has been toggled off!**")
        end;
    end;
})

Misc:CreateInput({
    Name = "Change Webhook Name";
    PlaceholderText = "Remeber To Press Enter!";
    RemoveTextAfterFocusLost = false;
    Callback = function(WebhookNameInput)
        Utils.Webhook:ChangeName(WebhookURL, WebhookNameInput);

        if WebhookSendInfo then
            Utils.Webhook:Send(WebhookURL, string.format("Webhook name has been changed to %s!", WebhookNameInput));
        end
    end;
})

Misc:CreateSection('Other')

Misc:CreateButton({
    Name = "Destroy GUI";
    Callback = function()
        Rayfield:Destroy();
    end;
})

Credits:CreateSection('Credits')

Credits:CreateParagraph({
    Title = "Who made this script?",
    Content = "Main Devs: Kaoru#6438 and Sw1ndler#7733; UI Dev: shlex#9425",
})

Credits:CreateSection('Discord')
Credits:CreateButton({
    Name = 'Join Discord',
    Callback = function()
        Utils.Network:SendInvite("JdzPVMNFwY")
    end;
})

Utils.Network:Notify("Loaded", string.format("Successfully Loaded AlphaZero for %s!", GameName), 5)

task.spawn(function()
    local StoredNumberHoney = 0;

    while true do task.wait(5)
        if #Averages["Honey"] > StoredNumberHoney then
            StoredNumberHoney = #Averages["Honey"]

            writefile(string.format("%s/Honey.txt", FolderName), TableToString(Averages["Honey"]))
        end
    end
end)