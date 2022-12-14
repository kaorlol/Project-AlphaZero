local spy = {currentTableDepth = 0, maxTableDepth = 10}

function toUnicode(string)
    local codepoints = "utf8.char("
    
    for _i, v in utf8.codes(string) do
        codepoints = codepoints .. v .. ', '
    end
    
    return codepoints:sub(1, -3) .. ')'
end

function spy.get_path(instance)
    local name = instance.Name
    local head = (#name > 0 and '.' .. name) or "['']"
    if not instance.Parent and instance ~= game then
        return head .. " --[[ Parented to nil ]]"
    end
    if instance == game then
        return "game"
    elseif instance == workspace then
        return "workspace"
    else
        local _success, result = pcall(game.GetService, game, instance.ClassName)
        
        if _success and result then
            head = ':GetService("' .. instance.ClassName .. '")'
        elseif instance == lplr then
            head = '.LocalPlayer' 
        else    
            local nonAlphaNum = name:gsub('[%w_]', '')
            local noPunct = nonAlphaNum:gsub('[%s%p]', '')
            
            if tonumber(name:sub(1, 1)) or (#nonAlphaNum ~= 0 and #noPunct == 0) then
                head = '["' .. name:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"]'
            elseif #nonAlphaNum ~= 0 and #noPunct > 0 then
                head = '[' .. toUnicode(name) .. ']'
            end
        end
    end
    return spy.get_path(instance.Parent) .. head
end

function spy.table_to_string(t) 
    spy.currentTableDepth = spy.currentTableDepth + 1
    if spy.currentTableDepth > spy.maxTableDepth+1 then
        spy.currentTableDepth = spy.currentTableDepth - 1
        return "table_over_maxTableDepth (.."..tostring(t)..")"
    end
    local returnStr = "{"
    for i,v in next, t do
        returnStr = returnStr.."\n"..(("    "):rep(spy.currentTableDepth)).."["..spy.get_real_value(i).."] = "..spy.get_real_value(v)..","
    end
    if returnStr:sub(-2) == ", " then returnStr = returnStr:sub(1, -3) end
    spy.currentTableDepth = spy.currentTableDepth - 1
    return returnStr.."\n"..(("    "):rep(spy.currentTableDepth)).."}"
end

function spy.bettergetinfo(func) 
    local info = debug.getinfo(func)
    info.func = nil 
    return info
end

function spy.get_real_value(value, newFunctionMethod)
    local _t = typeof(value)
    if _t == 'Instance' then
        return spy.get_path(value)
    elseif _t == 'string' then
        return '"'..value..'"'
    elseif _t == 'table' then 
        return spy.table_to_string(value)
    elseif _t == 'function' then
        if not islclosure((value)) then 
            return "newcclosure(function() end)"
        end
        if newFunctionMethod then
            return "--[[function -->]] "..spy.table_to_string({upvalues = debug.getupvalues(value), constants = debug.getconstants(value), protos = debug.getprotos(value), info = spy.bettergetinfo(value)})
        end
        return "function() end"
    elseif _t == 'UDim2' or _t == 'UDim' or _t == 'Vector3' or _t == 'Vector2' or _t == 'CFrame' or _t == 'Vector2int16' or _t == 'Vector3int16' or _t == 'BrickColor' or _t == 'Color3' then
        local value = _t == 'BrickColor' and "'"..tostring(value).."'" or value
        return _t..".new("..tostring(value)..")"
    elseif _t == 'TweenInfo' then
        return "TweenInfo.new("..spy.get_real_value(value.Time)..", "..spy.get_real_value(value.EasingStyle)..", "..spy.get_real_value(value.EasingDirection)..", "..spy.get_real_value(value.RepeatCount)..", "..spy.get_real_value(value.Reverses)..", "..spy.get_real_value(value.DelayTime)..")"
    elseif _t == 'Enums' then
        return "Enum"
    elseif _t == 'Enum' then
        return "Enum."..tostring(value)
    elseif _t == 'Axes' or _t == 'Faces' then
        local returnStr = _t..".new("
        local normals = Enum.NormalId:GetEnumItems()
        for i,v in next, normals do
            if value[v.Name] then
                returnStr = returnStr..spy.get_real_value(v)..", "
            end
        end
        return returnStr:sub(1, -3)..")"
    elseif _t == 'ColorSequence' then
        local returnStr = "ColorSequence.new{"
        local keypoints = value.Keypoints
        for i,v in next, keypoints do 
            returnStr = returnStr..spy.get_real_value(v)..", "
        end
        return returnStr:sub(1, -3).."}"
    elseif _t == 'ColorSequenceKeypoint' then
        return "ColorSequenceKeypoint.new("..tostring(value.Time)..", "..spy.get_real_value(value.Value)..")"
    elseif _t == 'DockWidgetPluginGuiInfo' then
        local str = ""
        local split1 = tostring(value):split(":")
        for i,v in next, split1 do 
            str = str..v.." "
        end
        local split2 = str:split(" ") 
        local str = ""
        local reali = 0
        for i,v in next, split2 do
            if math.floor(i/2) == i/2 and v~=" " then
                reali = reali + 1
                local _v = v
                if reali == 1 then 
                    _v = "Enum.InitialDockState."..v
                end
                str = str.._v..", "
            end
        end
        return "DockWidgetPluginGuiInfo.new("..(str:sub(1, -3))..")"
    elseif _t == 'DateTime' then
		if value.UnixTimestampMillis == DateTime.now().UnixTimestampMillis then
            return "DateTime.now()"
        end
        return "DateTime.fromUnixTimestampMillis("..value.UnixTimestampMillis..")"
    elseif _t == 'FloatCurveKey' then
        return "FloatCurveKey.new("..spy.get_real_value(value.Time)..", "..spy.get_real_value(value.Value)..", "..spy.get_real_value(value.Interpolation)..")"
    elseif _t == 'NumberRange' then
        return "NumberRange.new("..spy.get_real_value(value.Min)..", "..spy.get_real_value(value.Max)..")"
    elseif _t == 'NumberSequence' then
        local returnStr = "NumberSequence.new{"
        local keypoints = value.Keypoints
        for i,v in next, keypoints do 
            returnStr = returnStr..spy.get_real_value(v)..", "
        end
        return returnStr:sub(1, -3).."}"
    elseif _t == 'NumberSequenceKeypoint' then
        return "NumberSequenceKeypoint.new("..tostring(value.Time)..", "..spy.get_real_value(value.Value)..(value.Envelope and ", "..value.Envelope or "")..")"
    elseif _t == 'PathWaypoint' then
        return "PathWaypoint.new("..spy.get_real_value(value.Position)..", "..spy.get_real_value(value.Action)..")"
    elseif _t == 'PhysicalProperties' then
        return "PhysicalProperties.new("..spy.get_real_value(value.Density)..", "..spy.get_real_value(value.Friction)..", "..spy.get_real_value(value.Elasticity)..", "..spy.get_real_value(value.FrictionWeight)..", "..spy.get_real_value(value.ElasticityWeight)..")"
    elseif _t == 'Random' then
        return "Random.new()"
    elseif _t == 'Ray' then
        return "Ray.new("..spy.get_real_value(value.Origin)..", "..spy.get_real_value(value.Direction)..")"
    elseif _t == 'RaycastParams' then
        return "--[[typeof: RaycastParams ->]] {FilterDescendantsInstances = "..spy.get_real_value(value.FilterDescendantsInstances)..", FilterType = "..spy.get_real_value(value.FilterType)..", IgnoreWater = "..spy.get_real_value(value.IgnoreWater)..", CollisionGroup = '"..spy.get_real_value(value.CollisionGroup).."'}"
    elseif _t == 'RaycastResult' then
        return "--[[typeof: RaycastResult ->]] {Distance = " ..spy.get_real_value(value.Distance)..", Instance = "..spy.get_real_value(value.Instance)..", Material = "..spy.get_real_value(value.Material)..", Position = "..spy.get_real_value(value.Position)..", Normal = "..spy.get_real_value(value.Normal).."}"
    elseif _t == 'RBXScriptConnection' then
        return "--[[typeof: RBXScriptConnection ->]] {Connected = "..spy.get_real_value(value.Connected).."}"
    elseif _t == 'RBXScriptSignal' then
        return "RBXScriptSignal"
    elseif _t == 'Rect' then
        return "Rect.new("..spy.get_real_value(value.Min)..", "..spy.get_real_value(value.Max)..")"
    elseif _t == 'Region3' then
        local cframe = value.CFrame
        local size = value.Size
        local min = spy.get_real_value((cframe * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)).p)
        local max = spy.get_real_value((cframe * CFrame.new(size.X/2, size.Y/2, size.Z/2)).p)
        return "Region3.new("..min..", "..max..")"
    elseif _t == 'Region3int16' then
        return "Region3int16.new("..spy.get_real_value(value.Min)..", "..spy.get_real_value(value.Max)..")"
    elseif _t == 'CatalogSearchParams' then
        return "--[[typeof: CatalogSearchParams ->]] {SearchKeyword = "..spy.get_real_value(value.SearchKeyword)..", MinPrice = "..spy.get_real_value(value.MinPrice)..", MaxPrice = "..spy.get_real_value(value.MaxPrice)..", SortType = "..spy.get_real_value(value.SortType)..", CategoryFilter = "..spy.get_real_value(value.CategoryFilter)..", AssetTypes = "..spy.get_real_value(value.AssetTypes).."}"
    elseif _t == 'OverlapParams' then
        return "--[[typeof: OverlapParams ->]] {FilterDescendantsInstances = "..spy.get_real_value(value.FilterDescendantsInstances)..", FilterType = "..spy.get_real_value(value.FilterType)..", MaxParts ="..spy.get_real_value(value.MaxParts)..", CollisionGroup = "..spy.get_real_value(value.CollisionGroup).."}"
    elseif _t == 'userdata' then
        return "newproxy(true)"
    elseif value == nil then
        return "nil"
    end
    return tostring(value)
end

local TableUtil = {}; do
    function TableUtil:RemoveDuplicates(Table)
        local NewTable = {}

        for _, Value in next, Table do
            if not table.find(NewTable, Value) then
                table.insert(NewTable, Value)
            end
        end

        return NewTable
    end

    function TableUtil:ShuffleTable(Table)
        local NewTable = {}
        local TableLength = #Table

        for Int = 1, TableLength do
            local RandomIndex = math.random(1, #Table)
            table.insert(NewTable, Table[RandomIndex])
            table.remove(Table, RandomIndex)
        end

        return NewTable
    end

    function TableUtil:PrintTable(...)
        local Args = {...}
        local DoThing = Args[#Args]
        if typeof(DoThing) == 'boolean' then
            Args[#Args] = nil
        end
        for _, Arg in next, Args do 
            print(spy.get_real_value(Arg, DoThing))
        end
    end

    function TableUtil:CopyTable(...)
        local Args = {...}
        local DoThing = Args[#Args]
        if typeof(DoThing) == 'boolean' then
            Args[#Args] = nil
        end
        for _, Arg in next, Args do 
            setclipboard(spy.get_real_value(Arg, DoThing))
        end
    end

    function TableUtil:TableToString(...)
        local Args = {...}
        local DoThing = Args[#Args]
        if typeof(DoThing) == 'boolean' then
            Args[#Args] = nil
        end
        local String = "{"
        for Index, Value in next, Args do
            if typeof(Index) == 'number' then
                string.format(String, "%s[%s] = %s,", String, spy.get_real_value(Index, DoThing), spy.get_real_value(Value, DoThing))
            else
                string.format(String, "%s%s = %s,", String, spy.get_real_value(Index, DoThing), spy.get_real_value(Value, DoThing))
            end
        end
        String = String.."}"
        return String
    end
end
return TableUtil