--[[
    Info: Made by my friend 2unken#3050.

    Example Usage:

        Print All Controllers In Console:
            DumpControllers(print)
        Dump Contents Of Inputted Controller Name:
            DumpControllerContents("CodeController", print)
        Print All Services In Console:
            DumpServices(print)
        Dump Contents Of Inputted Service Name:
            DumpServiceContents("ClickService", print)

    Note: This only works in games that use Knit as their framework, so check using Dex Explorer or something.
]]

local Knit = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit")
local KnitClient = require(Knit:WaitForChild("KnitClient"))

local CreateController = KnitClient.CreateController
local GetService = KnitClient.GetService

local Controllers = getupvalue(CreateController, 1)
local Services = getupvalue(GetService, 1)

local KnitLib = {}; do
    function KnitLib:DumpServices(Callback)
        table.foreach(Services, Callback)
    end

    function KnitLib:DumpServiceContents(Service, Callback)
        table.foreach(Services[Service], Callback)
    end

    function KnitLib:DumpControllers(Callback)
        table.foreach(Controllers, Callback)
    end

    function KnitLib:DumpControllerContents(Controller, Callback)
        table.foreach(Controllers[Controller], Callback)
    end
end
return KnitLib