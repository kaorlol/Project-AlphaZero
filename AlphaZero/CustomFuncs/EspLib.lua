getgenv().ESP_ENABLED = false
getgenv().esp_config = {
    Text = {
        Outline = true,
        Color = Color3.new(1,1,1),
        Size = 16
    },
    Box = {
        Color = Color3.new(1,1,1),
        Thickness = 2
    },
    TeamCheck = false,
    TeamColor = false,
}

local espObjects = {}
local camera = workspace.CurrentCamera

function addBox(player)
    local char = player.Character
    local hrp = player.Character.HumanoidRootPart

    local box = Drawing.new("Square")
    box.Color = Color3.new(0, 0, 0)
    box.Thickness = 1

    local function update()
        local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local depth = vector.Z

        box.Size =  Vector2.new(3000 / depth, 4200 / depth)
        box.Position = Vector2.new(vector.X - (box.Size.X / 2), vector.Y - (box.Size.Y / 2.4))
    end

    table.insert(espObjects, {
        Update = update,
        Drawings = {box},
        Player = player,
        Type = 'Box'
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
        Type = "Nametag"
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
        local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)

        local depth = vector.Z
        local size = Vector2.new(3000 / depth, 4200 / depth)
        local center = Vector2.new(vector.X, vector.Y)
        
        local side = Vector2.new(center.X - (size.X / 1.8), center.Y)

        local top = Vector2.new(side.X, side.Y - (size.Y / 2.4))
        local bottom = Vector2.new(side.X, side.Y + (size.Y / 1.7))

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

function isvalidplayer(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head")
end

function initPlayer(player)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") then
        addBox(player)
        addNametag(player)
        addHealthbar(player)
    end

    player.CharacterAdded:Connect(function()
        repeat task.wait() until isvalidplayer(player)

        addBox(player)
        addNametag(player)
        addHealthbar(player)
    end)
end

for i,v in pairs(game.Players:GetChildren()) do
    initPlayer(v)
end

game.Players.PlayerAdded:Connect(function(player)
    initPlayer(player)
end)

game.Players.PlayerRemoving:Connect(function(player)
    for i,v in pairs(espObjects) do
        if v.Player == player then
            v.Remove = true
        end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    for i, object in pairs(espObjects) do
        local showDrawings = true

        if isvalidplayer(object.Player) then
            if not(object.Player.Character.HumanoidRootPart:IsDescendantOf(game.Workspace)) or object.Player.Character.Humanoid.Health <= 0 then
                object.Remove = true
            end
        end

        if object.Remove then
            for _, drawing in pairs(object.Drawings) do
                drawing:Remove()
            end
            table.remove(espObjects, i)
        end

        if ESP_ENABLED and object.Remove == nil and isvalidplayer(object.Player) then
            local hrp = object.Player.Character.HumanoidRootPart
            local _, onScreen = camera:WorldToViewportPoint(hrp.Position)

            object.Update()

            if onScreen then
                for _, drawing in pairs(object.Drawings) do
                    drawing.Visible = true
                    drawing.Transparency = 1
                end
            else
                for _, drawing in pairs(object.Drawings) do
                    drawing.Transparency = 0
                    
                end
            end
        else
            for _, drawing in pairs(object.Drawings) do
                drawing.Transparency = 0
            end
        end

        for _, drawing in pairs(object.Drawings) do
            if object.Type == 'Nametag' then
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

            if esp_config.TeamCheck and game.Players.LocalPlayer.Team == object.Player.Team then
                drawing.Transparency = 0
            end
        end
    end
end)


local esp_funcs = {}

function esp_funcs:CreateTab(window)
    local EspTab = window:AddTab('Esp')

    local MainEspTab = EspTab:AddLeftGroupbox('Enabled')
    local TextTab = EspTab:AddLeftGroupbox('Text Settings')
    local BoxTab = EspTab:AddRightGroupbox('Box Settings')

    MainEspTab:AddToggle('EspEnabled', {
        Text = 'Esp Enabled',
        Default = false,
        Tooltip = 'Toggles the esp'
    })
    Toggles.EspEnabled:OnChanged(function()
        ESP_ENABLED = Toggles.EspEnabled.Value
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



    BoxTab:AddLabel('Color'):AddColorPicker('BoxColor', {
        Default = Color3.new(1, 1, 1)
    })
    Options.BoxColor:OnChanged(function()
        esp_config.Box.Color = Options.BoxColor.Value
    end)


    BoxTab:AddSlider('BoxThickness', {
        Text = 'Text Size',
        Default = 2,
        Min = 0,
        Max = 5,
        Rounding = 1,
    })
    Options.BoxThickness:OnChanged(function()
        esp_config.Box.Thickness = Options.BoxThickness.Value
    end)
end

return esp_funcs
