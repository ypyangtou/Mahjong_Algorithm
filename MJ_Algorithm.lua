--[[
        Author: yaopeng
        Date:   2017/11/20
        Notice: This is lua code for MJ algorithm
--]]

local MJ_Algorithm = {}

----------------------------------------通用函数----------------------------------------
local MJ_CardArray = {
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,					-- 万子
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,					-- 索子
	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,					-- 同子
	0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,                               -- 东~白
	0x41, 0x42, 0x43, 0x44,	0x45, 0x46, 0x47, 0x48						    -- 春~菊
}

--删除单个
local function Delarray(list, dellist)
    --PrintTable(dellist)
	for i = 1, #dellist do
		for j = #list, 1, -1 do
			if dellist[i] == list[j] then
				table.remove(list, j)
				break
			end
		end
	end
    return list
end

-- --删除所有
-- local function Delarrays(list, dellist)
--     --PrintTable(dellist)
-- 	for i = 1, #dellist do
-- 		for j = #list, 1, -1 do
-- 			if dellist[i] == list[j] then
-- 				table.remove(list, j)
-- 			end
-- 		end
-- 	end
--     return list
-- end

--删除一次
local function Delarray_Once(list, dellist)
    --PrintTable(dellist)
	for i = 1, #dellist do
		for j = #list, 1, -1 do
			if dellist[i] == list[j] then
				table.remove(list, j)
				return list
			end
		end
	end
    return list
end

local function isIncluded(card, cardList)
    for i = 1, #cardList do
        if card == cardList[i] then
            return true
        end
    end
    return false
end

--深拷贝
local function DeepCopy(tbl)
    local InTable = {};  
    local function Func(obj)  
        if type(obj) ~= "table" then   --判断表中是否有表  
            return obj;  
        end  
        local NewTable = {};  --定义一个新表  
        InTable[obj] = NewTable;  --若表中有表，则先把表给InTable，再用NewTable去接收内嵌的表  
        for k, v in pairs(obj) do  --把旧表的key和Value赋给新表  
            NewTable[Func(k)] = Func(v);  
        end  
        return setmetatable(NewTable, getmetatable(obj))--赋值元表  
    end  
    return Func(tbl) --若表中有表，则把内嵌的表也复制了 
end

local function PrintTable(tbl, level, filteDefault)
    -- local msg = ""
    filteDefault = filteDefault or true --默认过滤关键字（DeleteMe, _class_type）
    level = level or 1
    local indent_str = ""
    for _ = 1, level do
        indent_str = indent_str.."  "
    end

    print(indent_str .. "{")
    for k, v in pairs(tbl) do
        if filteDefault then
            if k ~= "_class_type" and k ~= "DeleteMe" then
                local item_str = string.format("%s%s = %s", indent_str .. " ", tostring(k), tostring(v))
                print(item_str)
                if type(v) == "table" then
                    PrintTable(v, level + 1)
                end
            end
        else
            local item_str = string.format("%s%s = %s", indent_str .. " ", tostring(k), tostring(v))
            print(item_str)
            if type(v) == "table" then
                PrintTable(v, level + 1)
            end
        end
    end
    print(indent_str .. "}")
end

local function PrintTableBy64(list)
    if type(list) ~= "table" then
        print("error local function PrintTableBy64(list)")
        return
    else
        print("{")
        local strTotal = " "
        for i = 1, #list do
            if type(list[i]) == "table" then
                PrintTableBy64(list[i])
            else
                local str = string.format("0x%02x", list[i])
                strTotal = strTotal .. str .. ", "
            end
        end
        print(strTotal)
        print("{")
    end
end

-- local function print_debug(...)
--     -- print(...)
-- end

-- local function PrintTable_Debug(...)
--     -- PrintTable(...)
-- end

-- local function PrintTableBy64_Debug(...)
--     -- PrintTableBy64(...)
-- end

----------------------------------------通用函数----------------------------------------

----------------------------------------胡牌函数----------------------------------------
local function getcolor(value)
    return math.floor(value/0x10)
end

local function getvalue(value)
    return value%0x10
end

local function SwitchToCardIndex(card)
    return (getcolor(card) * 9 + getvalue(card))
end

local function SwitchToCardData(cardIndex)
    return (math.floor((cardIndex - 1) / 9) * 16 + (cardIndex - 1) % 9 + 1)
end

function MJ_Algorithm:GetWeaveCard(eat, peng)
    local cardData = {}
    for i = 1, #eat do
        table.insert(cardData, eat[i])
    end
    for i = 1, #peng do
        table.insert(cardData, peng[i])
    end
    return cardData
end

function MJ_Algorithm:AnalyseCard(cardList, relyCard, weaveItem)
    -- print_debug("function AnalyseCard(cardList, relyCard, weaveItem)")
    local cardCount = #cardList
    local maxCount = 17     -- 14 or 17
    local maxIndex = 34
    local maxWeave = 5      -- 4 or 5
    if cardCount < 2 or cardCount > maxCount or ((cardCount - 2) % 3) ~= 0 then
        return {}
    end
    local cardIndex = {}
    for i = 1, maxIndex do
        cardIndex[i] = 0
    end
    for i = 1, cardCount do
        local index = SwitchToCardIndex(cardList[i])
        cardIndex[index] = cardIndex[index] + 1
    end
    local magicIndex = SwitchToCardIndex(relyCard)
    -- local kindItemCount = 0
    local kindItem = {}
    local lessKindItem = math.floor((cardCount - 2) / 3)

    local analyseItemArray = {}

    -- print_debug("magicIndex =", magicIndex)
    -- if weaveItem then
        -- print_debug("weaveItem")
        -- PrintTable_Debug(weaveItem)
    -- end

    if lessKindItem == 0 then
        for i = 1, maxIndex do
            if cardIndex[i] == 2 or (magicIndex ~= 0 and i ~= magicIndex and (cardIndex[magicIndex] + cardIndex[i]) == 2) then
                local analyseItem = {eat = {}, peng = {}, jiang = {}}
                if weaveItem and weaveItem.eat and #weaveItem.eat > 0 then
                    analyseItem.eat = DeepCopy(weaveItem.eat)
                end
                if weaveItem and weaveItem.peng and #weaveItem.peng > 0 then
                    analyseItem.peng = DeepCopy(weaveItem.peng)
                end
                if cardIndex[i] < 2 or i == magicIndex then
                    analyseItem.jiang = {SwitchToCardData(i), relyCard}
                else
                    analyseItem.jiang = {SwitchToCardData(i), SwitchToCardData(i)}
                end
                table.insert(analyseItemArray, analyseItem)
                return analyseItemArray
            end
        end
        return analyseItemArray
    end
    local cardIndexTemp = DeepCopy(cardIndex)
    local magicCardCount = 0
    if magicIndex ~= 0 then
        magicCardCount = cardIndex[magicIndex]
        if cardIndexTemp[magicIndex] then
            cardIndexTemp[magicIndex] = 1
        end
    end

    if cardCount >= 3 then
        for i = 1, maxIndex do
            ---- 原版
            -- if cardIndexTemp[i] + magicCardCount >= 3 then
            --     local data = SwitchToCardData(i)
            --     local dataTemp = {data, data, data}
            --     local indexTemp = {}
            --     if cardIndexTemp[i] > 0 then
            --         indexTemp[1] = i
            --     else
            --         indexTemp[1] = magicIndex
            --     end
            --     if cardIndexTemp[i] > 1 then
            --         indexTemp[2] = i
            --     else
            --         indexTemp[2] = magicIndex
            --     end
            --     if cardIndexTemp[i] > 2 then
            --         indexTemp[3] = i
            --     else
            --         indexTemp[3] = magicIndex
            --     end
            --     table.insert(kindItem, {weaveKind = "peng", cardData = dataTemp, validIndex = indexTemp})
            --     if cardIndexTemp[i] + magicCardCount >= 6 then
            --         if cardIndexTemp[i] > 3 then
            --             indexTemp[1] = i
            --         else
            --             indexTemp[1] = magicIndex
            --         end
            --         indexTemp[2] = magicIndex
            --         indexTemp[3] = magicIndex
            --         table.insert(kindItem, {weaveKind = "peng", cardData = data, validIndex = indexTemp})
            --     end
            -- end
            ---- 优化版
            if (cardIndexTemp[i] + magicCardCount) >= 3 and cardIndexTemp[i] >= 1 then
                local data = SwitchToCardData(i)
                local dataTemp = {}
                local indexTemp = {}
                if cardIndexTemp[i] > 0 then
                    indexTemp[1] = i
                    dataTemp[1] = data
                else
                    indexTemp[1] = magicIndex
                    dataTemp[1] = relyCard
                end
                if cardIndexTemp[i] > 1 then
                    indexTemp[2] = i
                    dataTemp[2] = data
                else
                    indexTemp[2] = magicIndex
                    dataTemp[2] = relyCard
                end
                if cardIndexTemp[i] > 2 then
                    indexTemp[3] = i
                    dataTemp[3] = data
                else
                    indexTemp[3] = magicIndex
                    dataTemp[3] = relyCard
                end
                table.insert(kindItem, {weaveKind = "peng", cardData = dataTemp, validIndex = indexTemp})
                -- table.insert(kindItem, {weaveKind = "peng", validIndex = indexTemp})
            end
            if ((i - 1) < maxIndex - 8) and (((i - 1) % 9) < 7) then
                if (magicCardCount + cardIndexTemp[i] + cardIndexTemp[i + 1] + cardIndexTemp[i + 2]) >= 3 then
                    local index = {}
                    if i == magicIndex then
                        index[1] = 0
                    else
                        index[1] = cardIndexTemp[i]
                    end
                    if (i + 1) == magicIndex then
                        index[2] = 0
                    else
                        index[2] = cardIndexTemp[i + 1]
                    end
                    if (i + 2) == magicIndex then
                        index[3] = 0
                    else
                        index[3] = cardIndexTemp[i + 2]
                    end
                    local magicCardCountTemp = magicCardCount
                    ---- 原版
                    -- while(magicCardCountTemp + index[1] + index[2] + index[3] >= 3)
                    -- do
                    --     local validIndex = {0, 0, 0}
                    --     for j = 1, 3 do
                    --         if index[j] > 0 then
                    --             index[j] = index[j] - 1
                    --             validIndex[j] = i + j - 1
                    --         else
                    --             magicCardCountTemp = magicCardCountTemp - 1
                    --             validIndex[j] = magicIndex
                    --         end
                    --     end

                    --     if magicCardCountTemp >= 0 then
                    --         local data = SwitchToCardData(i)
                    --         local dataTemp = {data, data + 1, data + 2}
                    --         table.insert(kindItem, {weaveKind = "eat", cardData = dataTemp, validIndex = validIndex})
                    --     else
                    --         break
                    --     end
                    -- end
                    ---- 优化版
                    if (index[1] + index[2] + index[3]) >= 1 and ((index[1] > 0 and index[2] > 0) or (index[1] > 0 and index[3] > 0)or (index[2] > 0 and index[3] > 0)) then
                        if index[1] >= 1 and index[2] >= 2 and index[3] >= 1 and magicCardCountTemp >= 1 then
                            for q = 1, 3 do
                                local data = SwitchToCardData(i)
                                local dataTemp = {}
                                local validIndex = {}
                                for n = 1, 3 do
                                    validIndex[n] = i + n - 1
                                    dataTemp[n] = data + n - 1
                                end
                                validIndex[q] = magicIndex
                                dataTemp[q] = relyCard
                                
                                table.insert(kindItem, {weaveKind = "eat", cardData = dataTemp, validIndex = validIndex})
                                -- table.insert(kindItem, {weaveKind = "eat", validIndex = validIndex})
                            end
                            magicCardCountTemp = 0
                        end
                        if index[1] >= 2 and index[2] == 1 and index[3] == 1 and magicCardCountTemp >= 1 then
                            local validIndex = {}
                            local data = SwitchToCardData(i)
                            local dataTemp = {}
                            for n = 1, 3 do
                                validIndex[n] = i + n - 1
                                dataTemp[n] = data + n - 1
                            end
                            validIndex[1] = magicIndex
                            dataTemp[1] = relyCard
                            table.insert(kindItem, {weaveKind = "eat", cardData = dataTemp, validIndex = validIndex})
                            -- table.insert(kindItem, {weaveKind = "eat", validIndex = validIndex})
                            magicCardCountTemp = 0
                        end
                        while((magicCardCountTemp + index[1] + index[2] + index[3]) >= 3 and (index[1] + index[2] + index[3]) >= 1)
                        do
                            local validIndex = {}
                            local data = SwitchToCardData(i)
                            local dataTemp = {}
                            for j = 1, 3 do
                                if index[j] > 0 then
                                    index[j] = index[j] - 1
                                    validIndex[j] = i + j - 1
                                    dataTemp[j] = data + j - 1
                                else
                                    magicCardCountTemp = magicCardCountTemp - 1
                                    validIndex[j] = magicIndex
                                    dataTemp[j] = relyCard
                                end
                            end
                            if magicCardCountTemp >= 0 then
                                table.insert(kindItem, {weaveKind = "eat", cardData = dataTemp, validIndex = validIndex})
                                -- table.insert(kindItem, {weaveKind = "eat", validIndex = validIndex})
                            else
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    -- print_debug("kindItem size =", #kindItem)
    -- PrintTable_Debug(kindItem)
    -- -- PrintTable_Debug(sb)

    if #kindItem >= lessKindItem then
        local cardIndexTempTemp
        local index = {}
        for i = 1, maxWeave do
            index[i] = i
        end
        local kindItemTemp = {}
        repeat
            cardIndexTempTemp = DeepCopy(cardIndex)
            for i = 1, lessKindItem do
                kindItemTemp[i] = kindItem[index[i]]
            end
            local isEnoughCard = true
            for i = 1, lessKindItem * 3 do
                local calcIndex = kindItemTemp[math.floor((i - 1) / 3) + 1].validIndex[(i - 1) % 3 + 1]
                if cardIndexTempTemp[calcIndex] == 0 then
                    isEnoughCard = false
                    break
                else
                    cardIndexTempTemp[calcIndex] = cardIndexTempTemp[calcIndex] - 1
                end
            end
            if isEnoughCard then
                local cardEye = 0
                local isMagicEye = false
                for i = 1, maxIndex do
                    if cardIndexTempTemp[i] == 2 then
                        cardEye = SwitchToCardData(i)
                        if i == magicIndex then
                            isMagicEye = true
                        end
                    elseif i ~= magicIndex and magicIndex ~= 0 and (cardIndexTempTemp[i] + cardIndexTempTemp[magicIndex]) == 2 then
                        cardEye = SwitchToCardData(i)
                        isMagicEye = true
                    end
                end
                if cardEye ~= 0 then
                    local analyseItem = {eat = {}, peng = {}, jiang = {}}
                    if weaveItem and weaveItem.eat and #weaveItem.eat > 0 then
                        analyseItem.eat = DeepCopy(weaveItem.eat)
                    end
                    if weaveItem and weaveItem.peng and #weaveItem.peng > 0 then
                        analyseItem.peng = DeepCopy(weaveItem.peng)
                    end
                    for i = 1, lessKindItem do
                        if kindItemTemp[i].weaveKind == "eat" then
                            table.insert(analyseItem.eat, kindItemTemp[i].cardData)
                        else
                            table.insert(analyseItem.peng, kindItemTemp[i].cardData)
                        end
                    end
                    if isMagicEye then
                        analyseItem.jiang = {cardEye, relyCard}
                    else
                        analyseItem.jiang = {cardEye, cardEye}
                    end
                    table.insert(analyseItemArray, analyseItem)
                end
            end
            if index[lessKindItem] == #kindItem then
                local i = lessKindItem
                while(i > 1)
                do
                    if (index[i - 1] + 1) ~= index[i] then
                        local newIndex = index[i - 1]
                        for j = i - 1, lessKindItem + 1 do
                            index[j] = newIndex + j - i + 2
                        end
                        break
                    end
                    i = i - 1
                end
                if i == 1 then
                    break
                end
            else
                index[lessKindItem] = index[lessKindItem] + 1
            end

        until(false)
    end
    return analyseItemArray
end

-- function MJ_Algorithm:AnalyseCardWithoutItem(cardList, relyCard)
--     -- print_debug("function AnalyseCardWithoutItem(cardList, relyCard)")
--     local cardCount = #cardList
--     local maxCount = cardCount
--     local maxIndex = 34
--     local maxWeave = (cardCount - 2) / 3
--     if cardCount < 2 or cardCount > maxCount or ((cardCount - 2) % 3) ~= 0 then
--         return {}
--     end
--     local cardIndex = {}
--     for i = 1, maxIndex do
--         cardIndex[i] = 0
--     end
--     for i = 1, cardCount do
--         local index = SwitchToCardIndex(cardList[i])
--         cardIndex[index] = cardIndex[index] + 1
--     end
--     local magicIndex = SwitchToCardIndex(relyCard)
--     -- local kindItemCount = 0
--     local kindItem = {}
--     local lessKindItem = math.floor((cardCount - 2) / 3)

--     if lessKindItem == 0 then
--         for i = 1, maxIndex do
--             if cardIndex[i] == 2 or (magicIndex ~= 0 and i ~= magicIndex and (cardIndex[magicIndex] + cardIndex[i]) == 2) then
--                 return true
--             end
--         end
--         return false
--     end
--     local cardIndexTemp = DeepCopy(cardIndex)
--     local magicCardCount = 0
--     if magicIndex ~= 0 then
--         magicCardCount = cardIndex[magicIndex]
--         if cardIndexTemp[magicIndex] then
--             cardIndexTemp[magicIndex] = 1
--         end
--     end

--     if cardCount >= 3 then
--         for i = 1, maxIndex do
--             ---- 优化版
--             if (cardIndexTemp[i] + magicCardCount) >= 3 and cardIndexTemp[i] >= 1 then
--                 -- local data = SwitchToCardData(i)
--                 local indexTemp = {}
--                 if cardIndexTemp[i] > 0 then
--                     indexTemp[1] = i
--                 else
--                     indexTemp[1] = magicIndex
--                 end
--                 if cardIndexTemp[i] > 1 then
--                     indexTemp[2] = i
--                 else
--                     indexTemp[2] = magicIndex
--                 end
--                 if cardIndexTemp[i] > 2 then
--                     indexTemp[3] = i
--                 else
--                     indexTemp[3] = magicIndex
--                 end
--                 table.insert(kindItem, {weaveKind = "peng", validIndex = indexTemp})
--             end
--             if ((i - 1) < maxIndex - 8) and (((i - 1) % 9) < 7) then
--                 if (magicCardCount + cardIndexTemp[i] + cardIndexTemp[i + 1] + cardIndexTemp[i + 2]) >= 3 then
--                     local index = {}
--                     if i == magicIndex then
--                         index[1] = 0
--                     else
--                         index[1] = cardIndexTemp[i]
--                     end
--                     if (i + 1) == magicIndex then
--                         index[2] = 0
--                     else
--                         index[2] = cardIndexTemp[i + 1]
--                     end
--                     if (i + 2) == magicIndex then
--                         index[3] = 0
--                     else
--                         index[3] = cardIndexTemp[i + 2]
--                     end
--                     local magicCardCountTemp = magicCardCount
--                     ---- 优化版
--                     if (index[1] + index[2] + index[3]) >= 1 and ((index[1] > 0 and index[2] > 0) or (index[1] > 0 and index[3] > 0)or (index[2] > 0 and index[3] > 0)) then
--                         if index[1] >= 1 and index[2] >= 2 and index[3] >= 1 and magicCardCountTemp >= 1 then
--                             for q = 1, 3 do
--                                 local validIndex = {}
--                                 for n = 1, 3 do
--                                     validIndex[n] = i + n - 1
--                                 end
--                                 validIndex[q] = magicIndex
--                                 table.insert(kindItem, {weaveKind = "eat", validIndex = validIndex})
--                             end
--                             magicCardCountTemp = 0
--                         end
--                         if index[1] >= 2 and index[2] == 1 and index[3] == 1 and magicCardCountTemp >= 1 then
--                             local validIndex = {}
--                             for n = 1, 3 do
--                                 validIndex[n] = i + n - 1
--                             end
--                             validIndex[1] = magicIndex
--                             table.insert(kindItem, {weaveKind = "eat", validIndex = validIndex})
--                             magicCardCountTemp = 0
--                         end
--                         while((magicCardCountTemp + index[1] + index[2] + index[3]) >= 3 and (index[1] + index[2] + index[3]) >= 1)
--                         do
--                             local validIndex = {}
--                             for j = 1, 3 do
--                                 if index[j] > 0 then
--                                     index[j] = index[j] - 1
--                                     validIndex[j] = i + j - 1
--                                 else
--                                     magicCardCountTemp = magicCardCountTemp - 1
--                                     validIndex[j] = magicIndex
--                                 end
--                             end
--                             if magicCardCountTemp >= 0 then
--                                 table.insert(kindItem, {weaveKind = "eat", validIndex = validIndex})
--                             else
--                                 break
--                             end
--                         end
--                     end
--                 end
--             end
--         end
--     end

--     if #kindItem >= lessKindItem then
--         local cardIndexTempTemp
--         local index = {}
--         for i = 1, maxWeave do
--             index[i] = i
--         end
--         local kindItemTemp = {}
--         repeat
--             cardIndexTempTemp = DeepCopy(cardIndex)
--             for i = 1, lessKindItem do
--                 kindItemTemp[i] = kindItem[index[i]]
--             end
--             local isEnoughCard = true
--             for i = 1, lessKindItem * 3 do
--                 local calcIndex = kindItemTemp[math.floor((i - 1) / 3) + 1].validIndex[(i - 1) % 3 + 1]
--                 if cardIndexTempTemp[calcIndex] == 0 then
--                     isEnoughCard = false
--                     break
--                 else
--                     cardIndexTempTemp[calcIndex] = cardIndexTempTemp[calcIndex] - 1
--                 end
--             end
--             if isEnoughCard then
--                 local cardEye = 0
--                 -- local isMagicEye = false
--                 for i = 1, maxIndex do
--                     if cardIndexTempTemp[i] == 2 then
--                         cardEye = SwitchToCardData(i)
--                         -- if i == magicIndex then
--                             -- isMagicEye = true
--                         -- end
--                     elseif i ~= magicIndex and magicIndex ~= 0 and (cardIndexTempTemp[i] + cardIndexTempTemp[magicIndex]) == 2 then
--                         cardEye = SwitchToCardData(i)
--                         -- isMagicEye = true
--                     end
--                 end
--                 if cardEye ~= 0 then
--                     return true
--                 end
--             end
--             if index[lessKindItem] == #kindItem then
--                 local i = lessKindItem
--                 while(i > 1)
--                 do
--                     if (index[i - 1] + 1) ~= index[i] then
--                         local newIndex = index[i - 1]
--                         for j = i - 1, lessKindItem + 1 do
--                             index[j] = newIndex + j - i + 2
--                         end
--                         break
--                     end
--                     i = i - 1
--                 end
--                 if i == 1 then
--                     break
--                 end
--             else
--                 index[lessKindItem] = index[lessKindItem] + 1
--             end

--         until(false)
--     end
--     return false
-- end

function MJ_Algorithm:isDuiZi(cardList, relyList)
    if #cardList == 2 then
        if cardList[1] == cardList[2] then
            return true
        end
        if #relyList == 3 then
            return true
        end
    elseif #cardList == 1 then
        if #relyList == 1 then
            return true
        end
        if #relyList == 4 then
            return true
        end
    elseif #cardList == 0 then
        if #relyList == 2 then
            return true
        end
        if #relyList == 0 then
            return true
        end
    end
    return false
end

function MJ_Algorithm:isThree(cardList, relyList)
    if #cardList == 2 then
        if #relyList == 4 then
            return true
        end
    elseif #cardList == 1 then
        if #relyList == 2 then
            return true
        end
    elseif #cardList == 0 then
        if #relyList == 3 then
            return true
        end
        if #relyList == 0 then
            return true
        end
    end
    return false
end

function MJ_Algorithm:SeparateCard(cardList)
    local separateList = {{}, {}, {}, {}}
    for i = 1, #cardList do
        local color = getcolor(cardList[i])
        if color == 0 then
            table.insert(separateList[1], cardList[i])
        elseif color == 1 then
            table.insert(separateList[2], cardList[i])
        elseif color == 2 then
            table.insert(separateList[3], cardList[i])
        else
            table.insert(separateList[4], cardList[i])
        end
    end
    return separateList
end

function MJ_Algorithm:CombineCard(separateList)
    local cardList = {}
    for i = 1, #separateList do
        for j = 1, #separateList[i] do
            table.insert(cardList, separateList[i][j])
        end
    end
    return cardList
end

function MJ_Algorithm:Find456(cardList)
    for i = 1, #cardList do
        if getvalue(cardList[i]) == 4 and i + 1 <= #cardList then
            for j = i + 1, #cardList do
                if getvalue(cardList[j]) == 5 and j + 1 <= #cardList then
                    for k = j + 1, #cardList do
                        if getvalue(cardList[k]) == 6 then
                            local temp = {cardList[i], cardList[j], cardList[k]}
                            return temp
                        end
                    end
                end
            end
        end
    end
    return {}
end

function MJ_Algorithm:Find4Rely6(cardList, relyList)
    if #relyList > 0 then
        for i = 1, #cardList do
            if getvalue(cardList[i]) == 4 and i + 1 <= #cardList then
                for j = i + 1, #cardList do
                    if getvalue(cardList[j]) == 6 then
                        local temp = {cardList[i], cardList[j]}
                        return temp
                    end
                end
            end
        end
    end
    return {}
end

function MJ_Algorithm:RemoveThree(cardList, type)
    if type == 1 then
        -- print_debug("before self:RemoveFromLeft(cardList)")
        self:RemoveFromLeft(cardList)
    elseif type == 2 then
        -- print_debug("before self:RemoveFromRight(cardList)")
        self:RemoveFromRight(cardList)
    -- elseif type == 3 then
    --     -- print_debug("elseif type == 3 then")
    --     -- PrintTableBy64_Debug(cardList)
    --     local cardNum = #cardList
    --     if cardNum % 2 == 0 and cardList[cardNum / 2] ~= cardList[(cardNum / 2) + 1] then
    --         -- print_debug("before self:RemoveFromBothSides(cardList)")
    --         self:RemoveFromBothSides(cardList, 1)
    --         self:RemoveFromRight(cardList)
    --     else
    --         -- print_debug("before self:RemoveFromCenter(cardList)")
    --         self:RemoveFromCenter(cardList)
    --     end
    -- end
    elseif type == 3 then
        -- print_debug("elseif type == 3 then")
        -- PrintTableBy64_Debug(cardList)
        self:RemoveFromBothSides(cardList, 1)
        -- PrintTableBy64_Debug(cardList)
    elseif type == 4 then
        -- print_debug("elseif type == 4 then")
        -- PrintTableBy64_Debug(cardList)
        self:RemoveFromBothSides(cardList, 0)
        -- PrintTableBy64_Debug(cardList)
    elseif type == 5 then
        -- print_debug("elseif type == 5 then")
        -- PrintTableBy64_Debug(cardList)
        self:RemoveFromCenter(cardList)
        -- PrintTableBy64_Debug(cardList)
    end
    return cardList
end

function MJ_Algorithm:RemoveFromLeft(cardList)
    for i = 1, #cardList - 2 do
        for j = i + 1, #cardList - 1 do
            for k = j + 1, #cardList do
                -- if cardList[i] and cardList[j] and cardList[k] then
                    if ((cardList[i] + 1) == cardList[j]) and ((cardList[j] + 1) == cardList[k]) then
                        local temp = {cardList[i], cardList[j], cardList[k]}
                        Delarray(cardList, temp)
                        self:RemoveFromLeft(cardList)
                        return cardList
                    elseif cardList[i] == cardList[j] and cardList[j] == cardList[k] then
                        local temp = {cardList[i], cardList[j], cardList[k]}
                        Delarray(cardList, temp)
                        self:RemoveFromLeft(cardList)
                        return cardList
                    end
                -- end
            end
        end
    end
    return cardList
end
function MJ_Algorithm:RemoveFromRight(cardList)
    for i = #cardList, 3, -1 do
        for j = i - 1, 2, -1 do
            for k = j - 1, 1, -1 do
                -- if cardList[i] and cardList[j] and cardList[k] then
                    if ((cardList[i] - 1) == cardList[j]) and ((cardList[j] - 1) == cardList[k]) then
                        local temp = {cardList[i], cardList[j], cardList[k]}
                        Delarray(cardList, temp)
                        self:RemoveFromRight(cardList)
                        return cardList
                    elseif cardList[i] == cardList[j] and cardList[j] == cardList[k] then
                        local temp = {cardList[i], cardList[j], cardList[k]}
                        Delarray(cardList, temp)
                        self:RemoveFromRight(cardList)
                        return cardList
                    end
                -- end
            end
        end         
    end
    return cardList
end

function MJ_Algorithm:RemoveFeng(cardList)
    for i = 1, #cardList - 2 do
        for j = i + 1, #cardList - 1 do
            for k = j + 1, #cardList do
                -- if cardList[i] and cardList[j] and cardList[k] then
                    if cardList[i] == cardList[j] and cardList[j] == cardList[k] then
                        local temp = {cardList[i], cardList[j], cardList[k]}
                        Delarray(cardList, temp)
                        self:RemoveFeng(cardList)
                        return cardList
                    end
                -- end
            end
        end         
    end
    return cardList
end
function MJ_Algorithm:RemoveFromCenter(cardList)
    if #cardList >= 7 then
        for i = 3, #cardList - 4 do
            for j = i + 1, #cardList - 3 do
                for k = j + 1, #cardList - 2 do
                    if ((cardList[i] + 1) == cardList[j]) and ((cardList[j] + 1) == cardList[k]) then
                        local temp = {cardList[i], cardList[j], cardList[k]}
                        Delarray(cardList, temp)
                        self:RemoveFromCenter(cardList)
                        return cardList
                    elseif cardList[i] == cardList[j] and cardList[j] == cardList[k] then
                        local temp = {cardList[i], cardList[j], cardList[k]}
                        Delarray(cardList, temp)
                        self:RemoveFromCenter(cardList)
                        return cardList
                    end
                end
            end
        end
    end
    return cardList
end

function MJ_Algorithm:RemoveFromBothSides(cardList, direction)
    if #cardList >= 5 then
        if direction == 1 then
            for i = 1, #cardList - 2 do
                for j = i + 1, #cardList - 1 do
                    for k = j + 1, #cardList do
                        if ((cardList[i] + 1) == cardList[j]) and ((cardList[j] + 1) == cardList[k]) then
                            local temp = {cardList[i], cardList[j], cardList[k]}
                            Delarray(cardList, temp)
                            self:RemoveFromBothSides(cardList, 0)
                            return cardList
                        elseif cardList[i] == cardList[j] and cardList[j] == cardList[k] then
                            local temp = {cardList[i], cardList[j], cardList[k]}
                            Delarray(cardList, temp)
                            self:RemoveFromBothSides(cardList, 0)
                            return cardList
                        end
                    end
                end
            end
            -- self:RemoveFromBothSides(cardList, 0)
            -- return cardList
        else
            for i = #cardList, 3, -1 do
                for j = i - 1, 2, -1 do
                    for k = j - 1, 1, -1 do
                        if ((cardList[i] - 1) == cardList[j]) and ((cardList[j] - 1) == cardList[k]) then
                            local temp = {cardList[i], cardList[j], cardList[k]}
                            Delarray(cardList, temp)
                            self:RemoveFromBothSides(cardList, 1)
                            return cardList
                        elseif cardList[i] == cardList[j] and cardList[j] == cardList[k] then
                            local temp = {cardList[i], cardList[j], cardList[k]}
                            Delarray(cardList, temp)
                            self:RemoveFromBothSides(cardList, 1)
                            return cardList
                        end
                    end
                end         
            end
            -- self:RemoveFromBothSides(cardList, 1)
            -- return cardList
        end
        return cardList
    end
    return cardList
end

function MJ_Algorithm:RemoveFromCenterToLeft(cardList) 
    self:Remove456(cardList)
    -- -- print_debug("local isRemove = Remove456(cardList)")
    -- -- PrintTable_Debug(cardList)
    self:RemoveFromRight(cardList)
    return cardList
end

function MJ_Algorithm:RemoveFromCenterToRight(cardList)
    -- -- print_debug("function RemoveFromCenterToRight(cardList)")
    -- -- PrintTable_Debug(cardList)
    self:Remove456(cardList)
    -- -- print_debug("isRemove =", isRemove)
    -- -- PrintTable_Debug(cardList)
    self:RemoveFromLeft(cardList)
    return cardList
end

function MJ_Algorithm:Remove456(cardList)
    for i = 1, #cardList do
        if getvalue(cardList[i]) == 4 and i + 1 <= #cardList then
            for j = i + 1, #cardList do
                if getvalue(cardList[j]) == 5 and j + 1 <= #cardList then
                    for k = j + 1, #cardList do
                        if getvalue(cardList[k]) == 6 then
                            local temp = {cardList[i], cardList[j], cardList[k]}
                            Delarray(cardList, temp)
                            self:Remove456(cardList)
                            return cardList
                        end
                    end
                end
            end
        end
    end
    return cardList
end

function MJ_Algorithm:Remove4Rely6(cardList, relyList)
    if #relyList >= 0 then
        for i = 1, #cardList do
            if getvalue(cardList[i]) == 4 and i + 1 <= #cardList then
                for j = i + 1, #cardList do
                    if getvalue(cardList[j]) == 6 then
                        local temp = {cardList[i], cardList[j]}
                        Delarray(cardList, temp)
                        self:Remove4Rely6(cardList, relyList)
                        return cardList, relyList
                    end
                end
            end
        end
    end
    return cardList, relyList
end

function MJ_Algorithm:RemoveThreeWithRely(cardList, relyList, type)
    if type == 1 then
        -- print_debug("before self:RemoveFromLeftWithRely(cardList, relyList)")
        self:RemoveFromLeftWithRely(cardList, relyList)
    elseif type == 2 then
        -- print_debug("before self:RemoveFromRightWithRely(cardList, relyList)")
        self:RemoveFromRightWithRely(cardList, relyList)
    end
    return cardList
end

function MJ_Algorithm:RemoveFromLeftWithRely(cardList, relyList)
    if #relyList <= 0 then
        return cardList
    end
    for i = 1, #cardList - 1 do
        for j = i + 1, #cardList do
            -- if cardList[i] and cardList[j] and #relyList > 0 then
                if (cardList[i] + 1) == cardList[j] or (cardList[i] + 2) == cardList[j] then
                    local temp = {cardList[i], cardList[j]}
                    Delarray(cardList, temp)
                    table.remove(relyList, 1)
                    self:RemoveFromLeftWithRely(cardList, relyList)
                    return cardList
                elseif cardList[i] == cardList[j] then
                    local temp = {cardList[i], cardList[j]}
                    Delarray(cardList, temp)
                    table.remove(relyList, 1)
                    self:RemoveFromLeftWithRely(cardList, relyList)
                    return cardList
                end
            -- end
        end         
    end
    return cardList
end
function MJ_Algorithm:RemoveFromRightWithRely(cardList, relyList)
    if #relyList <= 0 then
        return cardList
    end
    for i = #cardList, 2, -1 do
        for j = i - 1, 1, -1 do
            -- if cardList[i] and cardList[j] and #relyList > 0 then
                if cardList[i] == cardList[j] then
                    local temp = {cardList[i], cardList[j]}
                    Delarray(cardList, temp)
                    table.remove(relyList, 1)
                    self:RemoveFromRightWithRely(cardList, relyList)
                    return cardList
                elseif (cardList[i] - 1) == cardList[j] or (cardList[i] - 2) == cardList[j] then
                    local temp = {cardList[i], cardList[j]}
                    Delarray(cardList, temp)
                    table.remove(relyList, 1)
                    self:RemoveFromRightWithRely(cardList, relyList)
                    return cardList
                end
            -- end
        end         
    end
    return cardList
end

function MJ_Algorithm:RemoveFengWithRely(cardList, relyList)
    if #relyList <= 0 then
        return cardList
    end
    for i = 1, #cardList - 1 do
        for j = i + 1, #cardList do
            -- if cardList[i] and cardList[j] then
                if cardList[i] == cardList[j] and #relyList > 0 then
                    local temp = {cardList[i], cardList[j]}
                    Delarray(cardList, temp)
                    table.remove(relyList, 1)
                    self:RemoveFengWithRely(cardList, relyList)
                    return cardList
                end
            -- end
        end         
    end
    return cardList
end

-- 给定牌组（满数量牌）和癞子数组，判断是否能胡
function MJ_Algorithm:HuPai(cardList, relyCardList)
    -- print_debug("function HuPai(cardList, relyCard)")
    local cardListTemp = DeepCopy(cardList)
    local relyList = {}
    for i = #cardListTemp, 1, -1 do
        for j = 1, #relyCardList do
            if cardListTemp[i] == relyCardList[j] then
                table.insert(relyList, relyCardList[j])
                table.remove(cardListTemp, i)
            end
        end
    end
    -- print_debug("cardListTemp is")
    -- PrintTableBy64_Debug(cardListTemp)
    -- print_debug("relyList is")
    -- PrintTableBy64_Debug(relyList)
    if self:isDuiZi(cardListTemp, relyList) then
        return true
    end
    table.sort(cardListTemp, function(a, b) return (a) < (b) end)
    local separateList = self:SeparateCard(cardListTemp)
    -- print_debug("separateList is")
    -- PrintTableBy64_Debug(separateList)

    local listRemoveThree = {}
    -- print_debug("before self:RemoveFeng(DeepCopy(separateList[4]))")
    listRemoveThree[4] = self:RemoveFeng(DeepCopy(separateList[4]))
    local index = {}
    local temp = {}
    for i = 1, 3 do
        temp[i] = {}
        if #separateList[i] > 0 then
            table.insert(temp[i], 1)
            table.insert(temp[i], 2)
            if #separateList[i] >= 7 then
                table.insert(temp[i], 3)
                table.insert(temp[i], 4)
                table.insert(temp[i], 5)
            end
        else
            table.insert(temp[i], 0)
        end
    end

    for i = 1, #temp[1] do
        for j = 1, #temp[2] do
            for k = 1, #temp[3] do
                local indexTemp = {temp[1][i], temp[2][j], temp[3][k]}
                table.insert(index, indexTemp)
            end
        end
    end
    local checkIndex = 1
    while(true)
    do
        -- print_debug("index[checkIndex] is")
        -- PrintTableBy64_Debug(index[checkIndex])
        for i = 1, 3 do
            listRemoveThree[i] = self:RemoveThree(DeepCopy(separateList[i]), index[checkIndex][i])
        end
        local removeThreeTemp = self:CombineCard(listRemoveThree)
        if self:isDuiZi(removeThreeTemp, relyList) then
            return true
        end
        table.sort(removeThreeTemp, function(a, b) return (a) < (b) end)
        -- print_debug("-- PrintTableBy64_Debug(removeThreeTemp) -- after remove three, before remove three with rely")
        -- PrintTableBy64_Debug(removeThreeTemp)
        for y = 1, 2 do
            local relyTemp = DeepCopy(relyList)
            local listRemoveRely = self:RemoveThreeWithRely(DeepCopy(removeThreeTemp), relyTemp, y)
            -- print_debug("listRemoveRely -- after remove three with rely")
            -- PrintTableBy64_Debug(listRemoveRely)
            if self:isDuiZi(listRemoveRely, relyTemp) then
                return true
            end
        end
        if checkIndex == #index then
            break
        else
            checkIndex = checkIndex + 1
        end
    end

    -- print_debug("@@@@@@@@@@@@@@@@@@@@@@@@@@Find 456 and 4rely6@@@@@@@@@@@@@@@@@@@@@@@@@@")

    -- for i = 1, 3 do
    --     local temp1 = self:Find456(separateList[i])
    --     if #temp1 > 0 then
    --         local newCardList = DeepCopy(cardList)
    --         Delarray(newCardList, temp1)
    --         -- print_debug("check 456, 456 card is")
    --         -- PrintTableBy64_Debug(temp1)
    --         -- print_debug("after remove 456, cardList is")
    --         -- PrintTableBy64_Debug(newCardList)
    --         if self:HuPai(newCardList, relyCard) then
    --             return true
    --         end
    --     end
    --     local temp2 = self:Find4Rely6(separateList[i], relyList)
    --     if #temp2 > 0 then
    --         local newCardList = DeepCopy(cardList)
    --         table.insert(temp2, relyCard)
    --         Delarray(newCardList, temp2)
    --         -- print_debug("check 4rely6, 4rely6 card is")
    --         -- PrintTableBy64_Debug(temp2)
    --         -- print_debug("after remove 4rely6, cardList is")
    --         -- PrintTableBy64_Debug(newCardList)
    --         if self:HuPai(newCardList, relyCard) then
    --             return true
    --         end
    --     end
    -- end

    -- print_debug("@@@@@@@@@@@@@@@@@@@@@@@@@@Find remove dui zi@@@@@@@@@@@@@@@@@@@@@@@@@@")

    if #relyCardList == 0 then
        return false
    end

    -- 先判断对子，暂时先去掉
    local isCheck1 = {}
    for i = 1, #cardList - 1 do
        for j = i + 1, #cardList do
            if not isCheck1[cardList[i]] and cardList[i] == cardList[j] and not isIncluded(cardList[i], relyCardList) then
                isCheck1[cardList[i]] = true
                local temp1 = DeepCopy(cardList)
                Delarray(temp1, {cardList[i], cardList[j]})
                -- print_debug("check dui zi, card is", cardList[i], cardList[j])
                -- print_debug("after remove dui zi, cardList is")
                -- PrintTableBy64_Debug(temp1)
                if self:isAllThree(temp1, relyCardList) then
                    return true
                end
            end
        end
    end

    -- if #relyList > 0 then
    --     local isCheck2 = {}
    --     for i = 1, #cardList do
    --         if not isCheck2[cardList[i]] and cardList[i] and cardList[i] ~= relyCard then
    --             isCheck2[cardList[i]] = true
    --             local temp1 = DeepCopy(cardList)
    --             Delarray(temp1, {cardList[i], relyCard})
    --             -- print_debug("check dui zi with rely, card is", cardList[i], relyCard)
    --             -- print_debug("after remove dui zi, cardList is")
    --             -- PrintTableBy64_Debug(temp1)
    --             if self:isAllThree(temp1, relyCard) then
    --                 return true
    --             end
    --         end
    --     end
    -- end

    return false
end

-- function MJ_Algorithm:HuPai_DuiZi(cardList, relyCard)
--     -- print_debug("function MJ_Algorithm:HuPai_DuiZi(cardList, relyCard)")
--     local cardListTemp = DeepCopy(cardList)
--     local relyList = {}
--     for i = #cardListTemp, 1, -1 do
--         if cardListTemp[i] == relyCard then
--             table.insert(relyList, relyCard)
--             table.remove(cardListTemp, i)
--         end
--     end
--     table.sort(cardListTemp, function(a, b) return (a) < (b) end)
--     -- print_debug("cardListTemp is")
--     -- PrintTable_Debug(cardListTemp)
--     -- print_debug("relyList is")
--     -- PrintTable_Debug(relyList)

--     local isCheck1 = {}
--     for i = 1, #cardList - 1 do
--         for j = i + 1, #cardList do
--             if not isCheck1[cardList[i]] and cardList[i] == cardList[j] and cardList[i] ~= relyCard then
--                 isCheck1[cardList[i]] = true
--                 local temp1 = DeepCopy(cardList)
--                 Delarray(temp1, {cardList[i], cardList[j]})
--                 if self:isAllThree(temp1, relyCard) then
--                     return true
--                 end
--             end
--         end
--     end

--     -- if #relyList <= 0 then
--     --     return false
--     -- end
--     -- local isCheck2 = {}
--     -- for i = 1, #cardList do
--     --     local card = cardList[i]
--     --     if isCheck2[card] == nil then
--     --         isCheck2[card] = true
--     --         local temp2 = DeepCopy(cardList)
--     --         Delarray(temp2, {card, relyCard})
--     --         if self:isAllThree(temp2, relyCard) then
--     --             return true
--     --         end
--     --     end
--     -- end

--     -- if #relyList <= 1 then
--     --     return false
--     -- end
--     -- local temp3 = DeepCopy(cardList)
--     -- Delarray(temp3, {relyCard, relyCard})
--     -- if self:isAllThree(temp3, relyCard) then
--     --     return true
--     -- end

--     return false
-- end

-- 给定牌组（满数量牌）和癞子数组，判断是否是全三
function MJ_Algorithm:isAllThree(cardList, relyCardList)
    -- print("function MJ_Algorithm:isAllThree(cardList, relyCardList)")
    -- print_debug("function MJ_Algorithm:isAllThree(cardList, relyCard)")
    local cardListTemp = DeepCopy(cardList)
    local relyList = {}
    for i = #cardListTemp, 1, -1 do
        for j = 1, #relyCardList do
            if cardListTemp[i] == relyCardList[j] then
                table.insert(relyList, relyCardList[j])
                table.remove(cardListTemp, i)
            end
        end
    end
    -- print_debug("cardListTemp is")
    -- PrintTableBy64_Debug(cardListTemp)
    -- print_debug("relyList is")
    -- PrintTableBy64_Debug(relyList)
    if self:isDuiZi(cardListTemp, relyList) then
        return true
    end
    table.sort(cardListTemp, function(a, b) return (a) < (b) end)
    local separateList = self:SeparateCard(cardListTemp)
    -- print_debug("separateList is")
    -- PrintTableBy64_Debug(separateList)

    local listRemoveThree = {}
    -- print_debug("before self:RemoveFeng(DeepCopy(separateList[4]))")
    listRemoveThree[4] = self:RemoveFeng(DeepCopy(separateList[4]))
    local index = {}
    local temp = {}
    for i = 1, 3 do
        temp[i] = {}
        if #separateList[i] > 0 then
            table.insert(temp[i], 1)
            table.insert(temp[i], 2)
            if #separateList[i] >= 7 then
                table.insert(temp[i], 3)
                table.insert(temp[i], 4)
                table.insert(temp[i], 5)
            end
        else
            table.insert(temp[i], 0)
        end
    end

    for i = 1, #temp[1] do
        for j = 1, #temp[2] do
            for k = 1, #temp[3] do
                local indexTemp = {temp[1][i], temp[2][j], temp[3][k]}
                table.insert(index, indexTemp)
            end
        end
    end
    local checkIndex = 1
    while(true)
    do
        -- print_debug("index[checkIndex] is")
        -- PrintTableBy64_Debug(index[checkIndex])
        for i = 1, 3 do
            listRemoveThree[i] = self:RemoveThree(DeepCopy(separateList[i]), index[checkIndex][i])
        end
        local removeThreeTemp = self:CombineCard(listRemoveThree)
        if self:isThree(removeThreeTemp, relyList) then
            return true
        end
        table.sort(removeThreeTemp, function(a, b) return (a) < (b) end)
        -- print_debug("-- PrintTableBy64_Debug(removeThreeTemp) -- after remove three, before remove three with rely")
        -- PrintTableBy64_Debug(removeThreeTemp)
        for y = 1, 2 do
            local relyTemp = DeepCopy(relyList)
            local listRemoveRely = self:RemoveThreeWithRely(DeepCopy(removeThreeTemp), relyTemp, y)
            -- print_debug("listRemoveRely -- after remove three with rely")
            -- PrintTableBy64_Debug(listRemoveRely)
            if self:isThree(listRemoveRely, relyTemp) then
                return true
            end
        end
        if checkIndex == #index then
            break
        else
            checkIndex = checkIndex + 1
        end
    end

    -- for i = 1, 3 do
    --     local temp1 = self:Find456(separateList[i])
    --     if #temp1 > 0 then
    --         local newCardList = DeepCopy(cardList)
    --         Delarray(newCardList, temp1)
    --         -- print_debug("check 456, 456 card is")
    --         -- PrintTableBy64_Debug(temp1)
    --         -- print_debug("after remove 456, cardList is")
    --         -- PrintTableBy64_Debug(newCardList)
    --         if self:isAllThree(newCardList, relyCard) then
    --             return true
    --         end
    --     end
    --     local temp2 = self:Find4Rely6(separateList[i], relyList)
    --     if #temp2 > 0 then
    --         local newCardList = DeepCopy(cardList)
    --         table.insert(temp2, relyCard)
    --         Delarray(newCardList, temp2)
    --         -- print_debug("check 4rely6, 4rely6 card is")
    --         -- PrintTableBy64_Debug(temp2)
    --         -- print_debug("after remove 4rely6, cardList is")
    --         -- PrintTableBy64_Debug(newCardList)
    --         if self:isAllThree(newCardList, relyCard) then
    --             return true
    --         end
    --     end
    -- end
    return false
end

-- 给定牌组（缺一）和癞子数组，计算得出需要进行胡牌判断的牌
function MJ_Algorithm:FindPossibleCard(cardlist, relyCardList)
    local possible = {}
    local check = {}
    if relyCardList and #relyCardList > 0 then
        for i = 1, #relyCardList do
            table.insert(possible, relyCardList[i])
            check[relyCardList[i]] = true
        end
    end
    for i = 1, #cardlist do
        if getcolor(cardlist[i]) <= 2 then
            if not check[cardlist[i] - 1] and getvalue(cardlist[i]) ~= 1 then
                table.insert(possible, (cardlist[i] - 1))
                check[(cardlist[i] - 1)] = true
            end
            if not check[cardlist[i] + 1] and getvalue(cardlist[i]) ~= 9 then
                table.insert(possible, (cardlist[i] + 1))
                check[(cardlist[i] + 1)] = true
            end
            if not check[cardlist[i] - 2] and getvalue(cardlist[i]) > 2 then
                table.insert(possible, (cardlist[i] - 2))
                check[(cardlist[i] - 2)] = true
            end
            if not check[cardlist[i] + 2] and getvalue(cardlist[i]) < 8 then
                table.insert(possible, (cardlist[i] + 2))
                check[(cardlist[i] + 2)] = true
            end
            if not check[cardlist[i]] then
                table.insert(possible, cardlist[i])
                check[cardlist[i]] = true
            end
        else
            if not check[cardlist[i]] then
                table.insert(possible, cardlist[i])
                check[cardlist[i]] = true
            end
        end
    end
    return possible
end

-- 给定牌组（满数目牌）、癞子牌组、计算剩余牌数的函数（可选）和kindid（可选），获取tinghumap和youjincard
-- tinghumap存的是打出的牌和可胡的牌的键值对，可胡的牌里包含该牌的剩余数量信息（默认为1）
-- youjincard存的是打出之后能胡任意牌的牌，不包含任意牌的剩余数量信息
-- 在youjincard里的牌，不会出现在tinghumap里
function MJ_Algorithm:EstimateTingHu(cardlist, relyCardList, fun_leftcard)
    local time_in = os.clock()
    local tinghumap = {}
    local youjincard = {}
    local listtemp = DeepCopy(cardlist)
    if (#listtemp - 2) % 3 ~= 0 then
        return {}, {}
    end
    local estimatetemp = DeepCopy(cardlist)
    local hasestimatedout = {}
    for i = 1, #listtemp do
        if not hasestimatedout[listtemp[i]] then
            -- print("i, listtemp", i, listtemp[i])
            Delarray(estimatetemp, {listtemp[i]})
            hasestimatedout[listtemp[i]] = true
            if self:TingHuAllCard(estimatetemp, relyCardList) then
                -- 打出listtemp[i]则能胡任意牌
                table.insert(youjincard, listtemp[i])
            else
                local possible = self:FindPossibleCard(estimatetemp, relyCardList)
                -- PrintTable(possible)
                for j = 1, #possible do
                    table.insert(estimatetemp, possible[j])
                    if self:HuPai(estimatetemp, relyCardList) then
                        if not tinghumap[listtemp[i]] then
                            tinghumap[listtemp[i]] = {}
                            -- print("i", i)
                        end
                        local cardnum
                        if fun_leftcard then
                            cardnum = fun_leftcard(possible[j])
                        else
                            cardnum = 1
                        end
                        local tingmap = {possible[j], cardnum}
                        table.insert(tinghumap[listtemp[i]], tingmap)
                    end
                    table.remove(estimatetemp, #estimatetemp)
                end
            end
            table.insert(estimatetemp, listtemp[i])
        end
    end
    local time_out = os.clock()
    print("EstimateTingHu, during time = ", time_out - time_in)
    return tinghumap, youjincard
end

-- 给定牌组（缺一牌组）、癞子牌组和kindid（可选），获取canhucard
-- canhucard存的是给定牌组能胡的牌
function MJ_Algorithm:EstimateCanHu(cardlist, relyCardList)
    local time_in = os.clock()
    local canhucard = {}
    local listtemp = DeepCopy(cardlist)
    if (#listtemp - 2) % 3 == 0 then
        return {}
    end
    if self:TingHuAllCard(listtemp, relyCardList) then
        -- 能胡任意牌则将0x66存入canhucard
        table.insert(canhucard, 0x66)
    else
        -- 不能胡任意牌，则判断能胡具体哪些牌
        local possible = self:FindPossibleCard(listtemp, relyCardList)
        for j = 1, #possible do
            table.insert(listtemp, possible[j])
            if self:HuPai(listtemp, relyCardList) then
                table.insert(canhucard, possible[j])
            end
            table.remove(listtemp, #listtemp)
        end
    end
    local time_out = os.clock()
    print("EstimateTingHu, during time = ", time_out - time_in)
    return canhucard
end

-- 给定牌组（缺一）和癞子牌组，判断是否能胡任意牌
function MJ_Algorithm:TingHuAllCard(cardlist, relyCardList)
    -- print("function MJ_Algorithm:TingHuAllCard(cardlist, relyCardList)")
    -- PrintTable(cardlist)
    -- PrintTable(relyCardList)
    if #relyCardList == 0 then
        return false
    end
    local temp = DeepCopy(cardlist)
    Delarray_Once(temp, relyCardList)
    -- PrintTable(temp)
    if #temp % 3 == 0 and self:isAllThree(temp, relyCardList) then
        return true
    else
        return false
    end
end

---------------------------------------小白龙部分---------------------------------------

-- 给定牌组（满数量牌）、癞子数组和kindid，以kindid对应的特殊胡牌方式，判断是否能胡
function MJ_Algorithm:HuPai_Special(cardlist, relyCardList, kindid)
    if kindid == 110001 then
        Delarray_Once(cardlist,relyCardList)

        if  self:Thepairsd(cardlist,relyCardList) == true then 
            return true 
        end 
    end
    return false
end


-- 给定牌组（缺一）、癞子数组和kindid，以kindid对应的特殊胡牌方式，判断是否能胡任意牌
function MJ_Algorithm:TingHuAllCard_Special(cardlist, relyCardList, kindid)
    -- print(#cardlist,"七小对出牌七小对出牌七小对出牌七小对出牌七小对出牌七小对出牌")
    if kindid == 110001 then
       
        local datacadlist = DeepCopy(cardlist)
        Delarray(datacadlist,relyCardList)
        print("进了七小对",#datacadlist,#relyCardList)
        if  self:Thepairs(datacadlist,relyCardList) == true then 
            print("七小对打印正确七小对打印正确七小对打印正确七小对打印正确七小对打印正确七小对打印正确七小对打印正确")
            return true 
        end 
    end
    return false 
end

function MJ_Algorithm:EstimateTingHu_XBL(cardlist, tinghumap, youjincard,relyCardList,shlecard,kindid)
    local listtemp = DeepCopy(cardlist)
    if (#listtemp - 2) % 3 ~= 0 then
        return
    end
    local estimatetemp = DeepCopy(cardlist)
    local qitimatetemp = DeepCopy(cardlist)
    local hasestimatedout = {}

    for i = 1, #listtemp do
        if not hasestimatedout[listtemp[i]] then
            -- print("listtemp, i", listtemp[i], i)
            Delarray(estimatetemp, {listtemp[i]})
            Delarray(qitimatetemp, {listtemp[i]})
            hasestimatedout[listtemp[i]] = true
            local tingspecial = self:TingHuAllCard_Special(qitimatetemp, relyCardList, kindid)
            print(tingspecial,#cardlist,#relyCardList,"听任意牌")
            if self:HuPai(estimatetemp, relyCardList) or tingspecial  then
                --判断是否单吊，单吊即游金
                local temp = DeepCopy(estimatetemp)
                Delarray(temp, {0x35})
                if (#temp % 3 == 0 and self:isAllThree(cardlist, relyCardList)) or tingspecial then
                    print("hurenyipaild")
                    table.insert(youjincard, listtemp[i])
                else
                    local possible = self:FindPossibleCard(estimatetemp, relyCardList)
                    local qiduihu = self:qiduizhao(cardlist)
                    -- PrintTable(possible)
                    for j = 1, #possible do
                        table.insert(estimatetemp, possible[j])
                        if self:HuPai(estimatetemp, relyCardList) then
                            if not tinghumap[listtemp[i]] then
                                tinghumap[listtemp[i]] = {}
                                -- print("i", i)
                            end
                            local cardnum = self:findnotseenum(possible[j],shlecard)
                            local tingmap = {possible[j], cardnum}
                            table.insert(tinghumap[listtemp[i]], tingmap)
                        end
                        table.remove(estimatetemp, #estimatetemp)
                    end
                    if  kindid == 110001 then 
                        PrintTable(qiduihu)
                       
                        
                        for j =1, #qiduihu do
                              local feinei = DeepCopy(qitimatetemp)
                                table.insert(feinei,qiduihu[j])
                                print("普通听七小对的牌",#feinei,#qiduihu)
                                if  self:HuPai_Special(feinei, relyCardList, kindid)  then 
                                     print("听七小对的牌正确的")
                                    if not tinghumap[listtemp[i]] then
                                        tinghumap[listtemp[i]] = {}
                                    end
                                    local cardnum
                                    if fun_leftcard then
                                        cardnum = self:findnotseenum(qiduihu[j],shlecard)            
                                    else
                                        cardnum = 1
                                    end
                                    local tingmap = {qiduihu[j], cardnum}
                                    table.insert(tinghumap[listtemp[i]], tingmap)
                                end 
                               
                        end 
                    end 
                end
            else 
                local qiduihu = self:qiduizhao(cardlist)
                if  kindid == 110001  then 
                    PrintTable(qiduihu)
                    print(#qitimatetemp,#qiduihu)
                    for j =1, #qiduihu do
                            local feinei = DeepCopy(qitimatetemp)
                            table.insert(feinei,qiduihu[j])
                            print("普通听七小对的de牌",#feinei,#qiduihu)
                            if  self:TingHuAllCard_Special(feinei, relyCardList, kindid)  then 
                                 print("听七小对的de牌正确的")
                                if not tinghumap[listtemp[i]] then
                                    tinghumap[listtemp[i]] = {}
                                end
                                local cardnum
                                if fun_leftcard then
                                    cardnum = self:findnotseenum(qiduihu[j],shlecard)            
                                else
                                    cardnum = 1
                                end
                                local tingmap = {qiduihu[j], cardnum}
                                table.insert(tinghumap[listtemp[i]], tingmap)
                            end 
                           
                    end 
                end 

            end
            table.insert(qitimatetemp,listtemp[i])
            table.insert(estimatetemp, listtemp[i])
        end
    end
    return
end


function MJ_Algorithm:qiduizhao(cardlist)
    local qiduihud = DeepCopy(cardlist)
    local houlaide = {}
    for i =1, #cardlist do 
        table.insert(houlaide,qiduihud[i])
        Delarray(qiduihud,{cardlist[i]})
    end 
    table.insert(houlaide,0x35)
    return houlaide
end 

function MJ_Algorithm:findnotseenum(card,shlecard) --找剩余牌的数量
    local num = 0
    for i = 1, #shlecard do
        if shlecard[i] == card then
            num = num + 1
        end
    end

    return num
end

function MJ_Algorithm:Delarrays(list,dellist)
	for j = #list, 1, -1 do
		if dellist == list[j] then 
			table.remove(list,j)
		end
	end
    return list
end


function MJ_Algorithm:fun_Thepairs(card)
    table.sort(card, function ( a,b ) return( a > b) end )
    if #card >= 2 then 
        for i = 1,#card-1 do 
            for j = i+1, #card do 
                if card[i] and  card[j] then
                    if card[i] == card[j] then 
                        local tum = {card[i],card[j]}
                        Delarray(card,tum)
                        self:fun_Thepairs(card)
                    end 
                end
            end 
        end
    end
    return card
end 


function MJ_Algorithm:Thepairsd(card,tump)
    if #card + #tump == 13 then 
        local  list = DeepCopy(card)
        local hu =  self:fun_Thepairs(list)
        if #hu == 0 then 
            return true 
        end  
        if #tump> #hu then
            return true 
        elseif #hu == 1 and #tump == 3 then 
            return true
        end  
    end
    return false
end


function MJ_Algorithm:Thepairs(card,tump)
    
    if #card + #tump == 14 then 
        local  list = DeepCopy(card)
        local hu =  self:fun_Thepairs(list)
        print("七小对胡的牌剩下的",#hu,#tump)

        if #hu ==0 then  
            return true 
        elseif #hu ==#tump then
            return true 
        end  
    end

    return false
end

---------------------------------------小白龙部分---------------------------------------

----------------------------------------胡牌函数----------------------------------------

return MJ_Algorithm