local Utils = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/AllUtils.lua")))();
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart");
local Humanoid = Character:WaitForChild("Humanoid");
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
local CornerESP = false;
local FreeCameraToggle = false;

local SprintKey = Enum.KeyCode.LeftShift;
local MovePosition = Vector2.new(0, 0)
local TargetMovePosition = MovePosition

local Y_Sensitivity = 300;
local X_Sensitivity = 300;

local LastRightButtonDown = Vector2.new(0, 0)
local RightMouseButtonDown = false

local TargetFOV = 70

local Sprinting = false;
local SprintingSpeed = 3;

local KeysDown = {};
local KeyMappings = {
    [Enum.KeyCode.W] = Vector3.new(0, 0, -1);
    [Enum.KeyCode.S] = Vector3.new(0, 0, 1);
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0);
    [Enum.KeyCode.D] = Vector3.new(1, 0, 0);
    [Enum.KeyCode.Space] = Vector3.new(0, 1, 0);
    [Enum.KeyCode.LeftControl] = Vector3.new(0, -1, 0);
};

local MarketplaceService = game:GetService("MarketplaceService");
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name;

LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char;
    Humanoid = Char:WaitForChild("Humanoid");
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart");
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController();
    VirtualUser:ClickButton2(Vector2.new(0,0));
end)

local GroupService = game:GetService("GroupService")
local CreatorId, PlaceId, JobId = game.CreatorId, game.PlaceId, game.JobId;
local TeleportService = game:GetService("TeleportService");
local HttpService = game:GetService("HttpService");
local Request = (syn and syn.request) or (http and http.request) or http_request;

local GroupId = nil;
if Players:GetPlayerByUserId(CreatorId) == nil then
    local Group = GroupService:GetGroupInfoAsync(CreatorId);
    GroupId = Group.Id;
end

local function GetWorstRank()
    local WorstRank = math.huge;
    local Group = GroupService:GetGroupInfoAsync(CreatorId);

    for _, Rank in next, Group.Roles do
        if Rank.Rank < WorstRank then
            WorstRank = Rank.Rank;
        end
    end

    return WorstRank;
end

local function IsAdmin(Player)
    local UserId = Player.UserId;

    if UserId == CreatorId then
        return true;
    elseif GroupId ~= nil then
        local InGroup = Player:IsInGroup(GroupId);
        local GroupRank = Player:GetRankInGroup(GroupId);
        local WorstRank = GetWorstRank();

        if InGroup and GroupRank > WorstRank then
            return true;
        end
    end

    return false;
end

local function ServerHop()
    local Servers = {};
    local Response = Request({Url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", PlaceId)});
    local Body = HttpService:JSONDecode(Response.Body);

    if Body and Body.data then
        for _, Server in next, Body.data do
            if type(Server) == "table" and tonumber(Server.playing) and tonumber(Server.maxPlayers) and Server.playing < Server.maxPlayers and Server.id ~= JobId then
                table.insert(Servers, 1, Server.id);
            end
        end
    end

    if #Servers > 0 then
        TeleportService:TeleportToPlaceInstance(PlaceId, Servers[math.random(1, #Servers)], LocalPlayer);
        Utils.Network:QueueOnTeleport([[
            repeat task.wait() until game:IsLoaded()

            local Network = loadstring(game:HttpGetAsync(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/Network.lua")))();
            Network:Notify("Server Hop", "Successfully Hopped To New Server", 5);

            loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/Supported%20Games/Universal.lua")))()
        ]])
    else
        Utils.Network:Notify("Server Hop", "No servers found to hop to", 10);
    end
end

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

local function IsSameTeam(Player, Toggle)
    return not Toggle or Player.Team ~= LocalPlayer.Team;
end

local function IsInFOV(Player, FOVSize, Toggle)
    local Vector, OnScreen = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position);

    return not Toggle or OnScreen and (Vector2.new(Vector.X, Vector.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude <= FOVSize;
end

local function DoChecks(Player)
    return Player and IsHolding() and IsVisible(Player);
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
                if IsAlive(Players[MouseTarget.Parent.Name]) and IsSameTeam(Players[MouseTarget.Parent.Name], TeamCheck) then
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
                if IsSameTeam(Player, TeamCheck) and IsAlive(Player) and IsInFOV(Player, FOVSize, FOV) then
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
                if IsSameTeam(Player, TeamCheck) and IsAlive(Player) then
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

    function GetClosest:PartFromMouse(Player)
        local ClosestPart = nil;
        local ClosestDistance = math.huge;

        for _, Part in next, Player.Character:GetChildren() do
            if Part:IsA("BasePart") then
                -- Find the distance between the mouse and the part
                local Distance = (Mouse.Hit.Position - Part.Position).Magnitude;
                -- Check if the part is on screen
                if Distance < ClosestDistance and IsOnScreen(Part) then
                    ClosestPart = Part.Name;
                    ClosestDistance = Distance;
                end
            end
        end

        return ClosestPart;
    end
end

local function FormatNametag(Player)
    -- Check if the player exists and is valid
    if Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Humanoid") then
        -- Check if the player is dead
        if not IsAlive(Player) or Player.Character.Humanoid.Health <= 0 then
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
                    if Player and Nametags and IsSameTeam(Player, TeamCheck) and IsOnScreen(Player.Character.HumanoidRootPart) and IsAlive(Player) then
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
                    if IsSameTeam(Player, TeamCheck) and IsOnScreen(Player.Character.HumanoidRootPart) and IsAlive(Player) then

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
                    if IsSameTeam(Player, TeamCheck) and IsOnScreen(Player.Character.HumanoidRootPart) and Player.Character:FindFirstChild("Head") then
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

-- This will make my life easier
local function NewLine(Color, Thickness)
    local Line = Drawing.new("Line");
    Line.Visible = false;
    Line.From = Vector2.new(0, 0);
    Line.To = Vector2.new(0, 0);
    Line.Color = Color;
    Line.Thickness = Thickness;
    return Line;
end

local EspFaceCamera  = true;
local function DrawCornerESP(Player)
    local Lines = {
        TopLeft1 = NewLine(Color3.fromRGB(255, 255, 255), 1);
        TopLeft2 = NewLine(Color3.fromRGB(255, 255, 255), 1);

        TopRight1 = NewLine(Color3.fromRGB(255, 255, 255), 1);
        TopRight2 = NewLine(Color3.fromRGB(255, 255, 255), 1);

        BottomLeft1 = NewLine(Color3.fromRGB(255, 255, 255), 1);
        BottomLeft2 = NewLine(Color3.fromRGB(255, 255, 255), 1);

        BottomRight1 = NewLine(Color3.fromRGB(255, 255, 255), 1);
        BottomRight2 = NewLine(Color3.fromRGB(255, 255, 255), 1);
    };

    local OrigenPart = Instance.new("Part")
    OrigenPart.Parent = workspace
    OrigenPart.Transparency = 1
    OrigenPart.CanCollide = false
    OrigenPart.Size = Vector3.new(1, 1, 1)
    OrigenPart.Position = Vector3.new(0, 0, 0)

    local function UpdateCornerESP()
        task.spawn(function()
            while true do task.wait()
                -- Check if corner esp is enabled
                if not CornerESP then
                    for _, Line in next, Lines do
                        Line.Visible = false;
                    end
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
                    if IsSameTeam(Player, TeamCheck) and IsOnScreen(Player.Character.HumanoidRootPart) and IsAlive(Player) then
                        OrigenPart.Size = Vector3.new(Player.Character.HumanoidRootPart.Size.X, Player.Character.HumanoidRootPart.Size.Y * 1.5, Player.Character.HumanoidRootPart.Size.Z)
                        OrigenPart.CFrame = CFrame.new(Player.Character.HumanoidRootPart.CFrame.Position, Camera.CFrame.Position)
                        local SizeX = OrigenPart.Size.X
                        local SizeY = OrigenPart.Size.Y
                        local TopLeft = Camera:WorldToViewportPoint((OrigenPart.CFrame * CFrame.new(SizeX, SizeY, 0)).Position)
                        local TopRight = Camera:WorldToViewportPoint((OrigenPart.CFrame * CFrame.new(-SizeX, SizeY, 0)).Position)
                        local BottomLeft = Camera:WorldToViewportPoint((OrigenPart.CFrame * CFrame.new(SizeX, -SizeY, 0)).Position)
                        local BottomRight = Camera:WorldToViewportPoint((OrigenPart.CFrame * CFrame.new(-SizeX, -SizeY, 0)).Position)

                        local Ratio = (Camera.CFrame.Position - Player.Character.HumanoidRootPart.Position).Magnitude;
                        local Offset = math.clamp(1 / Ratio * 750, 2, 300);

                        Lines.TopLeft1.From = Vector2.new(TopLeft.X, TopLeft.Y)
                        Lines.TopLeft1.To = Vector2.new(TopLeft.X + Offset, TopLeft.Y)
                        Lines.TopLeft2.From = Vector2.new(TopLeft.X, TopLeft.Y)
                        Lines.TopLeft2.To = Vector2.new(TopLeft.X, TopLeft.Y + Offset)

                        Lines.TopRight1.From = Vector2.new(TopRight.X, TopRight.Y)
                        Lines.TopRight1.To = Vector2.new(TopRight.X - Offset, TopRight.Y)
                        Lines.TopRight2.From = Vector2.new(TopRight.X, TopRight.Y)
                        Lines.TopRight2.To = Vector2.new(TopRight.X, TopRight.Y + Offset)

                        Lines.BottomLeft1.From = Vector2.new(BottomLeft.X, BottomLeft.Y)
                        Lines.BottomLeft1.To = Vector2.new(BottomLeft.X + Offset, BottomLeft.Y)
                        Lines.BottomLeft2.From = Vector2.new(BottomLeft.X, BottomLeft.Y)
                        Lines.BottomLeft2.To = Vector2.new(BottomLeft.X, BottomLeft.Y - Offset)

                        Lines.BottomRight1.From = Vector2.new(BottomRight.X, BottomRight.Y)
                        Lines.BottomRight1.To = Vector2.new(BottomRight.X - Offset, BottomRight.Y)
                        Lines.BottomRight2.From = Vector2.new(BottomRight.X, BottomRight.Y)
                        Lines.BottomRight2.To = Vector2.new(BottomRight.X, BottomRight.Y - Offset)

                        for _, Line in next, Lines do
                            Line.Color = ESPColor;
                            Line.Visible = true;
                        end
                    else
                        for _, Line in next, Lines do
                            Line.Visible = false;
                        end
                    end
                else
                    for _, Line in next, Lines do
                        Line.Visible = false;
                    end
                end
            end
        end)
    end
    coroutine.wrap(UpdateCornerESP)();
end

local function AimAt(Player, TargetPart, Smoothness)
    Player = Player or error("No player provided");
    TargetPart = TargetPart or "Head";
    Smoothness = Smoothness or 1;

    if TargetPart == "Get Closest Part From Mouse" then
        TargetPart = GetClosest:PartFromMouse(Player);
    end

    if Player and Player.Character and Player.Character:FindFirstChild(TargetPart) then
        if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Player.Character[TargetPart].Position), Smoothness);
        end
    end
end

local function Tween(a, b, t)
    if t == 1 then
        return b
    else
        if tonumber(a) then
            return a * (1 - t) + (b * t)
        else
            return a:Lerp(b, t);
        end
    end
end

local function CalculateMovement()
    local NewMovement = Vector3.new(0, 0, 0)
    for Index,_ in next, KeysDown do
        NewMovement = NewMovement + (KeyMappings[Index] or Vector3.new(0, 0, 0))
    end
    return NewMovement
end

local function Input(Input)
    if KeyMappings[Input.KeyCode] then
        if Input.UserInputState == Enum.UserInputState.Begin then
            KeysDown[Input.KeyCode] = true
        elseif Input.UserInputState == Enum.UserInputState.End then
            KeysDown[Input.KeyCode] = nil
        end
    else
        if Input.UserInputState == Enum.UserInputState.Begin then
            if Input.UserInputType == Enum.UserInputType.MouseButton2 then
                RightMouseButtonDown = true
                LastRightButtonDown = Vector2.new(Mouse.X, Mouse.Y)
                UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            elseif Input.KeyCode == Enum.KeyCode.Z then
                TargetFOV = 20
            elseif Input.KeyCode == SprintKey then
                Sprinting = true
            end
        else
            if Input.UserInputType == Enum.UserInputType.MouseButton2 then
                RightMouseButtonDown = false
                UIS.MouseBehavior = Enum.MouseBehavior.Default
            elseif Input.KeyCode == Enum.KeyCode.Z then
                TargetFOV = 70
            elseif Input.KeyCode == SprintKey then
                Sprinting = false
            end
        end
    end
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
local TargetPart = "Head";

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
local AimbotTabToggle = AimbotTab:CreateToggle({
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
local TriggerbotTabToggle = AimbotTab:CreateToggle({
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

local TargetPartDropdown = AimbotTab:CreateDropdown({
    Name = "Target Part";
    Options = {"Head", "HumanoidRootPart", "Get Closest Part From Mouse"};
    CurrentOption = "Head";
    Callback = function(TargetPartValue)
        TargetPart = TargetPartValue;
    end;
})

local AimbotSmoothness = AimbotTab:CreateSlider({
    Name = "Smoothness";
    Range = {0, 1};
    Increment = 0.001;
    Suffix = "";
    CurrentValue = 0.25;
    Callback = function(SmoothnessValue)
        Smoothness = SmoothnessValue;
    end;
})

local VisualsTab = Window:CreateTab("Visuals");
VisualsTab:CreateSection("Visuals Toggles");

local ChamsToggle, OldChamsColor = false, Color3.fromRGB(255, 255, 255);
local ChamsTabToggle = VisualsTab:CreateToggle({
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
                    if Player ~= LocalPlayer and Player.Character and IsSameTeam(Player, TeamCheck) then
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

local ESPTabToggle = VisualsTab:CreateToggle({
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

local NametagsToggle = VisualsTab:CreateToggle({
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

local TracersToggle = VisualsTab:CreateToggle({
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

local CornerEspToggle = VisualsTab:CreateToggle({
    Name = "Corner ESP";
    CurrentValue = false;
    Callback = function(AngleEspValue)
        CornerESP = AngleEspValue;

        if CornerESP then
            for _, Player in next, Players:GetPlayers() do
                DrawCornerESP(Player);
            end
        end
    end;
})

VisualsTab:CreateSection("FOV & FOV Settings");

local FOVToggle = VisualsTab:CreateToggle({
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

local FOVSizeSlider = VisualsTab:CreateSlider({
    Name = "FOV Size";
    Range = {0, 1000};
    Increment = 1;
    Suffix = "";
    CurrentValue = 100;
    Callback = function(FOVSizeValue)
        FOVSize = FOVSizeValue;
    end;
})

Players.PlayerAdded:Connect(function(Player)
    if ESPToggle then
        DrawESP(Player);
    end

    if Tracers then
        DrawTracer(Player);
    end

    if Nametags then
        DrawNametag(Player);
    end

    if CornerESP then
        DrawCornerESP(Player);
    end
end)

VisualsTab:CreateSection("Visuals Settings");

local RainbowEspToggle = VisualsTab:CreateToggle({
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

local ConfigTab = Window:CreateTab("Creator Configs");
ConfigTab:CreateSection('Configs')

local SelectedConfig = "None";
ConfigTab:CreateDropdown({
    Name = "Config";
    Options = {"Rage", "Semi-Legit", "Legit"};
    CurrentOption = "None";
    Callback = function(ConfigValue)
        SelectedConfig = ConfigValue;
    end;
})

ConfigTab:CreateButton({
    Name = "Apply Config";
    CurrentValue = false;
    Callback = function()
        if SelectedConfig == "Rage" then
            AimbotTabToggle:Set(true);
            TriggerbotTabToggle:Set(true);
            RainbowEspToggle:Set(true);
            FOVToggle:Set(true);
            FOVSizeSlider:Set(1000);
            ChamsTabToggle:Set(true);
            TracersToggle:Set(true);
            NametagsToggle:Set(true);
            ESPTabToggle:Set(true);
            TargetPartDropdown:Set("Head");
            AimbotSmoothness:Set(1)
        elseif SelectedConfig == "Semi-Legit" then
            AimbotTabToggle:Set(true);
            TriggerbotTabToggle:Set(true);
            RainbowEspToggle:Set(true);
            FOVToggle:Set(true);
            FOVSizeSlider:Set(250);
            ChamsTabToggle:Set(true);
            TracersToggle:Set(true);
            NametagsToggle:Set(true);
            ESPTabToggle:Set(true);
            TargetPartDropdown:Set("HumanoidRootPart");
            AimbotSmoothness:Set(0.25)
        elseif SelectedConfig == "Legit" then
            AimbotTabToggle:Set(true);
            TriggerbotTabToggle:Set(false);
            RainbowEspToggle:Set(true);
            FOVToggle:Set(true);
            FOVSizeSlider:Set(175);
            ChamsTabToggle:Set(true);
            TracersToggle:Set(true);
            NametagsToggle:Set(true);
            ESPTabToggle:Set(true);
            TargetPartDropdown:Set("Get Closest Part From Mouse");
            AimbotSmoothness:Set(0.1)
        elseif SelectedConfig == "None" then
            return Utils.Network:Notify("Error", "Please select a valid config!", 5)
        end
    end;
})

local MiscTab = Window:CreateTab("Misc");
MiscTab:CreateSection('Misc')

local AdminDetecterToggle = false;
MiscTab:CreateToggle({
    Name = "Admin Detecter (Not 100% Accurate)";
    CurrentValue = false;
    Callback = function(AdminDetecterValue)
        AdminDetecterToggle = AdminDetecterValue;

        if AdminDetecterToggle then
            for _, Player in next, Players:GetPlayers() do
                if IsAdmin(Player) then
                    LocalPlayer:Kick(string.format("Admin Detected (%s), Server Hopping...", Player.Name));
                    ServerHop();
                end
            end
        end
    end;
})

MiscTab:CreateToggle({
    Name = "Free Camera";
    CurrentValue = false;
    Callback = function(FreeCameraValue)
        FreeCameraToggle = FreeCameraValue
    end;
})

local SprintKeyInput = MiscTab:CreateInput({
    Name = "Free Camera | Sprint Key";
    PlaceholderText = "Current Key: " .. SprintKey.Name;
    RemoveTextAfterFocusLost = false;
    Callback = function(Text)
        SprintKey = Enum.KeyCode[Text]
    end,
})

UIS.InputChanged:Connect(function(InputObject)
    if InputObject.UserInputType == Enum.UserInputType.MouseMovement then
        MovePosition = MovePosition + Vector2.new(InputObject.Delta.X, InputObject.Delta.Y)
    end
end)

Mouse.WheelForward:Connect(function()
    Camera.CoordinateFrame = Camera.CoordinateFrame * CFrame.new(0, 0, -5)
end)

Mouse.WheelBackward:Connect(function()
    Camera.CoordinateFrame = Camera.CoordinateFrame * CFrame.new(0, 0, 5)
end)

UIS.InputBegan:Connect(Input)
UIS.InputEnded:Connect(Input)

game:GetService("RunService").RenderStepped:Connect(function()
    --SprintKeyInput.PlaceholderText = "Current Key: " .. SprintKey.Name;
    if FreeCameraToggle then
        Camera.CameraType = Enum.CameraType.Scriptable
        HumanoidRootPart.Anchored = true
        Humanoid.PlatformStand = true

        TargetMovePosition = MovePosition
        Camera.CoordinateFrame = CFrame.new(Camera.CoordinateFrame.Position) *
        CFrame.fromEulerAnglesYXZ(-TargetMovePosition.Y/Y_Sensitivity ,-TargetMovePosition.X/X_Sensitivity, 0) *
        CFrame.new(CalculateMovement() * ((({[true] = SprintingSpeed})[Sprinting]) or 0.5))

        Camera.FieldOfView = Tween(Camera.FieldOfView, TargetFOV, 0.5)
        if RightMouseButtonDown then
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            MovePosition = MovePosition - (LastRightButtonDown - Vector2.new(Mouse.X,Mouse.Y))
            LastRightButtonDown = Vector2.new(Mouse.X,Mouse.Y)
        end
    else
        Humanoid.PlatformStand = false
        HumanoidRootPart.Anchored = false
        Camera.CameraSubject = Humanoid
        Camera.CameraType = "Custom"
    end
end)

Players.PlayerAdded:Connect(function(Player)
    if AdminDetecterToggle then
        if IsAdmin(Player) then
            LocalPlayer:Kick(string.format("Admin Detected (%s), Server Hopping...", Player.Name));
            ServerHop();
        end
    end
end)

local CreditsTab = Window:CreateTab("Credits");
CreditsTab:CreateSection('Credits')

CreditsTab:CreateParagraph({
    Title = "Who made this script?",
    Content = "Main Devs: Kaoru#6438 and Sw1ndler#7733; UI Dev: shlex#9425",
})

CreditsTab:CreateSection('Discord')
CreditsTab:CreateButton({
    Name = 'Join Discord',
    Callback = function()
        Utils.Network:SendInvite("JdzPVMNFwY")
    end;
})

Utils.Network:Notify("Loaded", string.format("Successfully Loaded AlphaZero for %s!", GameName), 5)

Utils.Network:QueueOnTeleport([[
    repeat task.wait() until game:IsLoaded()

    loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/Supported%20Games/Universal.lua")))()
]])