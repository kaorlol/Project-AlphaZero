getgenv().ESP_ENABLED = false
getgenv().esp_config = {
    Text = {
        Outline = true,
        Color = Color3.new(1,1,1),
        Size = 16,
        Enabled = true
    },
    Box = {
        Color = Color3.new(1,1,1),
        Thickness = 2,
        Enabled = true
    },
    Healthbar = {
        Enabled = true
    },
    Corners = {
        Enabled = true,
        Color = Color3.new(1,1,1)
    },
    Fill = {
        Enabled = true,
        Color = Color3.new(1,1,1),
        Transparency = 0
    },
    Tracer = {
        Enabled = true,
        Color = Color3.new(1,1,1),
        Thickness = 1,
        Origin = "Mouse" -- Center, Mouse, Bottom
    },
    TeamCheck = false,
    TeamColor = false,
}

local espObjects = {}
local camera = workspace.CurrentCamera
local lplr = game.Players.LocalPlayer
local mouse = lplr:GetMouse()
local uis = game:GetService("UserInputService")

do

function addBox(player)
    local hrp = player.Character.HumanoidRootPart

    local box = Drawing.new("Square")
    box.Color = Color3.new(0, 0, 0)
    box.Thickness = 1

    local function update()
        local vector, onScreen = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, -0.5, 0))
        local depth = vector.Z

        box.Size =  Vector2.new(3000 / depth, 4200 / depth)
        box.Position = Vector2.new(vector.X - (box.Size.X / 2), vector.Y - (box.Size.Y / 2))
    end

    table.insert(espObjects, {
        Update = update,
        Drawings = {box},
        Player = player,
        Type = 'Box'
    })
end

function addFill(player)
    local hrp = player.Character.HumanoidRootPart

    local box = Drawing.new("Square")
    box.Filled = true
    box.Color = Color3.new(0.611764, 0.062745, 0.062745)
    box.Thickness = 0

    local function update()
        local vector, _ = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, -0.5, 0))
        local depth = vector.Z

        box.Size =  Vector2.new(3000 / depth, 4200 / depth)
        box.Position = Vector2.new(vector.X - (box.Size.X / 2), vector.Y - (box.Size.Y / 2))
    end

    table.insert(espObjects, {
        Update = update,
        Drawings = {box},
        Player = player,
        Type = 'Fill'
    })
end

function addNametag(player)
    local head = player.Character.Head

    local text = Drawing.new("Text")
    text.Color = Color3.new(1, 1, 1)
    text.Center = false
    text.Outline = true
    text.Size = 16
    text.Text = player.Name

    local function update()
        local vector, _ = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))

        local center = Vector2.new(vector.X, vector.Y)
        local top = Vector2.new(center.X, center.Y)

        text.Position = Vector2.new(top.X - (text.TextBounds.X / 2), top.Y - (text.TextBounds.Y * 1.25));
    end


    table.insert(espObjects, {
        Update = update,
        Drawings = {text},
        Player = player,
        Type = "Text"
    })

end

function addHealthbar(player)
    local char = player.Character
    local hrp = char.HumanoidRootPart
    local hum = char.Humanoid

    local bar = Drawing.new("Line")
    bar.Transparency = 1
    bar.Thickness = 3
    bar.Color = Color3.new(255, 0, 0)
    
    local barBackground = Drawing.new("Line")
    barBackground.Transparency = 1
    barBackground.Thickness = 3
    barBackground.Color = Color3.new(0, 0, 0)
    barBackground.ZIndex = -1

    local function update()
        local vector, onScreen = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, -0.5, 0))

        local depth = vector.Z
        local size = Vector2.new(3000 / depth, 4200 / depth)
        local center = Vector2.new(vector.X, vector.Y)
        
        local side = Vector2.new(center.X - (size.X / 1.6), center.Y)
        local top = Vector2.new(side.X, side.Y - (size.Y / 2))
        local bottom = Vector2.new(side.X, side.Y + (size.Y / 2))

        barBackground.From = bottom
        barBackground.To = top
        bar.From = bottom
        bar.To = Vector2.new(top.X, bottom.Y - ((bottom.Y - top.Y) * hum.Health / hum.MaxHealth))

        bar.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), hum.Health / hum.MaxHealth)
    end
    
    table.insert(espObjects, {
        Update = update,
        Drawings = {bar, barBackground},
        Player = player,
        Type = "Healthbar"
    })
end

function addCorners(player)
    local hrp = player.Character.HumanoidRootPart

    local lines = {}
    for i=1, 8 do
        local line = Drawing.new("Line")
        line.Transparency = 1
        line.Visible = true
        line.Thickness = 2
        line.Color = Color3.new(1,1,1)
        table.insert(lines, line)
    end

    local function update()
        local vector, _ = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, -0.5, 0))
        local depth = vector.Z

        local size = Vector2.new(3000 / depth, 4200 / depth)
        local center = Vector2.new(vector.X, vector.Y)

        local positions = {
            {
                Vector2.new(center.X - (size.X / 2), center.Y - (size.Y / 2)),
                Vector2.new(center.X - (size.X / 2), center.Y - (size.Y / 2.6))
            },
            {
                Vector2.new(center.X - (size.X / 2), center.Y - (size.Y / 2)),
                Vector2.new(center.X - (size.X / 3), center.Y - (size.Y / 2))
            },
            {
                Vector2.new(center.X + (size.X / 2), center.Y - (size.Y / 2)),
                Vector2.new(center.X + (size.X / 2), center.Y - (size.Y / 2.6))
            },
            {
                Vector2.new(center.X + (size.X / 2), center.Y - (size.Y / 2)),
                Vector2.new(center.X + (size.X / 3), center.Y - (size.Y / 2))
            },
            {
                Vector2.new(center.X - (size.X / 2), center.Y + (size.Y / 2)),
                Vector2.new(center.X - (size.X / 2), center.Y + (size.Y / 2.6))
            },
            {
                Vector2.new(center.X - (size.X / 2), center.Y + (size.Y / 2)),
                Vector2.new(center.X - (size.X / 3), center.Y + (size.Y / 2))
            },
            {
                Vector2.new(center.X + (size.X / 2), center.Y + (size.Y / 2)),
                Vector2.new(center.X + (size.X / 2), center.Y + (size.Y / 2.6))
            },
            {
                Vector2.new(center.X + (size.X / 2), center.Y + (size.Y / 2)),
                Vector2.new(center.X + (size.X / 3), center.Y + (size.Y / 2))
            }
        }


        for i,v in pairs(lines) do
            v.From = positions[i][1]
            v.To = positions[i][2]
        end
    end

    table.insert(espObjects, {
        Update = update,
        Drawings = lines,
        Player = player,
        Type = "Corners"
    })
end

function addTracer(player) -- uncompleted
    local char = player.Character
    local hrp = char.HumanoidRootPart

    local tracer = Drawing.new("Line")
    tracer.Transparency = 1
    tracer.Thickness = 3
    tracer.Color = Color3.new(255, 0, 0)
    

    local function update()
        local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)

        local from
        if esp_config.Tracer.Origin == 'Center' then
            from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        end

        if esp_config.Tracer.Origin == 'Bottom' then
            from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
        end

        if esp_config.Tracer.Origin == 'Mouse' then
            local mousePos = uis:GetMouseLocation()
            from = Vector2.new(mousePos.X, mousePos.Y)
        end

        tracer.To = Vector2.new(vector.X, vector.Y)
        tracer.From = from        
    end
    
    table.insert(espObjects, {
        Update = update,
        Drawings = {tracer},
        Player = player,
        Type = "Tracer"
    })
end

function isvalidplayer(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head")
end



function initPlayer(player)
    task.spawn(function()
        repeat
            task.wait()
        until player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid")

        addBox(player)
        addNametag(player)
        addHealthbar(player)
        addCorners(player)
        addFill(player)
        addTracer(player)


        -- player.CharacterAdded:Connect(function()
        --     repeat task.wait() until isvalidplayer(player)

        --     addFill(player)
        --     addCorners(player)
        --     addBox(player)
        --     addNametag(player)
        --     addHealthbar(player)
        --     addTracer(player)
        -- end)
    end)
end

-- for i,v in pairs(game.Players:GetChildren()) do
--     initPlayer(v)
-- end

-- game.Players.PlayerAdded:Connect(function(player)
--     initPlayer(player)
-- end)

function playerHasEsp(player)
    for i,v in pairs(espObjects) do
        if v.Player == player then
            return true
        end
    end
    return false
end

while task.wait() do
    if ESP_ENABLED then
        for i,v in pairs(game:GetService("Players")) do
            if playerHasEsp(v) == false then
                initPlayer(v)
            end
        end
    end
end
            

game.Players.PlayerRemoving:Connect(function(player)
    for i,v in pairs(espObjects) do
        if v.Player == player then
            v.Remove = true
        end
    end
end)

end

game:GetService("RunService").RenderStepped:Connect(function()
    for i, object in pairs(espObjects) do
        local showDrawings = true

        if isvalidplayer(object.Player) then
            if not(object.Player.Character.HumanoidRootPart:IsDescendantOf(game.Workspace)) or object.Player.Character.Humanoid.Health <= 0 then
                object.Remove = true
            end
        end

        if ESP_ENABLED and object.Remove == nil and isvalidplayer(object.Player) then
            local hrp = object.Player.Character.HumanoidRootPart
            local _, onScreen = camera:WorldToViewportPoint(hrp.Position)

            object.Update()

            if onScreen then
                showDrawings = true
            else
                showDrawings = false
            end
        else
            showDrawings = false
        end

        for _, drawing in pairs(object.Drawings) do
            if esp_config[object.Type].Enabled == false then
                showDrawings = false
            end

            if showDrawings == false then
                drawing.Visible = false
                drawing.Transparency = 0
            else
                drawing.Visible = true

                if esp_config[object.Type].Transparency == nil then
                    drawing.Transparency = 1
                else
                    drawing.Transparency = esp_config[object.Type].Transparency
                end
            end

            if object.Type == 'Text' then
                drawing.Outline = esp_config.Text.Outline
                drawing.Color = esp_config.Text.Color
                drawing.Size = esp_config.Text.Size
            end

            if object.Type == 'Box' then
                drawing.Color = esp_config.Box.Color
                drawing.Thickness = esp_config.Box.Thickness

                if esp_config.TeamColor then
                    drawing.Color = object.Player.TeamColor.Color
                end
            end

            if object.Type == 'Fill' then
                drawing.Color = esp_config.Fill.Color
                drawing.Transparency = esp_config.Fill.Transparency

                if esp_config.TeamColor then
                    drawing.Color = object.Player.TeamColor.Color
                end
            end
            
            
            if object.Type == 'Tracer' then
                drawing.Color = esp_config.Tracer.Color
                drawing.Thickness = esp_config.Tracer.Thickness

                if esp_config.TeamColor then
                    drawing.Color = object.Player.TeamColor.Color
                end
            end

            if esp_config.TeamCheck and game.Players.LocalPlayer.Team == object.Player.Team then
                drawing.Transparency = 0
            end
            
            if object.Remove then
                for _, drawing in pairs(object.Drawings) do
                    drawing:Remove()
                end
                table.remove(espObjects, i)
            end
        end
    end
end)


-- local repo = 'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/'

-- local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
-- local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
-- local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- local Window = Library:CreateWindow({
--     Title = 'Window',
--     Center = true, 
--     AutoShow = true,
-- })

local function initEsp(Window)

if Window == nil then
    local repo = 'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/'
    local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
    Window = Library:CreateWindow({
        Title = 'Window',
        Center = true, 
        AutoShow = true,
    })
end

local EspTab = Window:AddTab('Esp')

local MainEspTab = EspTab:AddLeftGroupbox('Enabled')
local TextTab = EspTab:AddLeftGroupbox('Text Settings')
local BoxTab = EspTab:AddRightGroupbox('Box Settings')
local FillTab = EspTab:AddRightGroupbox('Fill Settings')
local TracerTab = EspTab:AddRightGroupbox('Tracer Settings')

--- main tab
do

MainEspTab:AddToggle('EspEnabled', {
    Text = 'Esp Enabled',
    Default = false,
    Tooltip = 'Toggles the esp'
})
Toggles.EspEnabled:OnChanged(function()
    ESP_ENABLED = Toggles.EspEnabled.Value
end)

MainEspTab:AddToggle('BoxEnabled', {
    Text = 'Boxes',
    Default = false,
    Tooltip = 'Toggles boxes'
})
Toggles.BoxEnabled:OnChanged(function()
    esp_config.Box.Enabled = Toggles.BoxEnabled.Value

end)

MainEspTab:AddToggle('FillEnabled', {
    Text = 'Fill',
    Default = false,
    Tooltip = 'Toggles fill'
})
Toggles.FillEnabled:OnChanged(function()
    esp_config.Fill.Enabled = Toggles.FillEnabled.Value
end)


MainEspTab:AddToggle('CornersEnabled', {
    Text = 'Corners',
    Default = false,
    Tooltip = 'Toggles corners'
})
Toggles.CornersEnabled:OnChanged(function()
    esp_config.Corners.Enabled = Toggles.CornersEnabled.Value
end)


MainEspTab:AddToggle('NametagsEnabled', {
    Text = 'Nametags',
    Default = false,
    Tooltip = 'Toggles nametags'
})
Toggles.NametagsEnabled:OnChanged(function()
    esp_config.Text.Enabled = Toggles.NametagsEnabled.Value
end)


MainEspTab:AddToggle('TracersEnabled', {
    Text = 'Tracers',
    Default = false,
    Tooltip = 'Toggles tracers'
})
Toggles.TracersEnabled:OnChanged(function()
    esp_config.Tracer.Enabled = Toggles.TracersEnabled.Value
end)


MainEspTab:AddToggle('HealthbarEnabled', {
    Text = 'Healthbars',
    Default = false,
    Tooltip = 'Toggles healthbars'
})
Toggles.HealthbarEnabled:OnChanged(function()
    esp_config.Healthbar.Enabled = Toggles.HealthbarEnabled.Value
end)


MainEspTab:AddToggle('TeamCheck', {
    Text = 'Team Check',
    Default = false,
    Tooltip = 'Dont show players on your team'
})
Toggles.TeamCheck:OnChanged(function()
    esp_config.TeamCheck = Toggles.TeamCheck.Value
end)

MainEspTab:AddToggle('UseTeamColor', {
    Text = 'Use Team Color',
    Default = false,
    Tooltip = 'Assigns color based on team'
})
Toggles.UseTeamColor:OnChanged(function()
    esp_config.TeamColor = Toggles.UseTeamColor.Value
end)

end
---- nametags
do

TextTab:AddToggle('OutlineText', {
    Text = 'Outline Text',
    Default = true,
    Tooltip = 'Outline the text around nametags'
})
Toggles.OutlineText:OnChanged(function()
    esp_config.Text.Outline = Toggles.OutlineText.Value
end)


TextTab:AddLabel('Color'):AddColorPicker('TextColor', {
    Default = Color3.new(1, 1, 1)
})
Options.TextColor:OnChanged(function()
    esp_config.Text.Color = Options.TextColor.Value
end)


TextTab:AddSlider('TextSize', {
    Text = 'Text Size',
    Default = 16,
    Min = 0,
    Max = 30,
    Rounding = 1,
})
Options.TextSize:OnChanged(function()
    esp_config.Text.Size = Options.TextSize.Value
end)

end
------ boxes
do

BoxTab:AddLabel('Box Color'):AddColorPicker('BoxColor', {
    Default = Color3.new(1, 1, 1)
})
Options.BoxColor:OnChanged(function()
    esp_config.Box.Color = Options.BoxColor.Value
end)


BoxTab:AddSlider('BoxThickness', {
    Text = 'Box Thickness',
    Default = 2,
    Min = 0,
    Max = 5,
    Rounding = 0,
})
Options.BoxThickness:OnChanged(function()
    esp_config.Box.Thickness = Options.BoxThickness.Value
end)

end
-- fill
do

FillTab:AddLabel('Fill Color'):AddColorPicker('FillColor', {
    Default = Color3.new(1, 1, 1)
})
Options.FillColor:OnChanged(function()
    esp_config.Fill.Color = Options.FillColor.Value
end)


FillTab:AddSlider('FillTransparency', {
    Text = 'Fill Transparency',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
})
Options.FillTransparency:OnChanged(function()
    esp_config.Fill.Transparency = Options.FillTransparency.Value
end)

end
-- tracers
do

TracerTab:AddLabel('Tracer Color'):AddColorPicker('TracerColor', {
    Default = Color3.new(1, 1, 1)
})
Options.TracerColor:OnChanged(function()
    esp_config.Tracer.Color = Options.TracerColor.Value
end)


TracerTab:AddSlider('TracerThickness', {
    Text = 'Tracer Thickness',
    Default = 1,
    Min = 0,
    Max = 5,
    Rounding = 0,
})
Options.TracerThickness:OnChanged(function()
    esp_config.Tracer.Thickness = Options.TracerThickness.Value
end)

TracerTab:AddDropdown('TracerOrigin', {
    Values = {'Center', 'Mouse', 'Bottom'},
    Default = 1,
    Multi = false,
    Text = 'Tracer Origin',
    Tooltip = 'From where the tracer starts',
})

Options.TracerOrigin:OnChanged(function()
    esp_config.Tracer.Origin = Options.TracerOrigin.Value
end)

end

end

return initEsp

