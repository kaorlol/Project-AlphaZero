local LuaEncode = loadstring(game:HttpGet(("https://raw.githubusercontent.com/regginator/LuaEncode/master/src/LuaEncode.lua")))();

local function PrintTable(Table)
    return print(LuaEncode(Table, {
        PrettyPrinting = true;
        IndentCount = 4;
    }))
end

local function TableToString(Table)
    return LuaEncode(Table, {
        PrettyPrinting = true;
        IndentCount = 4;
    })
end

local function CopyTable(Table)
    return LuaEncode(Table, {
        PrettyPrinting = true;
        IndentCount = 4;
    })
end

return {
    PrintTable = PrintTable;
    TableToString = TableToString;
    CopyTable = CopyTable;
};