local StartTick = tick();

if not game:IsLoaded() then game.Loaded:Wait() end

local function RemoveExtraSpaces(String)
    local NewString = "";
    local LastChar = "";

    for i = 1, #String do
        local Char = String:sub(i, i);

        if Char ~= " " or LastChar ~= " " then
            NewString = NewString .. Char;
        end

        LastChar = Char;
    end

    return NewString;
end

local WaitCache = {};
local function GetChild(ChildName, Parent, Timeout)
    local Key = Parent:GetDebugId(99999) .. ChildName;

    if not WaitCache[Key] then
        WaitCache[Key] = Parent:FindFirstChild(ChildName) or Parent:WaitForChild(ChildName, Timeout);
    end

    return WaitCache[Key];
end

local Linoria = "https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/";

local Library = loadstring(game:HttpGet((Linoria .. 'Library.lua')))();

if not ScriptLoaded then
    Library:Notify("Loading Script...");
end

local ThemeManager = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/Theme%20Manager.lua")))();
local SaveManager = loadstring(game:HttpGet(Linoria .. 'addons/SaveManager.lua'))()

local GameName = RemoveExtraSpaces(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name);
local LocalPlayer = game:GetService("Players").LocalPlayer;
local Entity, OldFuncs = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/EntityLib.lua")))();
local VirtualUser = game:GetService("VirtualUser");

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController();
    VirtualUser:ClickButton2(Vector2.new(0,0));
end)

local Client = {
    Server = game:GetService("ReplicatedStorage").Remotes.Server;

    Locals = {
        ["Teleport Method"] = "Normal";
        ["Get Closest Method"] = "Closest"; 
        ["Egg"] = "Pyecy Village";
        ["Custom Enemy"] = nil;
        ["Attacking Meteor"] = false;
        ["Worlds"] = {};
        ["Attacking Boss"] = false;
        ["Boss Worlds"] = {};
    };

    Suffixes = {
        "K",
        "M",
        "B",
        "T",
        "Qd",
        "Qn",
        "Sx",
        "Sp",
        "O",
        "N",
        "D",
        "Ud",
        "Dd",
        "Td",
        "Qdd",
        "Qnd",
        "Sxd",
        "Spd",
        "Od",
        "Nd",
        "V",
        "Uv",
        "Dv",
        "Tv",
        "Qdv",
        "Qnv",
        "Sxv",
        "Spv",
        "Ov",
        "Nv",
        "Tr",
        "Ut",
        "Dt",
        "Tt",
        "Qdt",
        "Qnt",
        "Sxt",
        "Spt",
        "Ot",
        "Nt"
    };
};

local function ConvertToNumber(String)
    local Suffix = string.match(String, "%a+");
    local Number = string.gsub(String, "%a+", "");
    local Suffixes = Client.Suffixes;

    if not Suffix then
        return tonumber(Number);
    end

    for i = 1, #Suffixes do
        if Suffixes[i]:lower() == Suffix:lower() then
            return tonumber(Number) * 1000 ^ i;
        end
    end
end

local function ConvertToSuffix(Number)
    local Number = tonumber(Number);
    local Suffixes = Client.Suffixes;

    if Number < 1000 then
        return Number;
    end

    local Suffix = Suffixes[math.floor(math.log(Number) / math.log(1000))];

    return string.format("%.2f", Number / 1000 ^ math.floor(math.log(Number) / math.log(1000))) .. Suffix;
end

local function IsVector3(Value)
    return typeof(Value) == "Vector3";
end

local function IsCFrame(Value)
    return typeof(Value) == "CFrame";
end

local function IsInstance(Value)
    return typeof(Value) == "Instance";
end

local function GetNearestValue(Number, Range)
    local SmallestSoFar, SmallestIndex = nil, nil;

    if IsVector3(Number) or IsCFrame(Number) then
        for Index, Value in ipairs(Range) do
            if not SmallestSoFar or (Number - Value).Magnitude < SmallestSoFar then
                SmallestSoFar = (Number - Value).Magnitude;
                SmallestIndex = Index;
            end
        end

        return SmallestIndex, Range[SmallestIndex];
    end

    for Index, Value in ipairs(Range) do
        if not SmallestSoFar or (math.abs(Number - Value) < SmallestSoFar) then
            SmallestSoFar = math.abs(Number - Value);
            SmallestIndex = Index;
        end
    end

    return SmallestIndex, Range[SmallestIndex];
end

local Utilities = {}; do
    function Utilities:GetEntityNames()
        local Entities = Entity.entityList;
        local EntityNames = {};

        for _, Ent in ipairs(Entities) do
            table.insert(EntityNames, Ent.Player.Name);
        end

        return EntityNames;
    end

    function Utilities:IsAlive(Player, StateCheck)
        if not Player then
            return Entity.isAlive;
        end

        if StateCheck == nil then
            StateCheck = true;
        end

        if table.find(self:GetEntityNames(), Player.Name) then
            local _, Ent = Entity.getEntityFromPlayer(Player);

            return ((not StateCheck) or Ent and Ent.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and Ent;
        else
            return ((not StateCheck) or Player and Player.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and Player;
        end
    end

    function Utilities:GetClosestEnemy()
        if not Entity.isAlive then
            return;
        end

        local Enemies = {};
        local Positions = {};

        for _, Enemy in ipairs(workspace._ENEMIES:GetDescendants()) do
            if Enemy:IsA("Model") and Enemy:FindFirstChild("Humanoid") and self:IsAlive(Enemy) then
                table.insert(Enemies, Enemy);
                table.insert(Positions, Enemy.HumanoidRootPart.Position);
            end
        end

        local Index, Position = GetNearestValue(LocalPlayer.Character.HumanoidRootPart.Position, Positions);
        return Enemies[Index], Position;
    end

    function Utilities:GetEnemyWithName()
        if not Entity.isAlive then
            return;
        end

        local Enemies = {};
        local Positions = {};

        if Client.Locals["Custom Enemy"] then
            for _, Enemy in ipairs(workspace._ENEMIES:GetDescendants()) do
                if Enemy:IsA("Model") and Enemy:FindFirstChild("Head") and (Enemy.Head:FindFirstChild("health_bar") or Enemy.Head:FindFirstChild("health_boss")) then
                    local HealthBar = Enemy.Head:FindFirstChild("health_bar") or Enemy.Head:FindFirstChild("health_boss");

                    if HealthBar and HealthBar._name.label.Text:match(Client.Locals["Custom Enemy"]) then
                        table.insert(Enemies, Enemy);
                        table.insert(Positions, Enemy.HumanoidRootPart.Position);
                    end
                end
            end
        end

        local Index, Position = GetNearestValue(LocalPlayer.Character.HumanoidRootPart.Position, Positions);
        return Enemies[Index], Position;
    end

    function Utilities:GetEnemy(Method)
        if Method == "Closest" then
            return self:GetClosestEnemy();
        elseif Method == "Custom" then
            return self:GetEnemyWithName()
        end
    end

    function Utilities:TeleportTo(Input)
        if not Entity.isAlive then
            return;
        end

        if IsVector3(Input) then
            LocalPlayer.Character:MoveTo(Input);
        elseif IsCFrame(Input) then
            Entity.character.HumanoidRootPart.CFrame = Input;
        elseif IsInstance(Input) then
            Entity.character.HumanoidRootPart.CFrame = Input.CFrame;
        end
    end

    function Utilities:TpMethod(Method, Input)
        if Method == "Normal" then
            self:TeleportTo(Input);
        elseif Method == "MoveTo" then
            xpcall(function()
                OldFuncs:MoveTo(Input, true);
            end, function()
                self:TeleportTo(Input);
            end)
        end
    end
end

local function GetUncompletedQuest()
    local NotCompletedQuests = {};

    for _, Quest in next, workspace._QUESTS:GetDescendants() do
        if Quest:IsA("Frame") and Quest.Name == "completed" and Quest.Visible == false then
            table.insert(NotCompletedQuests, Quest:FindFirstAncestorOfClass("Model"));
        end
    end

    return NotCompletedQuests[1];
end

local function GetEnemyFromQuest()
    local Quest = GetUncompletedQuest();

    if Quest.Mural.SurfaceGui.Background.Objectives.main["final_stage"].Visible == false then
        local QuestInfo = Quest.Mural.SurfaceGui.Background.Objectives.main["in_progress"]._desc.Text;
        local EnemyName = string.split(QuestInfo:match("Defeat %d+ (.+)"), " in")[1];

        return string.sub(EnemyName, 1, -2);
    elseif Quest.Mural.SurfaceGui.Background.Objectives.main["final_stage"].Visible then
        local QuestInfo = Quest.Mural.SurfaceGui.Background.Objectives.main["final_stage"]._desc.Text;
        local EnemyName = string.split(QuestInfo:match("Defeat %d+ (.+)"), " in")[1];

        return string.sub(EnemyName, 1, -2);
    end
end

local function GetClosestQuestEnemy()
    local EnemyName = GetEnemyFromQuest();
    local Enemies = {};
    local Positions = {};

    for _, Enemy in next, workspace._ENEMIES:GetDescendants() do
        if Enemy:IsA("Model") and Enemy:FindFirstChild("Head") and Enemy.Head:FindFirstChild("health_bar") and Enemy.Head["health_bar"]._name.label.Text:match(EnemyName) then
            table.insert(Enemies, Enemy);
            table.insert(Positions, Enemy.HumanoidRootPart.Position);
        elseif Enemy:IsA("Model") and Enemy:FindFirstChild("Head") and Enemy.Head:FindFirstChild("health_boss") and Enemy.Head["health_boss"]._name.label.Text:match(EnemyName) then
            table.insert(Enemies, Enemy);
            table.insert(Positions, Enemy.HumanoidRootPart.Position);
        end
    end

    local Index, Position = GetNearestValue(Entity.character.HumanoidRootPart.Position, Positions);
    return Enemies[Index], Position;
end

local NoclipConnection = nil;
local Parts = {};
local function Noclipfunction()
    if Library.Unloaded then return; end
    if not Entity.isAlive then return; end

    if game.Players.LocalPlayer.Character ~= nil then
        for _, Part in next, game.Players.LocalPlayer.Character:GetDescendants() do
            if Part:IsA("BasePart") and Part.CanCollide == true then
                Part.CanCollide = false;
                Parts[Part] = true;
            end
        end
    end
end

local function GetIndex(Instance)
    for Index, NewInstance in next, Instance.Parent:GetChildren() do
        if NewInstance == Instance then
            return tostring(Index);
        end
    end
end

local function GameNotify(Type, Message) -- Types: Success, Error, and Warn.
    task.spawn(function()
        pcall(function()
            local Notification = LocalPlayer.PlayerGui.Notification.Types[Type]:Clone();
            Notification.Text.Size = UDim2.fromScale(0, 0);
            Notification.Text.Text = Message;
            Notification.Parent = LocalPlayer.PlayerGui.Notification.Messages;
            game:GetService("TweenService"):Create(Notification.Text, TweenInfo.new(0.2), {
                Size = UDim2.fromScale(1, 1);
            }):Play();

            task.wait(5)

            local TextTransparencyTween = game:GetService("TweenService"):Create(Notification.Text, TweenInfo.new(0.3), {
                TextTransparency = 1;
            })

            game:GetService("TweenService"):Create(Notification.Text.UIStroke, TweenInfo.new(0.2), {
                Transparency = 1;
            }):Play();

            TextTransparencyTween:Play();
            TextTransparencyTween.Completed:Wait();
            Notification:Destroy();
        end)
    end)
end

local function GetFeetPosition(Part, Origin)
    local Size = Part.Size;

    return Origin + Vector3.new(0, -Size.Y/2, 0)
end

local function NumberToRomanNumeral(Number)
    local RomanNumeral = "";
    local RomanNumeralMap = {
        {1000, "M"},
        {900, "CM"},
        {500, "D"},
        {400, "CD"},
        {100, "C"},
        {90, "XC"},
        {50, "L"},
        {40, "XL"},
        {10, "X"},
        {9, "IX"},
        {5, "V"},
        {4, "IV"},
        {1, "I"}
    };

    for _, Map in next, RomanNumeralMap do
        while Number >= Map[1] do
            Number = Number - Map[1];
            RomanNumeral = RomanNumeral .. Map[2];
        end
    end

    return RomanNumeral;
end

local function GetDamagePercentage()
    local AchievementData = require(game:GetService("ReplicatedStorage").Modules.Data.Achievements);
    local TotalPercentage = 0;

    for _, Achievement in next, LocalPlayer.PlayerGui.CenterUI.Achievements.Main.Scroll:GetChildren() do
        if Achievement.Name:match("dmg") and Achievement[Achievement.Name].claimed.Visible then
            table.foreach(AchievementData, function(_, Data)
                local FixedName = "DMG "..NumberToRomanNumeral(tonumber(Achievement.Name:split("_")[2]));

                if Data.name == FixedName then
                    TotalPercentage = TotalPercentage + (Data.multiplier * 100);
                end
            end)
        end
    end

    return TotalPercentage;
end

local function GetPlayerDamage()
    local Damage = ConvertToNumber(LocalPlayer.leaderstats.Energy.Value);

    return Damage + (Damage * GetDamagePercentage());
end

local function GetHitsUntilKill(Enemy)
    local Health = Enemy._stats["max_hp"].Value;

    return math.ceil(Health / GetPlayerDamage());
end

if ScriptLoaded then
    GameNotify("Error", "Script already loaded, please unload the script before executing again.");
    return;
end
getgenv().ScriptLoaded = true;

local Window = Library:CreateWindow({
    Title = string.format("%s | AlphaZero", GameName),
    Center = true,
    AutoShow = true,
})

local Tabs = {
    ["Main Tab"] = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
};

local MainTab = Tabs["Main Tab"]:AddLeftGroupbox("Farming")
local EggMainTab = Tabs["Main Tab"]:AddRightGroupbox("Egg")
local MiscTab = Tabs["Main Tab"]:AddRightGroupbox("Miscellaneous")

--local HitsUntilKill = MainTab:AddLabel("Hits Until Kill: Not Toggled");

MainTab:AddToggle("Auto Hit", {
    Text = "Auto Punch/Swing",
    Default = false,
    Tooltip = "Auto Punch/Swing will punch for you.",
})

Toggles["Auto Hit"]:OnChanged(function()
    task.spawn(function()
        while Toggles["Auto Hit"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            if Client.Locals["Attacking Meteor"] == false and Client.Locals["Attacking Boss"] == false then
                local ClosestEnemy = Utilities:GetClosestEnemy();
                local EnemyPosition = ClosestEnemy and GetFeetPosition(ClosestEnemy.HumanoidRootPart, ClosestEnemy.HumanoidRootPart.Position) or nil;
                local Distance = ClosestEnemy and (Entity.character.HumanoidRootPart.Position - EnemyPosition).Magnitude or math.huge;

                if ClosestEnemy and Distance > 5 then
                    Client.Server:FireServer({
                        "Hit"
                    });
                end
            end

            task.wait(0.1);
        end
    end)
end)

MainTab:AddDivider();

local QuestLabel = MainTab:AddLabel("Not Toggled");

MainTab:AddToggle("Auto Quest", {
    Text = "Auto Quest",
    Default = false,
    Tooltip = "Auto quest will do quests for you.",
})

Toggles["Auto Quest"]:OnChanged(function()
    if Toggles["Auto Quest"].Value then
        NoclipConnection = game.RunService.Stepped:Connect(Noclipfunction);
    else
        QuestLabel:SetText("Not Toggled");

        if NoclipConnection then
            NoclipConnection:Disconnect();
            NoclipConnection = nil;
        end

        for Index, Value in next, Parts do
            Index.CanCollide = true;
        end

        Parts = {};
    end

    task.spawn(function()
        while Toggles["Auto Quest"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            if Client.Locals["Attacking Meteor"] == false and Client.Locals["Attacking Boss"] == false then
                local Quest = GetUncompletedQuest();
                local Goal = nil;
                local CurrentIsland = workspace["_MAP"]:GetChildren()[2].Name;

                if Quest.Mural.SurfaceGui.Background.Objectives.main["in_progress"].Visible then
                    Goal = Quest.Mural.SurfaceGui.Background.Objectives.main["in_progress"]._goal;
                elseif Quest.Mural.SurfaceGui.Background.Objectives.main["final_stage"].Visible then
                    Goal = Quest.Mural.SurfaceGui.Background.Objectives.main["final_stage"]._goal;
                end

                local Kills, MaxKills = Goal.Text:split("/")[1], Goal.Text:split("/")[2];
                local ClosestEnemy, Position = GetClosestQuestEnemy();
                local EnemyPosition = ClosestEnemy and GetFeetPosition(ClosestEnemy.HumanoidRootPart, ClosestEnemy.HumanoidRootPart.Position) or nil;
                local Distance = (EnemyPosition - Entity.character.HumanoidRootPart.Position).Magnitude;

                if tonumber(Kills) >= tonumber(MaxKills) then
                    Client.Server:FireServer({
                        "Quest"
                    });
                end

                if ClosestEnemy and Distance <= 10000 then
                    QuestLabel:SetText(string.format("[Killing: %s] %s/%s kills", ClosestEnemy.Name, Kills, MaxKills));
                    --HitsUntilKill:SetText(string.format("Hits Until Kill: %s", GetHitsUntilKill(ClosestEnemy)));

                    if ClosestEnemy.Parent.Name ~= CurrentIsland then
                        Client.Server:FireServer({
                            "Teleport",
                            GetIndex(ClosestEnemy.Parent)
                        });

                        task.wait(3);
                    end

                    if Distance <= 5 then
                        Client.Server:FireServer({
                            "Hit",
                            ClosestEnemy
                        });
                    else
                        Utilities:TpMethod(Client.Locals["Teleport Method"], EnemyPosition);
                    end
                end
            end

            task.wait(0.1);
        end
    end)
end)

MainTab:AddDivider();

MainTab:AddToggle("Auto Attack Closest", {
    Text = "Auto Attack Closest",
    Default = false,
    Tooltip = "Auto attack closest will attack the closest enemy.",
})

Toggles["Auto Attack Closest"]:OnChanged(function()
    task.spawn(function()
        while Toggles["Auto Attack Closest"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            if Client.Locals["Attacking Meteor"] == false and Client.Locals["Attacking Boss"] == false then
                local Enemy, Position = Utilities:GetEnemy(Client.Locals["Get Closest Method"]);
                local EnemyPosition = Enemy and GetFeetPosition(Enemy.HumanoidRootPart, Enemy.HumanoidRootPart.Position) or nil;
                local Distance = (Entity.character.HumanoidRootPart.Position - EnemyPosition).Magnitude;

                if Enemy and Distance <= 5 then
                    --HitsUntilKill:SetText(string.format("Hits Until Kill: %s", GetHitsUntilKill(Enemy)));
                    Client.Server:FireServer({
                        "Hit",
                        Enemy
                    });
                end
            end

            task.wait(0.1);
        end
    end)
end)

MainTab:AddToggle("Teleport To Enemy", {
    Text = "Teleport To Enemy",
    Default = false,
    Tooltip = "Teleport to Enemy will teleport you to the enemy.",
})

Toggles["Teleport To Enemy"]:OnChanged(function()
    if Toggles["Teleport To Enemy"].Value then
        NoclipConnection = game.RunService.Stepped:Connect(Noclipfunction);
    else
        if NoclipConnection then
            NoclipConnection:Disconnect();
            NoclipConnection = nil;
        end

        for Index, Value in next, Parts do
            Index.CanCollide = true;
        end

        Parts = {};
    end

    task.spawn(function()
        while Toggles["Teleport To Enemy"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            if Client.Locals["Attacking Meteor"] == false and Client.Locals["Attacking Boss"] == false then
                local Enemy, Position = Utilities:GetEnemy(Client.Locals["Get Closest Method"]);
                local EnemyPosition = Enemy and GetFeetPosition(Enemy.HumanoidRootPart, Enemy.HumanoidRootPart.Position) or nil;
                local Distance = (Entity.character.HumanoidRootPart.Position - EnemyPosition).Magnitude;

                if Enemy and Distance <= 2000 then
                    Utilities:TpMethod(Client.Locals["Teleport Method"], EnemyPosition);
                else
                    local CurrentWorld = workspace._MAP:GetChildren()[2];
                    local WorldIndex = GetIndex(Enemy.Parent);

                    if CurrentWorld.Name ~= Enemy.Parent.Name then
                        if LocalPlayer.PlayerGui.CenterUI.Teleport.Main.Scroll[WorldIndex].locked.Visible == false then
                            Client.Server:FireServer({
                                "Teleport",
                                WorldIndex
                            });

                            task.wait(3);

                            Utilities:TpMethod(Client.Locals["Teleport Method"], EnemyPosition);
                        else
                            GameNotify("Error", "You cannot teleport to this island.");
                            Toggles["Teleport To Enemy"]:SetValue(false);
                            break;
                        end
                    end
                end
            end

            task.wait();
        end
    end)
end)

MainTab:AddDivider();

MainTab:AddDropdown("Teleport Methods", {
    Values = {"MoveTo", "Normal"},
    Default = 2,
    Multi = false,

    Text = "Teleport Methods",
    Tooltip = "Teleport methods will change the way you teleport.",
})

Options["Teleport Methods"]:OnChanged(function()
    local Selected = Options["Teleport Methods"].Value;

    Client.Locals["Teleport Method"] = Selected;
end)

MainTab:AddDropdown("Get Closest Method", {
    Values = {"Closest", "Custom"},
    Default = 1,
    Multi = false,

    Text = "Get Closest Method",
    Tooltip = "Get closest method will change the way you get the enemy.",
})

Options["Get Closest Method"]:OnChanged(function()
    local Selected = Options["Get Closest Method"].Value;

    Client.Locals["Get Closest Method"] = Selected;
end)

local Enemys = {};

for _, Enemy in ipairs(workspace._ENEMIES:GetDescendants()) do
    if Enemy:IsA("Model") and Enemy:FindFirstChild("Head") and (Enemy.Head:FindFirstChild("health_bar") or Enemy.Head:FindFirstChild("health_boss")) then
        local HealthBar = Enemy.Head:FindFirstChild("health_bar") or Enemy.Head:FindFirstChild("health_boss");

        if HealthBar and not table.find(Enemys, HealthBar._name.label.Text) then
            table.insert(Enemys, HealthBar._name.label.Text);
        end
    end
end

table.sort(Enemys);

MainTab:AddDropdown("Custom Enemy", {
    Values = Enemys,
    Default = nil,
    Multi = false,

    Text = "Custom Enemy (Hover for reqs.)",
    Tooltip = '( You need to have "Get Closest Method" set to "Custom" ) Custom enemy will change the enemy you want to get.',
})

Options["Custom Enemy"]:OnChanged(function()
    local Selected = Options["Custom Enemy"].Value;

    Client.Locals["Custom Enemy"] = Selected;
end)

MainTab:AddDivider();
MainTab:AddLabel("Meteor");

MainTab:AddToggle("Auto Attack Meteors", {
    Text = "Auto Attack Meteors",
    Default = false,
    Tooltip = "Auto attack meteors will attack the meteors.",
})

local function GetClosestFromWorld(Part)
    local Positions = {};
    local Worlds = workspace._QUESTS:GetChildren();
    
    for _, World in ipairs(Worlds) do
        local WorldPart = World.Mural;

        if WorldPart then
            table.insert(Positions, WorldPart.Position);
        end
    end

    local Index, Position = GetNearestValue(Part.Position, Positions);
    return Worlds[Index];
end

workspace._METEORS.ChildAdded:Connect(function()
    Library:Notify("A meteor has spawned.", 5);
end)

workspace._METEORS.ChildRemoved:Connect(function()
    Client.Locals["Attacking Meteor"] = false;
end)

local function WorldCheck(World)
    for Name,_ in next, Client.Locals["Worlds"] do
        if Name == World.Name then
            return true;
        end
    end

    return false;
end

Toggles["Auto Attack Meteors"]:OnChanged(function()
    task.spawn(function()
        while Toggles["Auto Attack Meteors"] and Toggles["Auto Attack Meteors"].Value do
            local Meteors = workspace._METEORS:GetChildren();
    
            if #Meteors > 0 and Client.Locals["Attacking Boss"] == false then
                local PrimaryPart = Meteors[1].PrimaryPart;
                local Distance = (Entity.character.HumanoidRootPart.Position - PrimaryPart.Position).Magnitude;
                local World = GetClosestFromWorld(PrimaryPart);
                local CurrentWorld = workspace._MAP:GetChildren()[2];
                local WorldIndex = GetIndex(World);

                if PrimaryPart then
                    if Distance <= 5 and WorldCheck(World) == false then
                        Client.Server:FireServer({
                            "Hit",
                            PrimaryPart.Parent
                        });
                    else
                        local Distance = (Entity.character.HumanoidRootPart.Position - PrimaryPart.Position).Magnitude;

                        if Distance <= 2000 then
                            if World.Name ~= CurrentWorld.Name and WorldCheck(World) == false then
                                if LocalPlayer.PlayerGui.CenterUI.Teleport.Main.Scroll[WorldIndex].locked.Visible == false then
                                    Client.Locals["Attacking Meteor"] = true;

                                    Client.Server:FireServer({
                                        "Teleport",
                                        WorldIndex
                                    });

                                    task.wait(3);
                                end
                            end

                            if LocalPlayer.PlayerGui.CenterUI.Teleport.Main.Scroll[WorldIndex].locked.Visible == false and WorldCheck(World) == false then
                                if Distance <= 2000 then
                                    Client.Locals["Attacking Meteor"] = true;

                                    Utilities:TpMethod(Client.Locals["Teleport Method"], PrimaryPart.Position);
                                end
                            end
                        end
                    end
                end
            else
                Client.Locals["Attacking Meteor"] = false;
            end

            task.wait(0.1);
        end
    end)
end)

local Worlds = {};
for _, World in ipairs(workspace._QUESTS:GetChildren()) do
    table.insert(Worlds, World.Name);
end

MainTab:AddDropdown("Worlds", {
    Values = Worlds,
    Default = nil,
    Multi = true,

    Text = "Ignore Selected Meteors",
    Tooltip = "This will change the world(s) you want to ignore.",
})

Options["Worlds"]:OnChanged(function()
    local Selected = Options["Worlds"].Value;

    Client.Locals["Worlds"] = Selected;
end)

MainTab:AddDivider();
MainTab:AddLabel("Boss");

local function GetAliveBoss()
    for _, Boss in next, workspace["_RAID_BOSSES"]:GetChildren() do
        if Boss:IsA("Model") and Boss:FindFirstChild("Humanoid") and Boss.Humanoid.Health > 0 then
            return Boss;
        end
    end

    return nil;
end

MainTab:AddToggle("Auto Attack Boss", {
    Text = "Auto Attack Raid Boss",
    Default = false,
    Tooltip = "Auto attack boss will attack the boss.",
})

workspace["_RAID_BOSSES"].ChildAdded:Connect(function()
    Library:Notify("A boss has spawned.", 5);
end)

workspace["_RAID_BOSSES"].ChildRemoved:Connect(function()
    Client.Locals["Attacking Boss"] = false;
end)

local function BossWorldCheck(World)
    for Name,_ in next, Client.Locals["Boss Worlds"] do
        if Name == World.Name then
            return true;
        end
    end

    return false;
end

Toggles["Auto Attack Boss"]:OnChanged(function()
    task.spawn(function()
        while Toggles["Auto Attack Boss"] and Toggles["Auto Attack Boss"].Value do
            local Boss = GetAliveBoss();

            if Boss then
                local BossPosition = GetFeetPosition(Boss.HumanoidRootPart, Boss.HumanoidRootPart.Position);
                local World = GetClosestFromWorld(Boss.HumanoidRootPart);
                local CurrentWorld = workspace._MAP:GetChildren()[2];
                local WorldIndex = GetIndex(World);
                local Distance = (Entity.character.HumanoidRootPart.Position - BossPosition).Magnitude;

                if Distance <= 5 then
                    Client.Server:FireServer({
                        "Hit",
                        Boss
                    });
                else
                    if World.Name ~= CurrentWorld.Name and BossWorldCheck(World) == false then
                        if LocalPlayer.PlayerGui.CenterUI.Teleport.Main.Scroll[WorldIndex].locked.Visible == false then
                            Client.Locals["Attacking Boss"] = true;

                            Client.Server:FireServer({
                                "Teleport",
                                WorldIndex
                            });

                            task.wait(3);
                        end
                    end

                    if LocalPlayer.PlayerGui.CenterUI.Teleport.Main.Scroll[WorldIndex].locked.Visible == false and BossWorldCheck(World) == false then
                        if Distance <= 2000 then
                            Client.Locals["Attacking Boss"] = true;

                            Utilities:TpMethod(Client.Locals["Teleport Method"], BossPosition);
                        end
                    end
                end
            else
                Client.Locals["Attacking Boss"] = false;
            end

            task.wait(0.1);
        end
    end)
end)

MainTab:AddDropdown("Boss Worlds", {
    Values = Worlds,
    Default = nil,
    Multi = true,

    Text = "Ignore Selected Raid Bosses",
    Tooltip = "This will change the world(s) you want to ignore.",
})

Options["Boss Worlds"]:OnChanged(function()
    local Selected = Options["Boss Worlds"].Value;

    Client.Locals["Boss Worlds"] = Selected;
end)

local EggLabel = EggMainTab:AddLabel("Not Toggled");

EggMainTab:AddToggle("Auto Buy Egg", {
    Text = "Auto Buy Egg",
    Default = false,
    Tooltip = "Auto buy egg will buy the egg for you.",
})

Toggles["Auto Buy Egg"]:OnChanged(function()
    if not Toggles["Auto Buy Egg"].Value then
        EggLabel:SetText("Not Toggled");
    end

    task.spawn(function()
        while Toggles["Auto Buy Egg"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            if Client.Locals["Attacking Meteor"] == false then
                local Distance = (Entity.character.HumanoidRootPart.Position - workspace._EGGS[Client.Locals["Egg"]].WorldsPad.Position).Magnitude;

                local CurrentSouls = ConvertToNumber(LocalPlayer.leaderstats.Souls.Value);
                local Price = ConvertToNumber(GetChild("TextLabel", LocalPlayer.PlayerGui.CenterUI.BuyPet.Main.Price).Text);

                xpcall(function()
                    EggLabel:SetText(string.format("Amount you can buy: %s", math.floor(CurrentSouls / Price)));
                end, function()
                    EggLabel:SetText("Amount you can buy: N/A : Error")
                end)

                if Distance <= 13 then
                    Client.Server:FireServer({
                        "BuyHeroes",
                        Client.Locals["Egg"]
                    });
                else
                    if Distance <= 2000 and Distance > 13 then
                        Utilities:TpMethod(Client.Locals["Teleport Method"], workspace._EGGS[Client.Locals["Egg"]].WorldsPad.Position + Vector3.new(0, 5, 0));
                    else
                        local CurrentWorld = workspace._MAP:GetChildren()[2];
                        local WorldIndex = GetIndex(workspace._QUESTS[Client.Locals["Egg"]]);

                        if CurrentWorld.Name ~= workspace._EGGS[Client.Locals["Egg"]].Parent.Name then
                            if LocalPlayer.PlayerGui.CenterUI.Teleport.Main.Scroll[WorldIndex].locked.Visible == false then
                                Client.Server:FireServer({
                                    "Teleport",
                                    WorldIndex
                                });

                                task.wait(3);

                                Utilities:TpMethod(Client.Locals["Teleport Method"], EnemyPosition);
                            else
                                GameNotify("Error", "You cannot teleport to this island.");
                                Toggles["Teleport To Enemy"]:SetValue(false);
                                break;
                            end
                        end
                    end
                end
            end

            task.wait(0.5);
        end
    end)
end)

EggMainTab:AddDivider();

EggMainTab:AddDropdown("Eggs", {
    Values = Worlds,
    Default = 1,
    Multi = false,

    Text = "Eggs",
    Tooltip = "Eggs will change the egg you want to buy.",
})

Options["Eggs"]:OnChanged(function()
    local Selected = Options["Eggs"].Value;

    Client.Locals["Egg"] = Selected;
end)

local function OpenAutoDeleteGui()
    local Settings = LocalPlayer.PlayerGui.CenterUI.Settings;
    if not Settings.Visible then
        Settings.Visible = true;

        local TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out);

        game.TweenService:Create(Settings, TweenInfo, {
            Position = UDim2.fromScale(0.5, 0.5)
        }):Play();

        Settings.Main.Back.Visible = true;
        Settings.Main.auto_delete.Visible = true;
        Settings.Main.Close.Visible = false;
        Settings.Main.options.Visible = false;
    else
        local TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In);

        game.TweenService:Create(Settings, TweenInfo, {
            Position = UDim2.fromScale(0.5, -0.5)
        }):Play();

        task.wait(0.2);

        Settings.Main.Back.Visible = false;
        Settings.Main.auto_delete.Visible = false;
        Settings.Main.Close.Visible = true;
        Settings.Main.options.Visible = true;

        Settings.Visible = false;
    end
end

EggMainTab:AddButton("Open Auto Delete Gui", OpenAutoDeleteGui):AddTooltip("Open auto delete gui will open and close the auto delete gui for you.");

MiscTab:AddToggle("Auto Equip Best", {
    Text = "Auto Equip Best Heros",
    Default = false,
    Tooltip = "Auto equip best will equip the best heros for you.",
})

Toggles["Auto Equip Best"]:OnChanged(function()
    task.spawn(function()
        while Toggles["Auto Equip Best"] and Toggles["Auto Equip Best"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            local BestHeroes = {};
            local Services = require(LocalPlayer.PlayerGui.Init.Client.Services);
            local PetsData = require(game:GetService("ReplicatedStorage").Modules.Data.Pets);
            local AchievementData = require(LocalPlayer.PlayerGui.Init.Client.Services.AchievementsService);

            for _, Hero in next, LocalPlayer.PlayerGui.CenterUI.Pets.Main.Scroll:GetChildren() do
                if Hero:IsA("ImageButton") then
                    if Hero.Equipped.Visible then
                        Client.Server:FireServer({
                            "EquipHero",
                            Hero.data.uuid.Value;
                        })
                    end

                    local HeroData = {
                        EnergyMultiplier = PetsData[Hero.data.id.Value].multipliers.energy,
                        uuid = Hero.data.uuid.Value;
                    };

                    if Hero.data.shiny.Value then
                        HeroData.EnergyMultiplier = HeroData.EnergyMultiplier * 2;
                    end

                    table.insert(BestHeroes, HeroData)
                end
            end

            table.sort(BestHeroes, function(hero1, hero2)
                return hero2.EnergyMultiplier < hero1.EnergyMultiplier;
            end)

            local PlayerData = Services.PlayerData;
            local HasMoreEquipsGamepass = PlayerData.Gamepasses["More Equips"];
            local Equips = PlayerData.Equips;
            local EquipsAllowed = Equips + (HasMoreEquipsGamepass and 3 or 0) + AchievementData.get_equips_by_achievements();
            local HeroesToEquip = math.min(#BestHeroes, EquipsAllowed);

            for i = 1, HeroesToEquip do
                Client.Server:FireServer({
                    "EquipHero",
                    BestHeroes[i].uuid
                })
            end

            task.wait(5);
        end
    end)
end)

local function GetNormalPets()
    local Pets = {};

    for _, Pet in next, LocalPlayer.PlayerGui.CenterUI.Pets.Main.Scroll:GetChildren() do
        if Pet:IsA("ImageButton") and Pet.data.shiny.Value == false then
            table.insert(Pets, Pet);
        end
    end

    return Pets;
end

MiscTab:AddToggle("Auto Craft Pets", {
    Text = "Auto Craft Pets",
    Default = false,
    Tooltip = "Auto craft pets will craft pets for you.",
})

Toggles["Auto Craft Pets"]:OnChanged(function()
    task.spawn(function()
        while Toggles["Auto Craft Pets"] and Toggles["Auto Craft Pets"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            local Pets = GetNormalPets();
            local Ids = {};
            local CraftArgs = {
                "ShinyMachine",
                {}
            };

            for _, Pet in next, Pets do
                if not Ids[Pet.data.id.Value] then
                    Ids[Pet.data.id.Value] = 1;
                else
                    Ids[Pet.data.id.Value] = Ids[Pet.data.id.Value] + 1;
                end
            end

            for Id, Count in next, Ids do
                if Count >= 5 then
                    for _, Pet in next, Pets do
                        if Pet.data.id.Value == Id and Pet.Equipped.Visible == false and #CraftArgs[2] < 5 then
                            table.insert(CraftArgs[2], Pet.data.uuid.Value);
                        end
                    end
                end
            end

            if #CraftArgs[2] >= 5 then
                Client.Server:FireServer(CraftArgs);
            end

            task.wait(5);
        end
    end)
end)

MiscTab:AddToggle("Auto Skill Spin", {
    Text = "Auto Skill Spin",
    Default = false,
    Tooltip = "Auto skill spin will spin for you.",
})

local SpinLabel = GetChild("Label", LocalPlayer.PlayerGui.CenterUI.Skills.Main.Buttons.Spin);
Toggles["Auto Skill Spin"]:OnChanged(function()
    task.spawn(function()
        while Toggles["Auto Skill Spin"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            local NumberOfSpins = SpinLabel.Text:match("%d+");

            if tonumber(NumberOfSpins) > 0 then
                Client.Server:FireServer({
                    "SkillSpin"
                });
            end
            task.wait(0.5);
        end
    end)
end)

local function GetSword()
    local FoundTool = LocalPlayer.Character:FindFirstChildOfClass("Tool");
    local SwordData = require(game:GetService("ReplicatedStorage").Modules.Data.Swords);

    if FoundTool then
        for _, Sword in next, SwordData do
            if Sword.id:match(FoundTool.Name) then
                return true, tonumber(Sword.multiplier);
            end
        end
    end

    return false;
end

local function GetSwords()
    local HasSword, Multi = GetSword();
    local SwordData = require(game:GetService("ReplicatedStorage").Modules.Data.Swords);
    local Swords = {};

    for _, Sword in ipairs(SwordData) do
        if HasSword then
            if tonumber(Sword.multiplier) > Multi then
                table.insert(Swords, Sword);
            end
        else
            table.insert(Swords, Sword);
        end
    end

    return Swords;
end

MiscTab:AddToggle("Auto Buy Swords", {
    Text = "Auto Buy Swords",
    Default = false,
    Tooltip = "Auto buy swords will buy swords for you.",
})

Toggles["Auto Buy Swords"]:OnChanged(function()
    task.spawn(function()
        while Toggles["Auto Buy Swords"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            local CurrentSouls = ConvertToNumber(LocalPlayer.leaderstats.Souls.Value);
            local Swords = GetSwords();

            if tonumber(Swords[1].price) <= CurrentSouls then
                Client.Server:FireServer({
                    "Swords"
                });
            end

            task.wait(1);
        end
    end)
end)

MiscTab:AddDivider();

local PriceLabel = MiscTab:AddLabel("Price Until Upgrade: Not Toggled");

MiscTab:AddToggle("Auto Upgrade Class", {
    Text = "Auto Upgrade Class",
    Default = false,
    Tooltip = "Auto upgrade class will upgrade your class for you.",
})

Toggles["Auto Upgrade Class"]:OnChanged(function()
    if not Toggles["Auto Upgrade Class"].Value then
        PriceLabel:SetText("Price Until Upgrade: Not Toggled");
    end

    task.spawn(function()
        while Toggles["Auto Upgrade Class"].Value do
            if Library.Unloaded then break; end
            if not Entity.isAlive then return; end

            local CurrentSouls = ConvertToNumber(LocalPlayer.leaderstats.Souls.Value);
            local Price = ConvertToNumber(GetChild("price", LocalPlayer.PlayerGui.CenterUI.Class.Main.Mid["can_upgrade"].price).Text)

            PriceLabel:SetText("Price Until Upgrade: " .. ConvertToSuffix(Price - CurrentSouls));

            if CurrentSouls >= Price then
                Client.Server:FireServer({
                    "Class"
                });
            end
            task.wait(1);
        end
    end)
end)

MiscTab:AddDivider();

local function OpenTeleportGui()
    local Teleport = LocalPlayer.PlayerGui.CenterUI.Teleport;

    if not Teleport.Visible then
        Teleport.Visible = true;

        local TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out);

        game.TweenService:Create(Teleport, TweenInfo, {
            Position = UDim2.fromScale(0.5, 0.5)
        }):Play();
    else
        local TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In);

        game.TweenService:Create(Teleport, TweenInfo, {
            Position = UDim2.fromScale(0.5, -0.5)
        }):Play();

        task.wait(0.2)

        Teleport.Visible = false;
    end
end

local function RedeemCodes()
    local Url = "https://tryhardguides.com/anime-souls-simulator-codes/";
    local Response = game:HttpGet(Url);
    local Codes = {};

    for ul in string.gmatch(Response, "<ul>(.-)</ul>") do
        for li in string.gmatch(ul, "<li>(.-)</li>") do
            for Code in string.gmatch(li, "<strong>([^<]+)</strong>") do
                table.insert(Codes, Code);
            end
        end
    end

    for _, Code in next, Codes do
        Client.Server:FireServer({
            "Codes",
            Code
        });
    end
end

MiscTab:AddButton("Redeem Codes", RedeemCodes):AddTooltip("Redeem codes will redeem all the codes for you.");
MiscTab:AddButton("Open Teleport Gui", OpenTeleportGui):AddTooltip("Open teleport gui will open and close the teleport gui for you.");
MiscTab:AddButton("Join Discord", function()
    Library:Notify("Joining discord...", 5);

    local Network = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/Network.lua")))();

    Network:SendInvite("JdzPVMNFwY");
end):AddTooltip("Join discord will join the discord server for you.");

Library:SetWatermarkVisibility(true)

Library.KeybindFrame.Visible = false;

Library:OnUnload(function()
    Library.Unloaded = true;
    getgenv().ScriptLoaded = false;
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu');

MenuGroup:AddButton("Unload UI", function() Library:Unload() end);
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default = "RightControl", NoUI = true, Text = "Menu keybind"});

Library.ToggleKeybind = Options.MenuKeybind;

ThemeManager:SetLibrary(Library);
SaveManager:SetLibrary(Library);

SaveManager:IgnoreThemeSettings();

SaveManager:SetIgnoreIndexes({"MenuKeybind"});

ThemeManager:SetFolder("AlphaZero");
SaveManager:SetFolder("AlphaZero/Anime Souls Simulator");

SaveManager:BuildConfigSection(Tabs["UI Settings"]);

ThemeManager:ApplyToTab(Tabs["UI Settings"]);

task.spawn(function()
    while game:GetService('RunService').RenderStepped:Wait() do
        if Library.Unloaded then break; end

        if Toggles.Rainbow and Toggles.Rainbow.Value then
            local Registry = Window.Holder.Visible and Library.Registry or Library.HudRegistry;

            for _, Object in next, Registry do
                for Property, ColorIdx in next, Object.Properties do
                    if ColorIdx == 'AccentColor' or ColorIdx == 'AccentColorDark' then
                        local Instance = Object.Instance;
                        local yPos = Instance.AbsolutePosition.Y;

                        local Mapped = Library:MapValue(yPos, 0, 1080, 0, 0.5) * 1.5;
                        local Color = Color3.fromHSV((Library.CurrentRainbowHue - Mapped) % 1, 0.8, 1);

                        if ColorIdx == 'AccentColorDark' then
                            Color = Library:GetDarkerColor(Color);
                        end

                        Instance[Property] = Color;
                    end
                end
            end
        end
    end
end)

Toggles.Rainbow:OnChanged(function()
    if not Toggles.Rainbow.Value then
        ThemeManager:ThemeUpdate()
    end
end)

local function GetLocalTime()
	local Time = os.date("*t")
	local Hour = Time.hour;
	local Minute = Time.min;
	local Second = Time.sec;

	local AmPm = nil;
	if Hour >= 12 then
		Hour = Hour - 12;
		AmPm = "PM";
	else
		Hour = Hour == 0 and 12 or Hour;
		AmPm = "AM";
	end

	return string.format("%s:%02d:%02d %s", Hour, Minute, Second, AmPm);
end

local DayMap = {"st", "nd", "rd", "th"};
local function FormatDay(Day)
    local LastDigit = Day % 10;
    if LastDigit >= 1 and LastDigit <= 3 then
        return string.format("%s%s", Day, DayMap[LastDigit]);
    end

    return string.format("%s%s", Day, DayMap[4]);
end

local MonthMap = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
local function GetLocalDate()
	local Time = os.date("*t")
	local Day = Time.day;

	local Month = nil;
	if Time.month >= 1 and Time.month <= 12 then
		Month = MonthMap[Time.month];
	end

	return string.format("%s %s", Month, FormatDay(Day));
end

local function GetLocalDateTime()
	return GetLocalDate() .. " " .. GetLocalTime();
end

Toggles.Rainbow:SetValue(true);

Library:Notify(string.format('Loaded script in %.2f second(s)!', tick() - StartTick), 5);

task.spawn(function()
    while true do task.wait(0.1)
        if Library.Unloaded then break; end

        local Ping = string.split(string.split(game.Stats.Network.ServerStatsItem["Data Ping"]:GetValueString(), " ")[1], ".")[1];
        local Fps = string.split(game.Stats.Workspace.Heartbeat:GetValueString(), ".")[1];
        local AccountName = LocalPlayer.Name;

        Library:SetWatermark(string.format("%s | %s | %s FPS | %s Ping", GetLocalDateTime(), AccountName, Fps, Ping));
    end
end)