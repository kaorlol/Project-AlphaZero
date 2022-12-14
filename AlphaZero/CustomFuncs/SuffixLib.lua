local Suffixes = {
    "K",
    "M",
    "B",
    "t",
    "q",
    "Q",
    "s",
    "S",
    "o",
    "n",
    "d",
    "U",
    "D",
    "T",
    "Qt",
    "Qd",
    "Sd",
    "St",
    "O",
    "N",
    "V",
    "c",
}
local SuffixLib = {}; do
    function SuffixLib:ConvertToSuffix(Number)
        local Number = tonumber(Number)
        if Number < 1000 then
            return Number
        end
        local Suffix = Suffixes[math.floor(math.log(Number) / math.log(1000))]
        return string.format("%.2f", Number / 1000 ^ math.floor(math.log(Number) / math.log(1000))) .. Suffix
    end

    function SuffixLib:ConvertToNumber(String)
        local String = tostring(String)
        local Suffix = string.match(String, "%a+")
        local Number = string.gsub(String, "%a+", "")
        if not Suffix then
            return tonumber(Number)
        end
        for i = 1, #Suffixes do
            if Suffixes[i]:lower() == Suffix:lower() then
                return tonumber(Number) * 1000 ^ i
            end
        end
    end

    function SuffixLib:ConvertFromSN(String)
        local String = tostring(String)
        local Number = string.match(String, "%d+")
        local Exponent = string.match(String, "%d+e%+?(%d+)")
        if not Exponent then
            return tonumber(Number)
        end
        return tonumber(Number) * 10 ^ tonumber(Exponent)
    end

    function SuffixLib:ConvertToSN(Number)
        local Number = tonumber(Number)
        if Number < 1000 then
            return Number
        end
        local Exponent = math.floor(math.log(Number) / math.log(10))
        return string.format("%.2f", Number / 10 ^ Exponent) .. "e" .. Exponent
    end
end
return SuffixLib