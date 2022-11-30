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
    "v",
    "c",
    "La",
    "De",
    "Me",
    "Hi",
    "DS",
    "Ds",
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
end
return SuffixLib