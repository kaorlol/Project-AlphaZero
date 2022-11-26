local Network = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/Network.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PlayerAttackInfo, Rayfield;
local Client = {
    Remotes = {
        GeneralAttack = ReplicatedStorage.RemoteEvents.GeneralAttack,
        DrawRole = ReplicatedStorage.RemoteEvents.DrawRole,
    },
    Connections = {
        CharacterAdded = {},
        ChildAdded = {},
    },
}

local AttackFuncs = {}; do
    function AttackFuncs:GetEnemies()
        getgenv().EnemyLevel = shared.EnemyLevel or "Leve1"
        local Enemies = {}

        for _, Pos in next, workspace.GhostPos[EnemyLevel]:GetChildren() do
            for _, Enemy in next, Pos:GetChildren() do
                if Enemy:IsA("Model") then
                    table.insert(Enemies, Enemy)
                end
            end
        end

        return Enemies
    end
    function AttackFuncs:GetClosestEnemy()
        local Enemies = self:GetEnemies()
        local ClosestEnemy = nil
        local ClosestDistance = math.huge

        if not ClosestEnemy then
            PlayerAttackInfo:Set({Title = "Attack Status:", Content = "Finding Target..."})
            for _, Enemy in next, Enemies do
                local Distance = (Enemy.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                if Distance < ClosestDistance then
                    ClosestDistance = Distance
                    ClosestEnemy = Enemy
                end
            end
        else
            return ClosestEnemy
        end

        return ClosestEnemy
    end
    function AttackFuncs:GetEnemyWithLowestHP()
        local Enemies = self:GetEnemies()
        local LowestHPEnemy = nil
        local LowestHP = math.huge

        if not LowestHPEnemy then
            PlayerAttackInfo:Set({Title = "Attack Status:", Content = "Finding Target..."})
            for _, Enemy in next, Enemies do
                if Enemy.Humanoid.MaxHealth < LowestHP then
                    LowestHP = Enemy.Humanoid.MaxHealth
                    LowestHPEnemy = Enemy
                end
            end
        else
            return LowestHPEnemy
        end

        return LowestHPEnemy
    end
    function AttackFuncs:GetEnemyWithHighestHP()
        local Enemies = self:GetEnemies()
        local HighestHPEnemy = nil
        local HighestHP = 0

        if not HighestHPEnemy then
            PlayerAttackInfo:Set({Title = "Attack Status:", Content = "Finding Target..."})
            for _, Enemy in next, Enemies do
                if Enemy.Humanoid.MaxHealth > HighestHP then
                    HighestHP = Enemy.Humanoid.MaxHealth
                    HighestHPEnemy = Enemy
                end
            end
        else
            return HighestHPEnemy
        end

        return HighestHPEnemy
    end
    function AttackFuncs:DoMethod()
        getgenv().AttackMethod = shared.AutoAttackMode or "Closest Enemy"

        if getgenv().AttackMethod == "Closest Enemy" then
            return self:GetClosestEnemy()
        elseif getgenv().AttackMethod == "Lowest HP" then
            return self:GetEnemyWithLowestHP()
        elseif getgenv().AttackMethod == "Highest HP" then
            return self:GetEnemyWithHighestHP()
        end
    end
    function AttackFuncs:TweenTo(CF, Time)
        local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local Tween = TweenService:Create(HumanoidRootPart, TweenInfo, {CFrame = CF})
        Tween:Play()
        Tween.Completed:Wait()
    end
    function AttackFuncs:MoveTo(CFrame)
        local PathfindingService = game:GetService("PathfindingService")
        local Path = PathfindingService:CreatePath()
        Path:ComputeAsync(HumanoidRootPart.Position, CFrame.Position)
        local Waypoints = Path:GetWaypoints()

        for _, Waypoint in next, Waypoints do
            Humanoid:MoveTo(Waypoint.Position)
        end
    end
    function AttackFuncs:TeleportTo(Part)
        getgenv().TeleportMethod = shared.TeleportMethod or "PivotTo"
        getgenv().TweenTime = shared.TweenDelay or 0.5

        if TeleportMethod == "PivotTo" then
            Character:PivotTo(Part.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))
        elseif TeleportMethod == "TweenTo" then
            self:TweenTo(Part.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0), TweenTime)
        elseif TeleportMethod == "MoveTo" then
            self:MoveTo(Part.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))
        end
    end
    function AttackFuncs:AutoAttack(boolean)
        getgenv().AutoAttack = boolean or false
        getgenv().UseAbilities = false
        getgenv().AbilityToUse = nil

        task.spawn(function()
            while true do task.wait()
                if AutoAttack then
                    local ClosestEnemy = self:DoMethod()

                    if ClosestEnemy then
                        local Distance = (ClosestEnemy.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                        local HeadUI = ClosestEnemy.Head:WaitForChild("HeadUI")

                        PlayerAttackInfo:Set({Title = "Attack Status:", Content = string.format("%s %s; HP: %s", HeadUI.DemonTitle.Text, HeadUI.DemonName.Text, HeadUI.Hp.HpLabel.Text)})
                        self:TeleportTo(ClosestEnemy.HumanoidRootPart)

                        if LocalPlayer.PlayerGui.MainUi.BattleUi.Visible then
                            for _, Ability in next, LocalPlayer.PlayerGui.MainUi.BattleUi["Attack_Pc"]:GetChildren() do
                                if Ability:IsA("ImageButton") and Ability.Lock.Visible == false and Ability.Mask.AbsoluteSize == Vector2.new(149.688, 0) then
                                    UseAbilities = true
                                    AbilityToUse = Ability
                                elseif Ability:IsA("ImageButton") and Ability.Lock.Visible == false and Ability.Mask.AbsoluteSize ~= Vector2.new(149.688, 0) then
                                    UseAbilities = false
                                    AbilityToUse = nil
                                end
                            end
                        end

                        if Distance <= 5 and UseAbilities and AbilityToUse ~= nil then
                            firesignal(AbilityToUse.MouseButton1Click)
                        elseif Distance <= 5 and not UseAbilities then
                            Network:Send(Client.Remotes.GeneralAttack)
                        end
                    end
                end
            end
        end)
    end
end
local EggFuncs = {}; do
    function EggFuncs:AutoEgg(boolean)
        getgenv().AutoEgg = boolean or false

        task.spawn(function()
            while true do
                if AutoEgg then
                    Character:PivotTo(workspace.Maps.LuckDraw.CameraPos.CFrame)
                    Network:Send(Client.Remotes.DrawRole, false)
                end
                task.wait(3.5)
            end
        end)
    end
end
local TrainFuncs = {}; do
    function TrainFuncs:TweenTo(CF, Time)
        local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local Tween = TweenService:Create(HumanoidRootPart, TweenInfo, {CFrame = CF})
        Tween:Play()
        Tween.Completed:Wait()
    end
    function TrainFuncs:MoveTo(CFrame)
        local PathfindingService = game:GetService("PathfindingService")
        local Path = PathfindingService:CreatePath()
        Path:ComputeAsync(HumanoidRootPart.Position, CFrame.Position)
        local Waypoints = Path:GetWaypoints()
    
        for _, Waypoint in next, Waypoints do
            Humanoid:MoveTo(Waypoint.Position)
        end
    end
    function TrainFuncs:TrainTeleport(Part)
        getgenv().TrainTeleportMethod = shared.TrainTeleportMethod or "PivotTo"
        getgenv().TrainTweenTime = shared.TrainTweenDelay or 0.5
    
        if TrainTeleportMethod == "PivotTo" then
            Character:PivotTo(Part.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))
        elseif TrainTeleportMethod == "TweenTo" then
            self:TweenTo(Part.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0), TrainTweenTime)
        elseif TrainTeleportMethod == "MoveTo" then
            self:MoveTo(Part.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))
        end
    end
end

Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
local Window = Rayfield:CreateWindow({
    Name = "Demon Soul Simulator",
    LoadingTitle = "Demon Soul Simulator",
    LoadingSubtitle = "By: Kaoru~#6438",
    ConfigurationSaving = {
		Enabled = true,
		FolderName = "Kaoru",
		FileName = "Demon-Soul-Simulator"
	},
})

local Main = Window:CreateTab('Auto Farm')
Main:CreateSection("Auto Attack")

PlayerAttackInfo = Main:CreateParagraph({
    Title = "Attack Status: ",
    Content = "Awaiting Toggle...",
})

Main:CreateToggle({
    Name = "Auto Attack",
    CurrentValue = false,
    Callback = function(AutoAttack)
        AttackFuncs:AutoAttack(AutoAttack)

        if not AutoAttack then
            PlayerAttackInfo:Set({Title = "Attack Status:", Content = "Awaiting Toggle..."})
        end
    end,
})

Main:CreateSection("Auto Train")

TrainInfo = Main:CreateParagraph({
    Title = "Train Status: ",
    Content = "Awaiting Toggle...",
})

AutoTrainToggle = Main:CreateToggle({
    Name = "Auto Train",
    CurrentValue = false,
    Callback = function(AutoTrain)
        shared.AutoTrain = AutoTrain
        if AutoTrain then
            local EnterTrain = ReplicatedStorage.RemoteEvents.EnterTrain
            local OpenButton = LocalPlayer.PlayerGui.MainUi.TrainBreathRewardFrame.Bg.ChestFrame.OpenBtn
            local ReceiveButton = LocalPlayer.PlayerGui.MainUi.TrainBreathRewardFrame.Bg.Reward.ReceiveBtn
            local OkButton = LocalPlayer.PlayerGui.MainUi.EnsureFrame.Bg.Buttons.OkButton

            Network:Send(EnterTrain, true, workspace.Train.Floor.CFrame, workspace.Train.Floor.CFrame)
            task.wait(1)

            task.spawn(function()
                while true do task.wait()
                    if not shared.AutoTrain then
                        break;
                    end
                    local Ghost = workspace.TrainGhosts[LocalPlayer.Name]:GetChildren()[1]
                    getgenv().TrainUseAbilities = false

                    if LocalPlayer.PlayerGui.MainUi.EnsureFrame.Visible then
                        Network:Notify("Heyo!", "You have ran out of time, you need to get stronger!", 5)
                        AutoTrainToggle:Set(false)
                        firesignal(OkButton.MouseButton1Click)
                        break;
                    end

                    if Ghost then
                        local GhostHeadUI = Ghost:WaitForChild("Head"):WaitForChild("HeadUI")
                        local Distance = (HumanoidRootPart.Position - Ghost.HumanoidRootPart.Position).Magnitude

                        TrainInfo:Set({Title = "Train Status:", Content = string.format("%s %s; HP: %s", GhostHeadUI.DemonTitle.Text, GhostHeadUI.DemonName.Text, GhostHeadUI.Hp.HpLabel.Text)})
                        TrainFuncs:TrainTeleport(Ghost.HumanoidRootPart)

                        if LocalPlayer.PlayerGui.MainUi.BattleUi.Visible then
                            for _, Ability in next, LocalPlayer.PlayerGui.MainUi.BattleUi["Attack_Pc"]:GetChildren() do
                                if Ability:IsA("ImageButton") and Ability.Lock.Visible == false and Ability.Mask.AbsoluteSize == Vector2.new(149.688, 0) then
                                    TrainUseAbilities = true
                                    TrainAbilityToUse = Ability
                                elseif Ability:IsA("ImageButton") and Ability.Lock.Visible == false and Ability.Mask.AbsoluteSize ~= Vector2.new(149.688, 0) then
                                    TrainUseAbilities = false
                                    TrainAbilityToUse = nil
                                end
                            end
                        end

                        if Distance <= 5 and TrainUseAbilities and TrainAbilityToUse ~= nil then
                            firesignal(TrainAbilityToUse.MouseButton1Click)
                        elseif Distance <= 5 and not TrainUseAbilities then
                            Network:Send(Client.Remotes.GeneralAttack)
                        end
                    elseif not Ghost then
                        TrainInfo:Set({Title = "Train Status:", Content = "Going to next stage..."})
                        TrainFuncs:TrainTeleport(workspace.Train.Portal.Next)

                        firesignal(OpenButton.MouseButton1Click)
                        firesignal(ReceiveButton.MouseButton1Click)

                        fireproximityprompt(workspace.Train.Train.ContinueTrigger.ProximityPrompt)
                    end
                end
            end)
        elseif not AutoTrain then
            TrainInfo:Set({Title = "Train Status:", Content = "Awaiting Toggle..."})
        end
    end,
})

local Attack = Window:CreateTab('AF Settings')
Attack:CreateSection("Auto Attack Settings")

local Levels = {}
for _, Level in next, workspace.GhostPos:GetChildren() do
    if Level:IsA("Folder") and not table.find(Levels, Level.Name) then
        table.insert(Levels, Level.Name)
    end
end

Attack:CreateDropdown({
    Name = "Enemy Level",
    Options = Levels,
    CurrentOption = "Leve1",
    Callback = function(EnemyLevel)
        shared.EnemyLevel = EnemyLevel
    end,
})

Attack:CreateDropdown({
    Name = "Auto Attack Mode",
    Options = {
        "Closest Enemy",
        "Highest HP",
        "Lowest HP",
    },
    CurrentOption = "Closest Enemy",
    Callback = function(AutoAttackMode)
        shared.AutoAttackMode = AutoAttackMode
    end,
})

Attack:CreateDropdown({
    Name = "Teleport Method",
    Options = {
        "PivotTo",
        "TweenTo",
        "MoveTo"
    },
    CurrentOption = "PivotTo",
    Callback = function(TeleportMethod)
        shared.TeleportMethod = TeleportMethod

        if TeleportMethod == "MoveTo" then
            local Distance = (workspace.Maps.Brama.brama.Position - HumanoidRootPart.Position).Magnitude

            if Distance < 50 then
                Character:PivotTo(workspace.Maps.Brama.brama.CFrame * CFrame.Angles(0, math.rad(180), 0))
            end
        end
    end,
})

Attack:CreateSlider({
    Name = "Tween Delay", 
    Range = {0, 5},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(TweenDelay)
        shared.TweenDelay = TweenDelay
    end,
})

local TrainAttack = Window:CreateTab('AT Settings')
TrainAttack:CreateSection("Auto Attack Train Settings")

TrainAttack:CreateDropdown({
    Name = "Train Teleport Method",
    Options = {
        "PivotTo",
        "TweenTo",
        "MoveTo"
    },
    CurrentOption = "PivotTo",
    Callback = function(TrainTeleportMethod)
        shared.TrainTeleportMethod = TrainTeleportMethod
    end,
})

TrainAttack:CreateSlider({
    Name = "Train Tween Delay", 
    Range = {0, 5},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(TrainTweenDelay)
        shared.TrainTweenDelay = TrainTweenDelay
    end,
})

local Egg = Window:CreateTab('Egg')
Egg:CreateSection("Auto Egg")

Egg:CreateToggle({
    Name = "Auto Egg",
    CurrentValue = false,
    Callback = function(AutoEgg)
        EggFuncs:AutoEgg(AutoEgg)
    end,
})

local Tele = Window:CreateTab('Teleport')
Tele:CreateSection("Teleports")

Tele:CreateDropdown({
    Name = "Teleport",
    Options = {
        "Spawn",
        "Pet Shop",
        "Clothing Shop",
        "Character Shop",
        "Luck Draw",
    },
    CurrentOption = "Select a Teleport",
    Callback = function(Teleport)
        if Teleport == "Spawn" then
            Character:PivotTo(workspace.Maps.Brama.brama.CFrame * CFrame.Angles(0, math.rad(180), 0))
        elseif Teleport == "Pet Shop" then
            Character:PivotTo(workspace.PetShop["Pet_4"].RootPart.CFrame)
        elseif Teleport == "Clothing Shop" then
            Character:PivotTo(workspace["ClothShop_NPC"]["ClothShop_1"].ShopTouch.CFrame)
        elseif Teleport == "Character Shop" then
            Character:PivotTo(workspace.CharaterShop.Touch.CFrame * CFrame.Angles(0, math.rad(270), 0) * CFrame.new(0, 0, 10))
        elseif Teleport == "Luck Draw" then
            Character:PivotTo(workspace.Maps.LuckDraw.CameraPos.CFrame)
        end
    end,
})

Rayfield:LoadConfiguration()
