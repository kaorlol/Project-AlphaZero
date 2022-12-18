local FolderName = "AlphaZero/Taxi Boss";
if not isfolder("AlphaZero") then
    makefolder("AlphaZero")
elseif not isfolder("AlphaZero/Taxi Boss") then
    makefolder("AlphaZero/Taxi Boss")
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
local Binds = require(LocalPlayer.PlayerScripts.Keybinds);
local Bind = "0x"..string.format("%X", Binds.handbrake.Value);
local CarList = require(ReplicatedStorage.ModuleLists.CarList);

local MarketplaceService = game:GetService("MarketplaceService");
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name;

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController();
    VirtualUser:ClickButton2(Vector2.new(0,0));
end)

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))();
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

LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char
	Humanoid = Char:WaitForChild("Humanoid")
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
end)

local function GetVehicle()
    local PrimaryPart, VehicleModel, Rating = nil, nil, nil;
    for _, Vehicle in next, workspace.Vehicles:GetDescendants() do
        if Vehicle:FindFirstChild("Server") and Vehicle.Server.Player.Value == LocalPlayer then
            PrimaryPart, VehicleModel = Vehicle.REAL.SEAT, Vehicle;
            Rating = VehicleModel.FAKE.PLATE.SurfaceGui.Rating.Text;
            break;
        end
    end
    return PrimaryPart, VehicleModel, Rating;
end

local function GetClients()
    local _, _, Rating = GetVehicle();
    local Clients = {};
    for _, Client in next, workspace.NewCustomers:GetDescendants() do
        if Client:IsA("Folder") and Client.Name == "Client" and Client:FindFirstChild("PromptPart") then
            if Client.PromptPart:FindFirstChild("Rating") then
                local ClientRating = tonumber(Client.PromptPart.Rating.Frame.Rating.Text);
                if ClientRating <= tonumber(Rating) then
                    table.insert(Clients, Client);
                end
            end
        end
    end
    return Clients;
end

local function GetBestRating()
    local Clients = GetClients();
    local BestRating, BestClient = 0, nil;
    for _, Client in next, Clients do
        if Client.PromptPart:FindFirstChild("Rating") then
            local ClientRating = tonumber(Client.PromptPart.Rating.Frame.Rating.Text);
            if ClientRating > BestRating then
                BestRating, BestClient = ClientRating, Client;
            end
        end
    end
    return BestRating, BestClient;
end

local function GetOwnedCars()
    local CarIds = {};
    for _, Car in next, LocalPlayer.Data.OwnedCars:GetChildren() do
        if Car.Value == true then
            table.insert(CarIds, tonumber(Car.Name))
        end
    end
    return CarIds;
end

local function GetBestCar()
    local CarIds = GetOwnedCars();
    local Rating, CarId = nil, nil;
    local RatingsAndIds = {};
    for _, Car in next, CarList do
        if table.find(CarIds, Car.id) then
            table.insert(RatingsAndIds, string.format("%s:%s", Car.rating, Car.id))
        end
    end

    table.sort(RatingsAndIds, function(a, b)
        return a:split(":")[1] > b:split(":")[1]
    end)

    Rating, CarId = RatingsAndIds[1]:split(":")[1], RatingsAndIds[1]:split(":")[2];

    return Rating, CarId;
end

if LocalPlayer.variables.inCar.Value == false then
    local _, CarId = GetBestCar();
    LocalPlayer.PlayerScripts.CarSpawner.SpawnCar:Fire(tonumber(CarId));
    task.wait(1);
    ReplicatedStorage.Vehicles.EnterVehicleEvent:InvokeServer();
end

repeat task.wait() until LocalPlayer.variables.inCar.Value

local SavedToggles = {
    AutoFarm = nil;
};

local AutoFarm = Window:CreateTab("Auto Farm");
AutoFarm:CreateSection("Main");

local AutoFarmStatus = AutoFarm:CreateLabel("Status: Not Running!")

local AutoFarmToggle = false;
SavedToggles.AutoFarm = AutoFarm:CreateToggle({
    Name = "Auto Farm";
    CurrentValue = false;
    Callback = function(AutoFarmValue)
        AutoFarmToggle = AutoFarmValue;
        local Rating, Client = nil, nil;
        local Seat, Vehicle = nil, nil;
        local MarkerFound = false;
        local BreakCheck = false;

        task.spawn(function()
            if AutoFarmToggle then
                Rating, Client = GetBestRating();
                Seat, Vehicle = GetVehicle();
                MarkerFound = false;
                BreakCheck = false;

                if Client:FindFirstChild("nameValue") then
                    Utils.Network:Notify("Client Found...", string.format("Client: %s, Client Rating: %s", Client.nameValue.Value, tostring(Rating)), 10);
                    AutoFarmStatus:Set(string.format("Status: Running! | Client: %s, Client Rating: %s", Client.nameValue.Value, tostring(Rating)))
                end
            end

            while true do task.wait()
                if not AutoFarmToggle then
                    AutoFarmStatus:Set("Status: Not Running!")
                    VirtualUser:CaptureController();
                    VirtualUser:SetKeyUp(Bind);
                    break;
                end

                Rating, Client = GetBestRating();
                Seat, Vehicle = GetVehicle();

                if workspace.ParkingMarkers:FindFirstChild("ParkingMarker") then
                    MarkerFound = true;
                end

                if MarkerFound then
                    task.wait(7.5);

                    if not workspace.ParkingMarkers:FindFirstChild("ParkingMarker") then

                        task.wait(1.5);

                        BreakCheck = false;
                        MarkerFound = false;
                        Rating, Client = GetBestRating();
                        Seat, Vehicle = GetVehicle();

                        if not Client then
                            Utils.Network:Notify("No Clients found...", "Teleported to Middle of Map", 3);
                            Vehicle:PivotTo(workspace.Tracks.t5C9L.CFrame * CFrame.new(0, 1, 0));
                        elseif Client and Client:FindFirstChild("nameValue") then
                            Utils.Network:Notify("Client Found...", string.format("Client: %s, Client Rating: %s", Client.nameValue.Value, tostring(Rating)), 10);
                            AutoFarmStatus:Set(string.format("Status: Running! | Client: %s, Client Rating: %s", Client.nameValue.Value, tostring(Rating)))
                        end

                        firesignal(PlayerGui.ScreenGui.MissionEnd.Frame.Close.Activated);

                        task.wait(1.5);
                    else
                        local Marker = workspace.ParkingMarkers.ParkingMarker;
                        BreakCheck = true;
                        Vehicle:PivotTo(Marker.Part.CFrame * CFrame.new(0, 1, 0));

                        task.spawn(function()
                            while BreakCheck do task.wait(0.1)
                                VirtualUser:CaptureController();
                                if not BreakCheck then
                                    VirtualUser:SetKeyUp(Bind);
                                    break;
                                end
                                VirtualUser:SetKeyDown(Bind);
                            end
                        end)
                    end
                end

                Rating, Client = GetBestRating();
                Seat, Vehicle = GetVehicle();

                if MarkerFound == false and (Seat.Position - Client.PromptPart.Position).Magnitude <= 5 then
                    fireproximityprompt(Client.PromptPart.CustomerPrompt, 5);
                elseif MarkerFound == false and Client:FindFirstChild("PromptPart") then
                    Vehicle:PivotTo(Client.PromptPart.CFrame, Vector3.new(0, 0, 0));
                end
            end
        end)
    end;
})

local Credits = Window:CreateTab('Credits')
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


function FileToString(Table)
    local String = "";
    for Index, Value in next, Table do
        String ..= string.format('["%s"] = %s, ', Index, tostring(Value))
    end
    return String
end

task.spawn(function()
    while true do task.wait(5)
        local Indexes = {};
        for Index, Table in next, SavedToggles do
            Indexes[Index] = Table.CurrentValue
        end

        writefile(string.format("%s/Toggles.txt", FolderName), FileToString(Indexes))
    end
end)

Utils.Network:QueueOnTeleport([[
    repeat task.wait() until game:IsLoaded()

    loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/Loader.lua")))();

    LoadToggles = true;
]])

if LoadToggles then
    function FileToTable(String)
        local Table = {};
        for Index, Value in string.gmatch(String, "%[(.-)%] = (.-),") do
            local NewIndex = Index:gsub('"', "")
            Table[NewIndex] = Value
        end
        return Table
    end

    task.spawn(function()
        if isfile(string.format("%s/Toggles.txt", FolderName)) then
            local Contents = readfile(string.format("%s/Toggles.txt", FolderName))
            for Index, Value in next, FileToTable(Contents) do
                SavedToggles[Index]:Set(Value == "true" and true or false)
            end
        end
    end)

    LoadToggles = false;
end