local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local Humanoid = Character:WaitForChild("Humanoid");
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart");
local VirtualUser = game:GetService("VirtualUser");
local Camera = workspace.CurrentCamera;
local Mouse = LocalPlayer:GetMouse();
local UIS = game:GetService("UserInputService");

local ESPColor, RainbowESP = Color3.fromRGB(255, 255, 255), false;
local ESPToggle, OldEspColor = false, Color3.fromRGB(255, 255, 255);
local ChamsColor, RainbowChams = Color3.fromRGB(255, 255, 255), false;
local Nametags = false;
local Tracers = false;
local TeamCheck = false;
local FOV = false;
local FOVSize, FOVFollowMouse = 100, false;

local MarketplaceService = game:GetService("MarketplaceService");
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name;

LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char
	Humanoid = Char:WaitForChild("Humanoid")
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController();
    VirtualUser:ClickButton2(Vector2.new(0,0));
end)

local function GetCorners(Part)
    local Size = Part.Size * Vector3.new(1, 1.5)
    return {
        TopRight = (Part.CFrame * CFrame.new(-Size.X, -Size.Y, 0)).Position;
        BottomRight = (Part.CFrame * CFrame.new(-Size.X, Size.Y, 0)).Position;
        TopLeft = (Part.CFrame * CFrame.new(Size.X, -Size.Y, 0)).Position;
        BottomLeft = (Part.CFrame * CFrame.new(Size.X, Size.Y, 0)).Position;
    };
end

local function IsAlive(Player)
    return Player and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0;
end

local function IsHolding()
    return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
end

local function IsOnScreen(Part)
    local _, OnScreen = Camera:WorldToViewportPoint(Part.Position);

    return OnScreen;
end

local function IsVisible(Player)
    local Parts = Camera:GetPartsObscuringTarget({Camera.CFrame.Position, Player.Character.HumanoidRootPart.Position}, {Player.Character})

    for Index, Part in next, Parts do
        if Part.Transparency == 1 or Part.CanCollide == false then
            Parts[Index] = nil;
        end
    end

    return #Parts == 0;
end

local function IsTeam(Player, Toggle)
    return not Toggle or Player.Team ~= LocalPlayer.Team;
end

local function IsInFOV(Player, FOVSize, Toggle)
    local Vector, OnScreen = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position);

    return not Toggle or OnScreen and (Vector2.new(Vector.X, Vector.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude <= FOVSize;
end

local function DoChecks(Player)
    return Player and IsHolding() and IsVisible(Player);
end

local function AimAt(Player, TargetPart, Smoothness)
    Player = Player or error("No player provided");
    TargetPart = TargetPart or "Head";
    Smoothness = Smoothness or 1;

    if Player and Player.Character and Player.Character:FindFirstChild(TargetPart) then
        if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Player.Character[TargetPart].Position), Smoothness);
        end
    end
end

local function Triggerbot()
    --[[

        1. Local variable MouseTarget is assigned to the current target of the mouse.

        2. If MouseTarget exists and its parent exists and its parent has a Humanoid child and its parent has a HumanoidRootPart child then continue.
            - MouseTarget is the target of the mouse.
            - MouseTarget.Parent is the parent of the target of the mouse.
            - MouseTarget.Parent:FindFirstChild("Humanoid") is the Humanoid child of the parent of the target of the mouse.
            - MouseTarget.Parent:FindFirstChild("HumanoidRootPart") is the HumanoidRootPart child of the parent of the target of the mouse.

        3. If the parent of MouseTarget is not the same as the character of the player that is running the script and if the mouse's behavior is set to Enum.MouseBehavior.LockCenter then continue.
            - MouseTarget.Parent is the parent of the target of the mouse.
            - LocalPlayer.Character is the character of the player that is running the script.
            - UIS.MouseBehavior is the current behavior of the mouse.
            - UIS.MouseBehavior == Enum.MouseBehavior.LockCenter checks if the mouse's behavior is set to Enum.MouseBehavior.LockCenter.

        4. If the Players service has a child with the same name as the parent of MouseTarget then continue.
            - Players is the Players service.
            - Players[MouseTarget.Parent.Name] is the child of the Players service with the same name as the parent of the target of the mouse.

        5. If the player with the same name as the parent of MouseTarget is alive and if the player with the same name as the parent of MouseTarget is on the same team as the player running the script then continue.
            - Players[MouseTarget.Parent.Name] is the player with the same name as the parent of the target of the mouse.
            - TeamCheck is the team of the player running the script.

        6. Click the left mouse button.

    ]]--

    local MouseTarget = Mouse.Target;

    if MouseTarget and MouseTarget.Parent and MouseTarget.Parent:FindFirstChild("Humanoid") and MouseTarget.Parent:FindFirstChild("HumanoidRootPart") then
        if MouseTarget.Parent ~= LocalPlayer.Character and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
            if Players:FindFirstChild(MouseTarget.Parent.Name) then
                if IsAlive(Players[MouseTarget.Parent.Name]) and IsTeam(Players[MouseTarget.Parent.Name], TeamCheck) then
                    mouse1click()
                end
            end
        end
    end
end

local GetClosest = {}; do
    function GetClosest:Player()
        local ClosestPlayer = nil;
        local ClosestDistance = math.huge;

        for _, Player in next, Players:GetPlayers() do
            if Player and Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                -- Check if the player is on your team
                if IsTeam(Player, TeamCheck) and IsAlive(Player) and IsInFOV(Player, FOVSize, FOV) then
                    -- Find the distance between you and the player
                    local Distance = (HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude;

                    -- Check if the player is on screen
                    if Distance < ClosestDistance and IsOnScreen(Player.Character.HumanoidRootPart) then
                        ClosestPlayer = Player;
                        ClosestDistance = Distance;
                    end
                end
            end
        end

        return ClosestPlayer;
    end;

    function GetClosest:ToMouse()
        local ClosestPlayer = nil;
        local ClosestDistance = math.huge;

        for _, Player in next, Players:GetPlayers() do
            if Player and Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                -- Check if the player is on your team
                if IsTeam(Player, TeamCheck) and IsAlive(Player) then
                    -- Find the distance between the mouse and the player
                    local Distance = (Mouse.Hit.Position - Player.Character.HumanoidRootPart.Position).Magnitude;
                    -- Check if the player is on screen
                    if Distance < ClosestDistance and IsOnScreen(Player.Character.HumanoidRootPart) then
                        ClosestPlayer = Player;
                        ClosestDistance = Distance;
                    end
                end
            end
        end

        return ClosestPlayer;
    end;
end

local function FormatNametag(Player)
    -- Check if the player exists and is valid
    if Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Humanoid") then
        -- Check if the player is dead
        if Player.Character.Humanoid.Health <= 0 then
            return ("[0] " .. Player.Name .. "| %sHP"):format(Player.Character.Humanoid.Health)
        end

        -- Return the formatted nametag
        return string.format("[%s] %s | %sHP",
        HumanoidRootPart and tostring(math.round((Player.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude)) or "N/A",
        Player.Name,
        tostring(math.round(Player.Character.Humanoid.Health)))
    end
end

local function DrawNametag(Player)
    -- Create a text object that will display the player's name.
    local Nametag = Drawing.new("Text");
    Nametag.Visible = true;
    Nametag.Text = "";
    Nametag.Size = 20;
    Nametag.Color = Color3.fromRGB(255, 255, 255);
    Nametag.Outline = true;

    local function UpdateNametag()
        -- Create a new task that will update the player's nametag every frame.
        task.spawn(function()
            while true do task.wait()
                -- If nametags are disabled, hide the nametag and stop the loop.
                if not Nametags then
                    Nametag.Visible = false;
                    break;
                end

                -- If rainbow nametags are enabled, set the nametag's color to a rainbow color.
                if RainbowESP then
                    Nametag.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1);
                else
                    -- Otherwise, set the nametag's color to white.
                    Nametag.Color = Color3.fromRGB(255, 255, 255);
                end

                -- Check if the player exists, is not the local player, has a character, and if the character has a HumanoidRootPart and a Head.
                if Player and Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Head") then
                    -- Get the player's head position on the screen.
                    local HeadPosition = Camera:WorldToViewportPoint(Player.Character.Head.Position);

                    -- Check if the player exists, nametags are enabled, is on the same team as the local player, is on screen, and is alive.
                    if Player and Nametags and IsTeam(Player, TeamCheck) and IsOnScreen(Player.Character.HumanoidRootPart) and IsAlive(Player) then
                        -- Set the nametag's text to the player's name, the distance to the player, and the player's health.
                        Nametag.Text = FormatNametag(Player);
                        Nametag.Font = 3
                        Nametag.Size = 16
                        Nametag.ZIndex = 2
                        Nametag.Visible = true
                        Nametag.Position = Vector2.new(HeadPosition.X - (Nametag.TextBounds.X / 2), HeadPosition.Y - (Nametag.TextBounds.Y * 1.25));
                        Nametag.Color = ESPColor
                    else
                        Nametag.Visible = false;
                    end
                else
                    Nametag.Visible = false;
                end
            end
        end)
    end
    coroutine.wrap(UpdateNametag)();
end

local function DrawESP(Player)
    -- Create the box
    local Box = Drawing.new("Quad");
    Box.Visible = false;
    Box.PointA = Vector2.new(0, 0);
    Box.PointB = Vector2.new(0, 0);
    Box.PointC = Vector2.new(0, 0);
    Box.PointD = Vector2.new(0, 0);
    Box.Color = Color3.fromRGB(255, 255, 255);
    Box.Thickness = 1;
    Box.Filled = false;

    local function UpdateESP()
        task.spawn(function()
            while true do task.wait()
                -- Check if esp is toggled on
                if not ESPToggle then
                    Box.Visible = false;
                    break;
                end

                -- Check if rainbow esp is toggled on
                if RainbowESP then
                    ESPColor = Color3.fromHSV(tick() % 5 / 5, 1, 1);
                else
                    ESPColor = OldEspColor;
                end

                -- Check if player exists
                if Player and Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    -- Get corners of the player
                    local Corners = GetCorners(Player.Character.HumanoidRootPart);
                    -- Get vectors of the player
                    local Vectors = {
                        Camera:WorldToViewportPoint(Corners.TopRight);
                        Camera:WorldToViewportPoint(Corners.BottomRight);
                        Camera:WorldToViewportPoint(Corners.BottomLeft);
                        Camera:WorldToViewportPoint(Corners.TopLeft);
                    };

                    -- Check if player is on the same team and is on screen
                    if IsTeam(Player, TeamCheck) and IsOnScreen(Player.Character.HumanoidRootPart) then

                        -- Update the box
                        Box.Visible = true;
                        Box.PointA = Vector2.new(Vectors[1].X, Vectors[1].Y);
                        Box.PointB = Vector2.new(Vectors[2].X, Vectors[2].Y);
                        Box.PointC = Vector2.new(Vectors[3].X, Vectors[3].Y);
                        Box.PointD = Vector2.new(Vectors[4].X, Vectors[4].Y);
                        Box.Color = ESPColor;
                    else
                        Box.Visible = false;
                    end
                else
                    Box.Visible = false;
                end
            end
        end)
    end
    coroutine.wrap(UpdateESP)();
end

local function DrawTracer(Player)
    -- Create the tracer
    local Tracer = Drawing.new("Line");
    Tracer.Visible = false;
    Tracer.From = Vector2.new(0, 0);
    Tracer.To = Vector2.new(0, 0);
    Tracer.Color = Color3.fromRGB(255, 255, 255);
    Tracer.Thickness = 1;

    -- Create the update loop
    local function UpdateTracer()
        task.spawn(function()
            while true do task.wait()
                -- Check if tracers are enabled
                if not Tracers then
                    Tracer.Visible = false;
                    break;
                end

                -- Check if rainbow esp is enabled
                if RainbowESP then
                    ESPColor = Color3.fromHSV(tick() % 5 / 5, 1, 1);
                else
                    ESPColor = OldEspColor;
                end

                -- Check if the player is valid
                if Player and Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    -- Check if the player is on the same team
                    if IsTeam(Player, TeamCheck) and IsOnScreen(Player.Character.HumanoidRootPart) and Player.Character:FindFirstChild("Head") then
                        -- Get the player's head position on the screen
                        local HeadPosition = Camera:WorldToViewportPoint(Player.Character.Head.Position);

                        -- Update the tracer
                        Tracer.Visible = true;
                        Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2);
                        Tracer.To = Vector2.new(HeadPosition.X, HeadPosition.Y);
                        Tracer.Color = ESPColor;
                    else
                        Tracer.Visible = false;
                    end
                else
                    Tracer.Visible = false;
                end
            end
        end)
    end
    coroutine.wrap(UpdateTracer)();
end

local function DrawFOV()
    -- Create the fov circle
    local FOVCircle = Drawing.new("Circle");
    FOVCircle.Visible = false;
    FOVCircle.Thickness = 1;
    FOVCircle.NumSides = 100;
    FOVCircle.Filled = false;
    FOVCircle.Color = Color3.fromRGB(255, 255, 255);
    FOVCircle.Radius = 0;
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2);

    -- Create the update loop
    local function UpdateFOV()
        task.spawn(function()
            while true do task.wait()
                -- Check if fov is enabled
                if not FOV then
                    FOVCircle.Visible = false;
                    break;
                end

                -- Check if rainbow esp is enabled
                if RainbowESP then
                    ESPColor = Color3.fromHSV(tick() % 5 / 5, 1, 1);
                else
                    ESPColor = OldEspColor;
                end

                -- Check if fov follow mouse is enabled
                if FOVFollowMouse then
                    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y);
                else
                    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2);
                end

                -- Update the fov circle
                FOVCircle.Visible = true;
                FOVCircle.Radius = FOVSize;
                FOVCircle.Color = ESPColor;
            end
        end)
    end
    coroutine.wrap(UpdateFOV)();
end

Instance.new("ScreenGui", game.CoreGui).Name = "Kaoru"
local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name = "ChamsFolder"
for _, GUI in next, game.CoreGui:GetChildren() do
    if GUI:IsA('ScreenGui') and GUI.Name == 'Kaoru' then
        ChamsFolder.Parent = GUI
    end
end
Players.PlayerRemoving:Connect(function(Player)
    if ChamsFolder:FindFirstChild(Player.Name) then
        ChamsFolder[Player.Name]:Destroy()
    end
end)

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))();
local Window = Rayfield:CreateWindow({
    Name = string.format("Project: AlphaZero | Universal Remake"),
    LoadingTitle = string.format("Project: AlphaZero | Universal Remake"),
    LoadingSubtitle = "By: Kaoru~#6438 and Sw1ndler#7733",
    Discord = {
        Enabled = true,
        Invite = "JdzPVMNFwY",
        RememberJoins = true,
     },
})

local AimbotTab = Window:CreateTab("Aimbot");
AimbotTab:CreateSection("Aimbot Toggles");

local Smoothness = 0.25;
local TargetPart = "HumanoidRootPart";

AimbotTab:CreateDropdown({
    Name = "Aimbot Method";
    Options = {"Closest To Crosshair", "Closest To Player"};
    CurrentOption = "Closest To Crosshair";
    Callback = function(Method)
        if Method == "Closest To Crosshair" then
            GetClosest = {
                Player = function()
                    return GetClosest:ToMouse();
                end;
            };
        elseif Method == "Closest To Player" then
            GetClosest = {
                Player = function()
                    return GetClosest:Player();
                end;
            };
        end
    end;
})

local AimbotToggle = false;
AimbotTab:CreateToggle({
    Name = "Aimbot";
    CurrentValue = false;
    Callback = function(AimbotValue)
        AimbotToggle = AimbotValue;

        task.spawn(function()
            while AimbotToggle do task.wait()
                local Player = GetClosest:Player();
                if DoChecks(Player) then
                    AimAt(Player, TargetPart, Smoothness);
                end
            end
        end)
    end;
})

local TriggerbotToggle = false;
AimbotTab:CreateToggle({
    Name = "Triggerbot";
    CurrentValue = false;
    Callback = function(TriggerbotValue)
        TriggerbotToggle = TriggerbotValue;

        task.spawn(function()
            while TriggerbotToggle do task.wait()
                Triggerbot();
            end
        end)
    end;
})

AimbotTab:CreateSection("Aimbot Settings");

AimbotTab:CreateToggle({
    Name = "Team Check";
    CurrentValue = false;
    Callback = function(TeamCheckValue)
        TeamCheck = TeamCheckValue;
    end;
})

AimbotTab:CreateDropdown({
    Name = "Target Part";
    Options = {"Head", "HumanoidRootPart"};
    CurrentOption = "Head";
    Callback = function(TargetPartValue)
        TargetPart = TargetPartValue;
    end;
})

AimbotTab:CreateSlider({
    Name = "Smoothness";
    Range = {0, 1};
    Increment = 0.001;
    CurrentValue = 0.25;
    Callback = function(SmoothnessValue)
        Smoothness = SmoothnessValue;
    end;
})

local VisualsTab = Window:CreateTab("Visuals");
VisualsTab:CreateSection("Visuals Toggles");

local ChamsToggle, OldChamsColor = false, Color3.fromRGB(255, 255, 255);
VisualsTab:CreateToggle({
    Name = "Chams";
    CurrentValue = false;
    Callback = function(ChamsValue)
        ChamsToggle = ChamsValue;

        task.spawn(function()
            while ChamsToggle do task.wait()
                if RainbowChams then
                    ChamsColor = Color3.fromHSV(tick() % 5 / 5, 1, 1);
                else
                    ChamsColor = OldChamsColor;
                end

                for _, Player in next, Players:GetPlayers() do
                    if ChamsFolder:FindFirstChild(Player.Name) then
                        Chams = ChamsFolder[Player.Name];
                        Chams.Enabled = false;
                        Chams.FillColor = Color3.fromRGB(255, 255, 255);
                        Chams.OutlineColor = ChamsColor;
                    end
                    if Player ~= LocalPlayer and Player.Character and IsTeam(Player, TeamCheck) then
                        if ChamsFolder:FindFirstChild(Player.Name) == nil then
                            local Highlight = Instance.new("Highlight");
                            Highlight.Name = Player.Name;
                            Highlight.Parent = ChamsFolder;
                            Chams = Highlight;
                        end
                        Chams.Enabled = true;
                        Chams.Adornee = Player.Character;
                        Chams.OutlineTransparency = 0;
                        Chams.DepthMode = Enum.HighlightDepthMode[(true and "AlwaysOnTop" or "Occluded")];
                        Chams.FillTransparency = 1;
                    end
                end

                if not ChamsToggle then
                    for _, Player in next, Players:GetPlayers() do
                        if ChamsFolder:FindFirstChild(Player.Name) then
                            Chams = ChamsFolder[Player.Name];
                            Chams.Enabled = false;
                            Chams:Destroy();
                        end
                    end
                    break;
                end
            end
        end)
    end;
})

VisualsTab:CreateToggle({
    Name = "ESP";
    CurrentValue = false;
    Callback = function(ESPValue)
        ESPToggle = ESPValue;

        if ESPToggle then
            for _, Player in next, Players:GetPlayers() do
                DrawESP(Player);
            end
        end
    end;
})

VisualsTab:CreateToggle({
    Name = "Nametags";
    CurrentValue = false;
    Callback = function(NametagsValue)
        Nametags = NametagsValue;

        if Nametags then
            for _, Player in next, Players:GetPlayers() do
                DrawNametag(Player);
            end
        end
    end;
})

VisualsTab:CreateToggle({
    Name = "Tracers";
    CurrentValue = false;
    Callback = function(TracersValue)
        Tracers = TracersValue;

        if Tracers then
            for _, Player in next, Players:GetPlayers() do
                DrawTracer(Player);
            end
        end
    end;
})

VisualsTab:CreateSection("FOV & FOV Settings");

VisualsTab:CreateToggle({
    Name = "Use FOV";
    CurrentValue = false;
    Callback = function(FOVValue)
        FOV = FOVValue;

        if FOV then
            DrawFOV();
        end
    end;
})

VisualsTab:CreateToggle({
    Name = "FOV Follow Mouse";
    CurrentValue = false;
    Callback = function(FOVFollowMouseValue)
        FOVFollowMouse = FOVFollowMouseValue;
    end;
})

VisualsTab:CreateSlider({
    Name = "FOV Size";
    Range = {0, 1000};
    Increment = 1;
    CurrentValue = 100;
    Callback = function(FOVSizeValue)
        FOVSize = FOVSizeValue;
    end;
})

Players.PlayerAdded:Connect(function(Player)
    if ESPToggle then
        DrawESP(Player);
    elseif Tracers then
        DrawTracer(Player);
    elseif Nametags then
        DrawNametag(Player);
    end
end)

VisualsTab:CreateSection("Visuals Settings");

VisualsTab:CreateToggle({
    Name = "Rainbow ESP";
    CurrentValue = false;
    Callback = function(RainbowESPValue)
        RainbowESP, RainbowChams = RainbowESPValue, RainbowESPValue;
    end;
})

VisualsTab:CreateColorPicker({
    Name = "ESP Color";
    Color = Color3.fromRGB(255, 255, 255);
    Callback = function(ESPColorValue)
        ESPColor, OldEspColor = ESPColorValue, ESPColorValue;
        ChamsColor, OldChamsColor = ESPColorValue, ESPColorValue;
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