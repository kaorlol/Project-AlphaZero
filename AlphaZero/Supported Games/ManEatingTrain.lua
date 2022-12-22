loadstring(game:HttpGet("https://raw.githubusercontent.com/Sw1ndlerScripts/RobloxScripts/main/Esp%20Library/esp%20v2.lua",true))()

plr = game.Players.LocalPlayer

getgenv().config = {
    esp = {
        items = {
            ammunition = false,
            medical = false,
            ticket = false
        },
        train = false
    },
    combat = {
        silentAim = true  
    },
    infStam = false,
    instantInteract = false
}

function getCrates()
    props = {}
    for i,v in pairs(game:GetService("Workspace").Railcars:GetChildren()) do
        for _, prop in pairs(v:GetDescendants()) do
            if prop:FindFirstChild("Root") and (string.match(prop.Name:lower(), 'crate') or string.match(prop.Name:lower(), 'box')) then
                table.insert(props, prop)
            end
        end
    end
    return props
end

function updateTrainEsp()
    local train = game:GetService("Workspace").Multipods.Multipod.Body.WeldedParts["Locomotive_NoWheels_Texture_01"]
    if config.esp.train then
        addBoxEsp(train)
    else
        removeItem(train)
    end
end

local function rayToPos(x,y)
    return Ray.new(x,(y-x).Unit*9e9)
end

function updateItemEsp()
    for i,v in pairs(getCrates()) do
        local proxPrompt = v.Root.ProximityPrompt
        local name = proxPrompt.ObjectText
        
        if name ~= "" then
            
            if name == 'Ammunition Box' then
                if config.esp.items.ammunition then
                    addText(v.Root, name)
                    addBoxEsp(v.Root)
                else
                    removeItem(v.Root)
                end
            end
            
            if name == 'Medical Box' then
                if config.esp.items.medical then
                    addText(v.Root, name)
                    addBoxEsp(v.Root)
                else
                    removeItem(v.Root)
                end
            end
            
            if name == 'Ticket Box' then
                if config.esp.items.ticket then
                    addText(v.Root, name)
                    addBoxEsp(v.Root)
                else
                    removeItem(v.Root)
                end
            end
        end
    end
end


-- hooks ---------------------

stam = plr.Character["IntValue_Stamina"]

local old
old = hookmetamethod(game, '__index', function(self, key)
    if self == stam and key == 'Value' and config.infStam then
        return 100
    end
    return old(self, key)
end)

-- local fire
-- fire = hookmetamethod(game, '__namecall', function(self, ...)
--     args = {...}
--     if tostring(self):lower() == 'workspace' and getnamecallmethod() == 'FindPartOnRayWithIgnoreList' and tostring(getcallingscript()) ~= "ControlModule" and config.combat.silentAim then
--         if game.Workspace:FindFirstChild("Multipods") and game.Workspace.Multipods:FindFirstChild("Multipods") then
--             local trainPart = game:GetService("Workspace").Multipods.Multipod.Head.VisualHead

--             args[1] = rayToPos(plr.Character.Head.Position, trainPart.Position)
--             return fire(self, unpack(args))

--         end
--     end
--     return fire(self, ...)
-- end)


game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt)
    if config.instantInteract then
        fireproximityprompt(prompt)
    end
end)


local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local Window = Rayfield:CreateWindow({
    Name = "Edward the Man-Eating Train",
    LoadingTitle = "Project Alpha Zero: Edward the Man-Eating Train",
    LoadingSubtitle = "By: Kaoru~#6438 and Sw1ndler#7733",
    Discord = {
        Enabled = false,
        Invite = "JdzPVMNFwY",
        RememberJoins = true,
     },
})

--local Combat = Window:CreateTab("Combat")
local Esp = Window:CreateTab("Esp")
local Misc = Window:CreateTab("Misc")


-- Combat

-- Combat:CreateToggle({
-- 	Name = "Train Silent Aim",
-- 	CurrentValue = false,
-- 	Callback = function(Value)
-- 	    config.combat.silentAim = Value
-- 	end
-- })

-- Misc Functions

Misc:CreateToggle({
	Name = "Infinite Stamina",
	CurrentValue = false,
	Callback = function(Value)
	    config.infStam = Value
	end
})

Misc:CreateToggle({
	Name = "Instant Interact",
	CurrentValue = false,
	Callback = function(Value)
	    config.instantInteract = Value
	end
})


--------- Misc Esp
Esp:CreateSection("Npc's")

Esp:CreateToggle({
	Name = "Man Eating Train",
	CurrentValue = false,
	Callback = function(Value)
	    config.esp.train = Value
        updateTrainEsp()
	end
})


Esp:CreateSection("Misc")

Esp:CreateToggle({
	Name = "Ammunition Box",
	CurrentValue = false,
	Callback = function(Value)
	    config.esp.items.ammunition = Value
        updateItemEsp()
	end
})

Esp:CreateToggle({
	Name = "Medical Box",
	CurrentValue = false,
	Callback = function(Value)
	    config.esp.items.medical = Value
        updateItemEsp()
	end
})

Esp:CreateToggle({
	Name = "Ticket Box",
	CurrentValue = false,
	Callback = function(Value)
	    config.esp.items.ticket = Value
        updateItemEsp()
	end
})



