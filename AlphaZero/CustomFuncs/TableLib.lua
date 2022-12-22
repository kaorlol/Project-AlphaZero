local LuaEncode = loadstring(game:HttpGet(("https://raw.githubusercontent.com/regginator/LuaEncode/master/src/LuaEncode.lua")))();

local TableLib = {}; do
    function TableLib:TableToString(Table)
        return LuaEncode(Table, {
            PrettyPrinting = true;
            IndentCount = 4;
        })
    end;

    function TableLib:PrintTable(Table)
        return print(self:TableToString(Table))
    end;

    function TableLib:CopyTable(Table)
        return setclipboard(self:TableToString(Table))
    end;
end
return TableLib;