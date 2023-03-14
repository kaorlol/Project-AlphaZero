local plr = game:GetService("Players").LocalPlayer
local mouse = plr:GetMouse()
local camera = game:GetService("Workspace").CurrentCamera

loadstring(game:HttpGet("https://raw.githubusercontent.com/Sw1ndlerScripts/RobloxScripts/main/funcs/utils.lua"))()


getgenv().config = {
    enabled = true,
    hitchance = 100,
    hitpart = "Random", -- "Head", "RootPart", "Random"
    fov = 300,
    fovVisible = false,
    wallbang = false
}

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.new(1, 0, 0)
fovCircle.Position = getScreenCenter()
fovCircle.NumSides = 100

fovCircle.Radius = 100
fovCircle.Visible = false

local raycastMod = require(game:GetService("ReplicatedStorage").GunSystem.Raycast)

old = hookfunction(raycastMod.Raycast, function(...)
    local plr = game.Players.LocalPlayer
    local player = getClosestPlayerToMouse(config.fov)

    if config.enabled and player and player.Character and player.Character:FindFirstChild("Head") then
        local matches = 0
    
        for _, part in pairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Blacklist
                params.FilterDescendantsInstances = {plr.Character}
                
                local direction = (part.Position - plr.Character.Head.Position).Unit * 9e9
                local ray = workspace:Raycast(plr.Character.HumanoidRootPart.Position, direction, params)
        
                if ray and ray.Instance:IsDescendantOf(player.Character) then
                    matches = matches + 1
                end
            end
        end
        
        local rand = math.random() * 100
        
        local behindWall = false
        
        if matches == 0 then
            behindWall = true
        end
        
        if config.wallbang then
            behindWall = false
        end

        if config.hitchance >= rand and behindWall == false then
            local hitpart
            if config.hitpart == 'Head' then
                hitpart = player.Character.Head
            end
            if config.hitpart == 'RootPart' then
                hitpart = player.Character.HumanoidRootPart
            end
            if config.hitpart == 'Random' then
                local parts = {}
                for i,v in pairs(player.Character:GetChildren()) do
                    if v:IsA("BasePart") then
                        table.insert(parts, v)
                    end
                end
            
                hitpart = parts[math.random(1, #parts)]
            end
            
            local origin = hitpart.Position - Vector3.new(0, 0, 1)
            local destination = Vector3.new(0, 0, 1) + hitpart.Position
            local direction = (destination - origin).Unit * 10
            local ray = workspace:Raycast(origin, direction)
            
            return ray, 0
        end

    end
    return old(...)
end)

local repo = 'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()

local Window = Library:CreateWindow({
    Title = 'Pistol 1v1',
    Center = true,
    AutoShow = true
})


local Main = Window:AddTab('Main')

local Toggles = Main:AddLeftGroupbox("Toggles") 
local Config = Main:AddRightGroupbox("Config") 


Toggles:AddToggle('SilentAimToggle', {
    Text = 'Silent Aim',
    Default = false,
    Tooltip = 'Toggles the silent aim',
    Callback = function(Value)
        config.enabled = Value
    end,
})

Config:AddSlider('HitChance', {
    Text = 'Hit Chance',
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        config.hitchance = value
    end,
})

Config:AddDropdown('HitPart', {
    Values = {"Head", "RootPart", "Random"},
    Default = 1, 
    Multi = false, 

    Text = 'Hit Part',
    Tooltip = 'What part to hit', 
    Callback = function(value)
        config.hitpart = value
    end,
})

Config:AddToggle("Wallbang", {
    Text = 'Wallbang',
    Default = false,
    Tooltip = 'Toggles the wallbang',
    Callback = function(Value)
        config.wallbang = Value
    end,
})

Config:AddToggle('ShowFovCircle', {
    Text = 'Show Fov Circle',
    Default = true,
    Tooltip = 'Toggles visibility of the fov circle',
    Callback = function(Value)
        fovCircle.Visible = Value
    end,
})

Config:AddSlider('FOV', {
    Text = 'FOV',
    Default = 300,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        config.fov = value
        fovCircle.Radius = value
    end,
})

