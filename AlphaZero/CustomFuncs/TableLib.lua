local TableUtil = {}; do
    function TableUtil:SortTable(Table, method)
        local SortedTable = {}
        local TableLength = #Table
        if method == 'number' then
            for Int = 1, TableLength do
                local LowestValue = math.huge
                local LowestValueIndex = 0
                
                for Index, Value in next, Table do
                    if tonumber(Value) < LowestValue then
                        LowestValue = tonumber(Value)
                        LowestValueIndex = Index
                    end
                end
                table.insert(SortedTable, Table[LowestValueIndex])
                table.remove(Table, LowestValueIndex)
            end
        elseif method == 'letter' then
            for Int = 1, TableLength do
                local LowestValue = 'z'
                local LowestValueIndex = 0
                
                for Index, Value in next, Table do
                    if Value <= LowestValue then
                        LowestValue = Value
                        LowestValueIndex = Index
                    end
                end
                table.insert(SortedTable, Table[LowestValueIndex])
                table.remove(Table, LowestValueIndex)
            end
        else
            error('Invalid method, please use "number" or "letter"')
        end
        return SortedTable
    end

    function TableUtil:RemoveDuplicates(Table)
        local NewTable = {}

        for _, Value in next, Table do
            if not table.find(NewTable, Value) then
                table.insert(NewTable, Value)
            end
        end

        return NewTable
    end
end
return TableUtil