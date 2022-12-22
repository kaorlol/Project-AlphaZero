local LuaEncode = loadstring(game:HttpGet(("https://raw.githubusercontent.com/regginator/LuaEncode/master/src/LuaEncode.lua")))();

local TableLib = {}; do
    function TableLib:PrintTable(Table)
        return print(LuaEncode(Table, {
            PrettyPrinting = true;
            IndentCount = 4;
        }))
    end;

    function TableLib:TableToString(Table)
        return LuaEncode(Table, {
            PrettyPrinting = true;
            IndentCount = 4;
        })
    end;

    function TableLib:CopyTable(Table)
        return LuaEncode(Table, {
            PrettyPrinting = true;
            IndentCount = 4;
        })
    end;
end;
return TableLib;