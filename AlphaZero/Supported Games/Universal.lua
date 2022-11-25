local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Request = (syn and syn.request) or request or http_Request or (http and http.request)
local Camera = workspace.CurrentCamera
local CurrentTarget = nil
local Entity
local FOVMake

local Connections = {
	CharacterAdded = {},
}

table.insert(Connections.CharacterAdded, LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char
	Humanoid = Char:WaitForChild("Humanoid")
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
end))

local EntityLib = {}; do
    function EntityLib:Require(url)
        local response = Request({
            Url = url,
            Method = "GET",
        })
        if response.StatusCode == 200 then
            return response.Body
        end
    end
    function EntityLib:Run(code)
        local func, err = loadstring(code)
        if not typeof(func) == 'function' then
            return error("Failed to run code, error: " .. tostring(err))
        end
        return func()
    end
    function EntityLib:IsAlive(plr, stateCheck)
        local _, ent
        pcall(function()
            if not plr then 
                return Entity.isAlive 
            end
            _, ent = Entity.getEntityFromPlayer(plr)
        end)
        return ((not stateCheck) or ent and ent.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and ent
    end
end
local Fov = {}; do
    local Loops = {RenderStepped = {}, Heartbeat = {}, Stepped = {}}
    function Fov:BindToRenderStepped(id, callback)
        if not Loops.RenderStepped[id] then
            Loops.RenderStepped[id] = RunService.RenderStepped:Connect(callback)
        end
    end
    function Fov:UnbindFromRenderStepped(id)
        if Loops.RenderStepped[id] then
            Loops.RenderStepped[id]:Disconnect()
            Loops.RenderStepped[id] = nil
        end
    end
    function Fov:Make()
        local FOV = Drawing.new("Circle")
        FOV.Visible = false
        FOV.Thickness = 1
        FOV.NumSides = 100
        FOV.Radius = 100
        FOV.Color = Color3.fromRGB(255, 255, 255)
        FOV.Transparency = 1
        FOV.Filled = false
        return FOV
    end
    FOVMake = Fov:Make()
    function Fov:Update()
        getgenv().FOVRadius = shared.FOVSize or 100
        FOVMake.Position = Vector2.new(Mouse.X, Mouse.Y + 30)
        FOVMake.Visible = true
        FOVMake.Radius = FOVRadius
    end
    function Fov:Toggle(boolean)
        if boolean then
            self:BindToRenderStepped("FOV", function()
                self:Update()
            end)
        else
            self:UnbindFromRenderStepped("FOV")
            FOVMake.Visible = false
        end
    end
end
local Aimbot = {}; do
	local Loops = {RenderStepped = {}, Heartbeat = {}, Stepped = {}}
	function Aimbot:BindToRenderStepped(id, callback)
		if not Loops.RenderStepped[id] then
			Loops.RenderStepped[id] = RunService.RenderStepped:Connect(callback)
		end
	end
	function Aimbot:UnbindFromRenderStepped(id)
		if Loops.RenderStepped[id] then
			Loops.RenderStepped[id]:Disconnect()
			Loops.RenderStepped[id] = nil
		end
	end
	function Aimbot:IsHolding()
		return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end
    function Aimbot:StoreCurrentTarget()
        return CurrentTarget
    end
    function Aimbot:DistanceCheck(Player, Distance)
        shared.DistanceCheck = shared.DistanceCheck or true
        shared.Distance = shared.Distance or 1000

        if Distance and shared.DistanceCheck then
            return (Player.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude <= Distance
        else
            return true
        end
    end
    function Aimbot:TeamCheck(Player, Toggle)
		if Toggle then
			return Player.Team ~= LocalPlayer.Team
		else
			return true
		end
	end
    function Aimbot:VisibleCheck(Player, Toggle)
        getgenv().TargetPart = shared.TargetPart or "Head"
        if Toggle then
            local Parts = Camera:GetPartsObscuringTarget({Camera.CFrame.Position, Player.Character.HumanoidRootPart.Position}, {Player.Character})
            return #Parts == 0
        else
            return true
        end
    end
	function Aimbot:GetClosestPlayerToMouse()
		local ClosestPlayer = nil
		local ClosestPlayerDistance = math.huge
        getgenv().VisibleCheck = shared.VisibleCheck or false

		for _, Player in next, Players:GetPlayers() do
			if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
				local ScreenPoint = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)
				local MousePoint = Vector2.new(Mouse.X, Mouse.Y)
				local Distance = (MousePoint - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                local _, OnScreen = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)

				if Distance < ClosestPlayerDistance and OnScreen and Aimbot:DistanceCheck(Player, shared.Distance) and Aimbot:TeamCheck(Player, shared.TeamCheck) and Aimbot:VisibleCheck(Player, shared.VisibleCheck) then
					ClosestPlayer = Player
					ClosestPlayerDistance = Distance
				end
			end
		end

		return ClosestPlayer
	end
    function Aimbot:GetClosestFromDistance()
        local ClosestPlayer = nil
        local ClosestPlayerDistance = math.huge
        getgenv().VisibleCheck = shared.VisibleCheck or false

        for _, Player in next, Players:GetPlayers() do
            if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                local Distance = (Player.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                local _, OnScreen = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)

                if Distance < ClosestPlayerDistance and OnScreen and Aimbot:DistanceCheck(Player, shared.Distance) and Aimbot:TeamCheck(Player, shared.TeamCheck) and Aimbot:VisibleCheck(Player, shared.VisibleCheck) then
                    ClosestPlayer = Player
                    ClosestPlayerDistance = Distance
                end
            end
        end

        return ClosestPlayer
    end
    function Aimbot:GetClosestFromFOV()
        local ClosestPlayer = nil
        local ClosestPlayerDistance = math.huge
        getgenv().VisibleCheck = shared.VisibleCheck or false

        for _, Player in next, Players:GetPlayers() do
            if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                local ScreenPoint = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)
                local MousePoint = Vector2.new(Mouse.X, Mouse.Y)
                local Distance = (MousePoint - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                local _, OnScreen = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)

                if Distance < ClosestPlayerDistance and OnScreen and Aimbot:DistanceCheck(Player, shared.Distance) and Aimbot:TeamCheck(Player, shared.TeamCheck) and Aimbot:VisibleCheck(Player, shared.VisibleCheck) and Distance <= FOVRadius then
                    ClosestPlayer = Player
                    ClosestPlayerDistance = Distance
                end
            end
        end

        return ClosestPlayer
    end
    function Aimbot:GetClosestTargetPart()
        local ClosestPart = nil
        local ClosestPartDistance = math.huge
        getgenv().VisibleCheck = shared.VisibleCheck or false

        for _, Part in next, CurrentTarget.Character:GetDescendants() do
            if Part:IsA("BasePart") and Part.CanCollide and Part.Name ~= "HumanoidRootPart" then
                local ScreenPoint = Camera:WorldToViewportPoint(Part.Position)
                local MousePoint = Vector2.new(Mouse.X, Mouse.Y)
                local Distance = (MousePoint - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                local _, OnScreen = Camera:WorldToViewportPoint(Part.Position)

                if Distance < ClosestPartDistance and OnScreen and Aimbot:DistanceCheck(CurrentTarget, shared.Distance) and Aimbot:TeamCheck(CurrentTarget, shared.TeamCheck) and Aimbot:VisibleCheck(CurrentTarget, shared.VisibleCheck) then
                    ClosestPart = Part
                    ClosestPartDistance = Distance
                end
            end
        end

        return ClosestPart
    end
    function Aimbot:DoMethod()
        shared.Method = shared.Method or "Closest To Mouse"

        if shared.Method == "Closest To Mouse" then
            return self:GetClosestPlayerToMouse()
        elseif shared.Method == "Distance" then
            return self:GetClosestFromDistance()
        elseif shared.Method == "FOV" then
            return self:GetClosestFromFOV()
        end
    end
	Aimbot:StoreCurrentTarget(Aimbot:DoMethod())
	function Aimbot:Update()
		getgenv().Smoothness = shared.Smoothness or .25
		getgenv().TeamCheck = shared.TeamCheck or false
        getgenv().SelectedView = shared.SelectedView or "First Person"
        getgenv().TargetPart = shared.TargetPart or "Head"
        local GetClosest = self:DoMethod()

		if GetClosest and GetClosest.Character then
            if self:IsHolding() and self:TeamCheck(GetClosest, TeamCheck) then
                local Vector = Camera:WorldToViewportPoint(GetClosest.Character:WaitForChild(TargetPart).Position)
                GetClosest = self:DoMethod()
				if SelectedView == "First Person" and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
					Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, GetClosest.Character:WaitForChild(TargetPart).Position), Smoothness)
				elseif SelectedView == "Third Person" and UIS.MouseBehavior == Enum.MouseBehavior.Default then
					mousemoverel((Vector.X - Mouse.X) / 2 * Smoothness, (Vector.Y - Mouse.Y - 35) / 2 * Smoothness)
                elseif SelectedView == "Auto" then
                    if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
                        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, GetClosest.Character:WaitForChild(TargetPart).Position), Smoothness)
                    elseif UIS.MouseBehavior == Enum.MouseBehavior.Default then
                        mousemoverel((Vector.X - Mouse.X) / 2 * Smoothness, (Vector.Y - Mouse .Y - 35) / 2 * Smoothness)
                    end
				end
			end
		else
			GetClosest = self:DoMethod()
		end
	end
	function Aimbot:Toggle(boolean)
		if boolean then
			self:BindToRenderStepped("Aimbot", function()
				self:Update()
			end)
		else
			self:UnbindFromRenderStepped("Aimbot")
		end
	end
end
local Triggerbot = {}; do
    local Loops = {RenderStepped = {}, Heartbeat = {}, Stepped = {}}
	function Triggerbot:BindToRenderStepped(id, callback)
		if not Loops.RenderStepped[id] then
			Loops.RenderStepped[id] = RunService.RenderStepped:Connect(callback)
		end
	end
	function Triggerbot:UnbindFromRenderStepped(id)
		if Loops.RenderStepped[id] then
			Loops.RenderStepped[id]:Disconnect()
			Loops.RenderStepped[id] = nil
		end
	end
    function Triggerbot:TriggerBotUpdate()
        local MouseTarget = Mouse.Target
        getgenv().Delay = shared.Delay or 0

        if MouseTarget and MouseTarget.Parent and MouseTarget.Parent:FindFirstChild("Humanoid") and MouseTarget.Parent ~= Character and UIS.MouseBehavior ~= Enum.MouseBehavior.Default then 
            task.delay(Delay, function()
                mouse1click()
            end)
        end
    end
    function Triggerbot:TriggerBotToggle(boolean)
        if boolean then
            self:BindToRenderStepped("TriggerBot", function()
                self:TriggerBotUpdate()
            end)
        else
            self:UnbindFromRenderStepped("TriggerBot")
        end
    end
end
local Esp = {}; do
    Instance.new("ScreenGui",game.CoreGui).Name = "Kaoru"
    local ChamsFolder = Instance.new("Folder")
    ChamsFolder.Name = "ChamsFolder"
    for _,v in next, game.CoreGui:GetChildren() do
        if v:IsA'ScreenGui' and v.Name == 'Kaoru' then
            ChamsFolder.Parent = v
        end
    end
    Players.PlayerRemoving:Connect(function(plr)
        if ChamsFolder:FindFirstChild(plr.Name) then
            ChamsFolder[plr.Name]:Destroy()
        end
    end)
    local Loops = {RenderStepped = {}, Heartbeat = {}, Stepped = {}}
    function Esp:BindToRenderStepped(id, callback)
        if not Loops.RenderStepped[id] then
            Loops.RenderStepped[id] = RunService.RenderStepped:Connect(callback)
        end
    end
    function Esp:UnbindFromRenderStepped(id)
        if Loops.RenderStepped[id] then
            Loops.RenderStepped[id]:Disconnect()
            Loops.RenderStepped[id] = nil
        end
    end
    function Esp:TeamCheck(Player, Toggle)
        if Toggle then
            return Player.Team ~= LocalPlayer.Team
        else
            return true
        end
    end
    function Esp:Update()
        getgenv().TeamCheck = shared.TeamCheck or false

        for _, Player in next, Players:GetChildren() do
            if ChamsFolder:FindFirstChild(Player.Name) then
                Chams = ChamsFolder[Player.Name]
                Chams.Enabled = false
                Chams.FillColor = Color3.fromRGB(255, 255, 255)
                Chams.OutlineColor = Color3.fromHSV(tick()%5/5,1,1)
            end
            if Player ~= LocalPlayer and Player.Character and self:TeamCheck(Player, TeamCheck) then
                if ChamsFolder:FindFirstChild(Player.Name) == nil then
                    local chamfolder = Instance.new("Highlight")
                    chamfolder.Name = Player.Name
                    chamfolder.Parent = ChamsFolder
                    Chams = chamfolder
                end
                Chams.Enabled = true
                Chams.Adornee = Player.Character
                Chams.OutlineTransparency = 0
                Chams.DepthMode = Enum.HighlightDepthMode[(true and "AlwaysOnTop" or "Occluded")]
                Chams.FillTransparency = 1
            end
        end
    end
    function Esp:Toggle(boolean)
        if boolean then
            self:BindToRenderStepped("Esp", function()
                self:Update()
            end)
        else
            self:UnbindFromRenderStepped("Esp")
            ChamsFolder:ClearAllChildren()
        end
    end
end
local WhiteList = {}; do
    local WhiteListed = {}
    function WhiteList:GetPlayers()
        local PlayerTable = {}
        for _, Player in next, Players:GetPlayers() do
            if Player ~= LocalPlayer and not table.find(WhiteListed, Player) then
                table.insert(PlayerTable, Player.Name)
            end
        end
        return PlayerTable
    end
    function WhiteList:GetWhiteListedPlayers()
        return WhiteListed
    end
    function WhiteList:AddPlayer(Player)
        if not table.find(WhiteListed, Player) then
            table.insert(WhiteListed, Player)
        end
    end
    function WhiteList:RemovePlayer(Player)
        if table.find(WhiteListed, Player) then
            table.remove(WhiteListed, table.find(WhiteListed, Player))
        end
    end
    function WhiteList:RemoveAll()
        table.clear(WhiteListed)
    end
end

Entity = EntityLib:Run(EntityLib:Require("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/Libraries/entityHandler.lua", true, true))
Entity.fullEntityRefresh()

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
local Window = Rayfield:CreateWindow({
	Name = "FPS Universal V1.1.0",
	LoadingTitle = "FPS Universal",
	LoadingSubtitle = "By: Kaoru~#6438",
	ConfigurationSaving = {
		Enabled = false,
		FolderName = "FPS-Universal-Kaoru",
		FileName = "reddyhub"
	},
})

local Main = Window:CreateTab('Main')
Main:CreateSection("Aimbot")

Main:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(AimAssistToggle)
        Aimbot:Toggle(AimAssistToggle)
    end,
})

Main:CreateSection("Aimbot Settings")

Main:CreateDropdown({
    Name = "Method",
    Options = {"Closest To Mouse", "Distance", "FOV"},
    CurrentOption = "Closest To Mouse",
    Callback = function(Method)
        Aimbot.Method = Method
    end,
})

Main:CreateDropdown({
    Name = "Target Part",
    Options = {
        "Head",
        "Torso",
    },
    CurrentOption = "Head",
    Callback = function(TargetPart)
        if TargetPart == "Torso" then
            shared.TargetPart = "HumanoidRootPart"
        elseif TargetPart ~= "Torso" then
            shared.TargetPart = TargetPart
        end
    end,
})

Main:CreateDropdown({
    Name = "Selected View",
    Options = {"First Person", "Third Person", "Auto"},
    CurrentOption = "First Person",
    Callback = function(SelectedView)
        shared.SelectedView = SelectedView
    end,
})

Main:CreateSlider({
    Name = "Smoothness",
    Range = {0, 1},
    Increment = .01,
    CurrentValue = .25,
    Callback = function(Smoothness)
        shared.Smoothness = Smoothness
    end,
})

Main:CreateToggle({
    Name = "Distance Check",
    CurrentValue = true,
    Callback = function(DistanceCheckToggle)
        shared.DistanceCheck = DistanceCheckToggle
    end,
})

Main:CreateSlider({
    Name = "Distance",
    Range = {0, 1000},
    Increment = 1,
    CurrentValue = 1000,
    Callback = function(Distance)
        shared.Distance = Distance
    end,
})

Main:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(TeamCheckToggle)
        shared.TeamCheck = TeamCheckToggle
    end,
})

Main:CreateToggle({
    Name = "Visible Check",
    CurrentValue = false,
    Callback = function(VisibleCheckToggle)
        shared.VisibleCheck = VisibleCheckToggle
    end,
})

Main:CreateSection("Triggerbot")

Main:CreateToggle({
    Name = "Triggerbot",
    CurrentValue = false,
    Callback = function(Trigger)
        Triggerbot:TriggerBotToggle(Trigger)
    end,
})

Main:CreateSection("Triggerbot Settings")

Main:CreateSlider({
    Name = "Delay",
    Range = {0, 1},
    Increment = .01,
    CurrentValue = 0,
    Callback = function(Delay)
        shared.Delay = Delay
    end,
})

Main:CreateSection("FOV")

Main:CreateToggle({
    Name = "FOV",
    CurrentValue = false,
    Callback = function(FOVToggle)
        Fov:Toggle(FOVToggle)
    end,
})

Main:CreateSlider({
    Name = "FOV Size",
    Range = {0, 1000},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(FOVSize)
        shared.FOVSize = FOVSize
    end,
})

Main:CreateSection("Esp")

Main:CreateToggle({
    Name = "Esp",
    CurrentValue = false,
    Callback = function(EspToggle)
        Esp:Toggle(EspToggle)
    end,
})

Main:CreateSection("Esp Settings")

Main:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(ESPTeamCheck)
        shared.ESPTeamCheck = ESPTeamCheck
    end,
})
