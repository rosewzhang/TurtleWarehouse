function main()
    -- local turtleWarehouse = new_TurtleWarehouse_CC('warehousedata.txt', 15, 15, 10)
    local turtleWarehouse = new_TurtleWarehouse_CCFromFile('warehousedata.txt')
    handler = new_BufferedWarehouseRequestHandler(turtleWarehouse, 1, 2, 10)
    BufferedWarehouseRequestHandler_run(handler)
end

-- direction: unit circle but quarter turns instead of radians but 0 is 4

function new_Turtle(maxX, maxY, maxZ,
        getPosFunc, getDirFunc, forwardFunc, turnLeftFunc, turnRightFunc, downFunc, upFunc,
        getFuelLevelFunc, refuelFunc, suckDownFunc, dropDownFunc, selectFunc, getItemDetailFunc,
        absX0, absY0, absZ0)
    local self = {}
    self.maxX, self.maxY, self.maxZ = maxX, maxY, maxZ
    self.getPosFunc, self.getDirFunc = getPosFunc, getDirFunc
    self.forwardFunc, self.turnLeftFunc, self.turnRightFunc = forwardFunc, turnLeftFunc, turnRightFunc
    self.downFunc, self.upFunc = downFunc, upFunc
    self.getFuelLevelFunc, self.refuelFunc, self.suckDownFunc, self.dropDownFunc, self.selectFunc
            = getFuelLevelFunc, refuelFunc, suckDownFunc, dropDownFunc, selectFunc
    self.getItemDetailFunc = getItemDetailFunc
    self.direction = self.getDirFunc() or error("couldn't get turtle direction")
    if absX0 == nil or absY0 == nil or absZ0 == nil then
        self.absX0, self.absY0, self.absZ0 = getPosFunc()
    else
        self.absX0, self.absY0, self.absZ0 = absX0, absY0, absZ0
    end
    Turtle_turnToDirection(self, 1)
    return self
end

-- relative but not virtual
function Turtle_getPosition(self)
    absX, absY, absZ = self.getPosFunc()
    return absX - self.absX0 + 1, absY - self.absY0 + 1, absZ - self.absZ0 + 1
end

function Turtle_turnToDirection(self, direction)
    if self.direction == direction then return end
    if (self.direction - 1 - 1) % 4 + 1 == direction then
        self.turnRightFunc()
        self.direction = direction
        return
    end
    if (self.direction - 1 + 1) % 4 + 1 == direction then
        self.turnLeftFunc()
        self.direction = direction
        return
    end
    self.turnLeftFunc()
    self.turnLeftFunc()
    self.direction = direction
end

-- level 1 is at y = 1. Level 2 is at y = 3.
function Turtle_goToVirtual(self, destX, destY, destZ)
    local x, y, z = Turtle_getPosition(self)
    if y ~= destY then
        -- go to 1, y, 1
        if x ~= 1 then Turtle_turnToDirection(self, 3) end
        for i = 1, x - 1 do
            self.forwardFunc()
        end
        if z ~= 1 then Turtle_turnToDirection(self, 2) end
        for i = 1, z - 1 do
            self.forwardFunc()
        end
        -- go up or down
        if y > destY then
            for i = 1, y - destY do
                self.downFunc()
            end
        else 
            for i = 1, destY - y do
                self.upFunc()
            end
        end
        x = 1
        y = destY
        z = 1
    end
    -- go 
    local dx, dz = destX - x, destZ - z
    if dx > 0 then
        Turtle_turnToDirection(self, 1)
        for i = 1, dx do self.forwardFunc() end
    elseif dx < 0 then
        Turtle_turnToDirection(self, 3)
        for i = 1, -dx do self.forwardFunc() end
    end
    if dz > 0 then
        Turtle_turnToDirection(self, 4)
        for i = 1, dz do self.forwardFunc() end
    elseif dz < 0 then
        Turtle_turnToDirection(self, 2)
        for i = 1, -dz do self.forwardFunc() end
    end
end

-- expects slot 1 to be empty
-- leaves self.direction in an undefined (but consistent with reality) state
function Turtle_refuelIfNecessary(self)
    if self.getFuelLevelFunc() < 50 * (self.maxX + self.maxY + self.maxZ) then
        local oldX, oldY, oldZ = Turtle_getPosition(self)
        Turtle_goToVirtual(self, 1, 1, 1)
        self.selectFunc(1)
        self.suckDownFunc()
        self.refuelFunc()
        Turtle_refuelIfNecessaryHelper(self)
        Turtle_goToVirtual(self, oldX, oldY, oldZ)
    end
end

function Turtle_refuelIfNecessaryHelper(self)
    if self.getFuelLevelFunc() > 100 * (self.maxX + self.maxY + self.maxZ) then return end
    self.selectFunc(1)
    self.suckDownFunc()
    self.refuelFunc()
    Turtle_refuelIfNecessaryHelper(self)
end




function getTurtleDirHelper(maxTurns)
    if maxTurns < 0 then error('turtle is surrounded on all sides, cannot get direction') end
    if turtle.inspect() then
        turtle.turnLeft()
        local value = ((getTurtleDirHelper(maxTurns - 1) - 1 - 1) % 4) + 1
        turtle.turnRight()
        return value
    end
    local x1, y1, z1 = gps.locate()
    turtle.forward()
    local x2, y2, z2 = gps.locate()
    turtle.back()
    local dx, dz = x2-x1, z2-z1
    if dx == 1 then return 1
    elseif dx == -1 then return 3
    elseif dz == 1 then return 4
    elseif dz == -1 then return 2
    else error("direction is not possible! dx, dz = "..tostring(dx)..", "..tostring(dz))
    end
end

function getTurtleDir()
    return getTurtleDirHelper(3)
end

function new_CCTurtle(maxX, maxY, maxZ, absX0, absY0, absZ0)
    return new_Turtle(maxX, maxY, maxZ, gps.locate, getTurtleDir, turtle.forward, turtle.turnLeft,
            turtle.turnRight, turtle.down, turtle.up, turtle.getFuelLevel, turtle.refuel, 
            turtle.suckDown, turtle.dropDown, turtle.select, turtle.getItemDetail, absX0, absY0, absZ0) 
end




function new_HoleLinkedList()
    return {firstHole = nil}
end

function HoleLinkedList_pushFront(self, address, holeSize)
    local newHole = {address=address, holeSize=holeSize, nextPtr=self.firstHole} 
    self.firstHole = newHole
end

function HoleLinkedList_popFront(self)
    local temp = self.firstHole
    self.firstHole = self.firstHole.nextPtr
    return temp
end

function HoleLinkedList_popHole(self)
    if self.firstHole.holeSize > 1 then
        self.firstHole.holeSize = self.firstHole.holeSize - 1
        local returnValue = self.firstHole.address
        self.firstHole.address = self.firstHole.address + 1
        self.firstHole.holeSize = self.firstHole.holeSize - 1
        return returnValue
    end
    return HoleLinkedList_popFront(self).address 
end

-- creates a new allocator with no allocations
function new_Allocator(size)
    local object = {}
    object.holes = new_HoleLinkedList()
    HoleLinkedList_pushFront(object.holes, 1, size)
    -- falsy if free, truthy if allocated (in Lua, only nil and false are falsy)
    object.allocatedTable = {}
    return object
end

-- takes unique ownership of allocatedDict
function new_Allocator_existing(size, allocatedDict)
    local object = {}
    object.holes = new_HoleLinkedList()
    object.allocatedTable = allocatedDict

    local last, first
    local i = size
    while true do
        while allocatedDict[i] and i >= 1 do
            i = i - 1
        end
        if i < 1 then break end
        last = i
        -- we found the end of a hole, now find its beninging
        while not allocatedDict[i] and i >= 1 do
            i = i - 1
        end
        first = i + 1
        HoleLinkedList_pushFront(object.holes, first, last - first + 1)
    end
    return object
end

--[[
function Allocator_debugPrintSelf(self)
    print('allocator: ')
    print(self.allocatedTable)
    local nextNode = self.holes.firstHole
    while nextNode ~= nil do
        print('address '..tostring(nextNode.address)..', size '..tostring(nextNode.holeSize))
        nextNode = nextNode.nextPtr
    end
    print('')
end
--]]

function Allocator_requestAllocation(self)
    if self.holes.firstHole == nil then
        error("no memory to allocate, exiting")
    end
    local address = HoleLinkedList_popHole(self.holes)
    self.allocatedTable[address] = true
    return address
end


function Allocator_freeAllocation(self, address)
    HoleLinkedList_pushFront(self.holes, address, 1)
    self.allocatedTable[address] = nil
end




function addressToVirtualCoords(n, xmax, ymax, zmax)
    local x, y, z
    local temp
    y = -3 + 2 * (2 + math.floor((n-1) / ((xmax-1) * (zmax-1))))
    temp = 1 + (n-1) % ((xmax-1) * (zmax-1))
    z = 2 + math.floor((temp-1) / (xmax-1))
    x = 2 + (temp-1) % (xmax-1)
    return x, y, z
end

function portToVirtualCoords(n, maxX, maxY, maxZ)
    local x, y, z
    local temp
    y = -1 + 2 * (math.floor((n-1)/((maxX-1)+(maxZ-1)))+1)
    temp = (n-1) % ((maxX-1)+(maxZ-1))+1
    if temp > maxX - 1 then
        x, z = 1, temp-(maxX-1)+1
    else
        x, z = temp+1, 1
    end
    return x, y, z
end

function TurtleWarehouse_addressToVirtualCoords(self, n)
    local xmax, ymax, zmax = self.turtle.maxX, self.turtle.maxY, self.turtle.maxZ
    local x, y, z
    local temp
    y = -3 + 2 * (2 + math.floor((n-1) / ((xmax-1) * (zmax-1))))
    temp = 1 + (n-1) % ((xmax-1) * (zmax-1))
    z = 2 + math.floor((temp-1) / (xmax-1))
    x = 2 + (temp-1) % (xmax-1)
    return x, y, z
end

function TurtleWarehouse_portToVirtualCoords(self, n)
    local maxX, maxY, maxZ = self.turtle.maxX, self.turtle.maxY, self.turtle.maxZ
    local x, y, z
    local temp
    y = -1 + 2 * (math.floor((n-1)/((maxX-1)+(maxZ-1)))+1)
    temp = (n-1) % ((maxX-1)+(maxZ-1))+1
    if temp > maxX - 1 then
        x, z = 1, temp-(maxX-1)+1
    else
        x, z = temp+1, 1
    end
    return x, y, z
end

function TurtleWarehouse_writeToFile(self)
    shell.run('rm', '.turtlewarehousetemp')
    local tempFile = fs.open('.turtlewarehousetemp', 'w')
    tempFile.writeLine(tostring(self.turtle.absX0))
    tempFile.writeLine(tostring(self.turtle.absY0))
    tempFile.writeLine(tostring(self.turtle.absZ0))
    tempFile.writeLine(tostring(self.turtle.maxX))
    tempFile.writeLine(tostring(self.turtle.maxY))
    tempFile.writeLine(tostring(self.turtle.maxZ))
    tempFile.writeLine('')
    for itemName, quantity in pairs(self.quantities) do
        tempFile.writeLine(itemName)
        tempFile.writeLine(tostring(math.floor(quantity)))
        local top = self.tops[itemName]
        while top ~= nil do
            tempFile.writeLine(top)
            top = self.nextPtr[top]
        end
        tempFile.writeLine('')
    end
    tempFile.close()
    shell.run('rm', self.fileName)
    shell.run('mv', '.turtlewarehousetemp', self.fileName)
end

function new_TurtleWarehouse(turtle, fileName)
    local self = {}
    self.numSlots = (turtle.maxX - 1) * math.floor(turtle.maxY / 2) * (turtle.maxZ - 1)
    self.numPorts = math.floor(turtle.maxY / 2) * (turtle.maxX + turtle.maxZ)
    self.turtle = turtle
    self.quantities = {}
    self.tops = {}
    self.nextPtr = {}
    self.allocator = new_Allocator(self.numSlots)
    self.fileName = fileName
    return self
end

function new_TurtleWarehouse_CC(fileName, maxX, maxY, maxZ, absX0, absY0, absZ0)
    return new_TurtleWarehouse(new_CCTurtle(maxX, maxY, maxZ, absX0, absY0, absZ0), fileName)
end

function new_TurtleWarehouse_CCFromFile(fileName)
    local f = fs.open(fileName, 'r')
    local absX0 = tonumber(f.readLine())
    local absY0 = tonumber(f.readLine())
    local absZ0 = tonumber(f.readLine())
    local maxX = tonumber(f.readLine())
    local maxY = tonumber(f.readLine())
    local maxZ = tonumber(f.readLine())
    local self = new_TurtleWarehouse_CC(fileName, maxX, maxY, maxZ, absX0, absY0, absZ0)
    f.readLine()
    local allocatedDict = {}
    local nextLine = f.readLine()
    while nextLine ~= nil and nextLine ~= '' do
        local itemName = nextLine
        local quantity = tonumber(f.readLine())
        self.quantities[itemName] = quantity
        self.tops[itemName] = tonumber(f.readLine())
        allocatedDict[self.tops[itemName]] = true
        nextLine = f.readLine()
        local bottom = self.tops[itemName]
        while nextLine ~= '' and nextLine ~= nil do
            self.nextPtr[bottom] = tonumber(nextLine)
            bottom = tonumber(nextLine)
            allocatedDict[tonumber(nextLine)] = true
            nextLine = f.readLine()
        end
        nextLine = f.readLine()
    end
    f.close()
    self.allocator = new_Allocator_existing(self.numSlots, allocatedDict)
    return self
end 

-- determines the proper place for the item in the stack that the turtle has selected, deposits
-- it to the proper inventory
function TurtleWarehouse_depositItemInSlot(self, slot)
    self.turtle.selectFunc(slot)
    local itemDetail = self.turtle.getItemDetailFunc()
    local name, count = itemDetail.name, itemDetail.count
    if count == 0 then return end
    if self.quantities[name] == nil then self.quantities[name] = 0 end    
    if self.quantities[name] ~= 0 then
        if not self.tops[name] then error('quantity for item '..name..' nonzero but no top') end
        Turtle_goToVirtual(self.turtle,
                addressToVirtualCoords(self.tops[name], self.turtle.maxX, self.turtle.maxY, self.turtle.maxZ))
        self.turtle.dropDownFunc()
        local newItemDetail = self.turtle.getItemDetailFunc()
        local newCount; if newItemDetail == nil then newCount = 0 else newCount = newItemDetail.count end
        self.quantities[name] = self.quantities[name] + (count - newCount)
        if newCount == 0 then
            TurtleWarehouse_writeToFile(self)
            return
        end
        -- count is not zero, so the barrel is full, so we must request a new barrel from the allocator
        local newTop = Allocator_requestAllocation(self.allocator)
        self.nextPtr[newTop] = self.tops[name]
        self.tops[name] = newTop
        Turtle_goToVirtual(self.turtle,
                addressToVirtualCoords(self.tops[name], self.turtle.maxX, self.turtle.maxY, self.turtle.maxZ))
        self.turtle.dropDownFunc()
        self.quantities[name] = self.quantities[name] + newCount
    else
        local address = Allocator_requestAllocation(self.allocator)
        self.tops[name] = address
        self.nextPtr[address] = nil
        self.quantities[name] = self.quantities[name] + count
        Turtle_goToVirtual(self.turtle,
                addressToVirtualCoords(self.tops[name], self.turtle.maxX, self.turtle.maxY, self.turtle.maxZ))
        self.turtle.dropDownFunc()
        TurtleWarehouse_writeToFile(self)
    end
end

function TurtleWarehouse_deposit(self, port, numStacks)
    -- outer loop loops over once every trip
    while numStacks > 0 do
        print('HERE0')
        Turtle_refuelIfNecessary(self.turtle)
        print('HERE1')
        Turtle_goToVirtual(self.turtle, portToVirtualCoords(port, self.turtle.maxX, self.turtle.maxY,
                self.turtle.maxZ))
        print('HERE2')
        local stacksThisTrip
        if numStacks > 16 then 
            stacksThisTrip = 16
            numStacks = numStacks - 16
        else
            stacksThisTrip = numStacks
            numStacks = 0
        end
        -- optimization: sort all stacks by destination (top) before depositing them all
        -- bubble sort cuz its n=16 and who cares
        slotTops = {}
        self.turtle.selectFunc(1)
        for i = 1, stacksThisTrip do
            self.turtle.selectFunc(i)
            self.turtle.suckDownFunc()
            local itemDetail = self.turtle.getItemDetailFunc()
            if itemDetail == nil then 
                stacksThisTrip = i - 1
                numStacks = 0
                break
            else
                slotTops[i] = self.tops[itemDetail.name]
            end
        end
        order = {}
        for i = 1, stacksThisTrip do
            -- order[i] is to be visited i'th
            order[i] = i
        end
        for i = 1, stacksThisTrip do
            for j = 1, stacksThisTrip-1 do
                -- compare j with j-1 and swap if needed
                local jValue = slotTops[order[j]]
                local jPlusOneValue = slotTops[order[j+1]]
                if jValue > jPlusOneValue then
                    local temp = order[j]
                    order[j] = order[j+1]
                    order[j+1] = temp
                end
            end
        end
        for i = 1, stacksThisTrip do
            -- print('DEBUG: depositing item in slot' .. order[i])
            if self.turtle.getItemDetailFunc(order[i]) == nil then return end
            TurtleWarehouse_depositItemInSlot(self, order[i])
        end
    end
end

-- returns true if successful and false if not
function TurtleWarehouse_withdraw(self, itemName, quantity, port)
    if self.quantities[itemName] == nil or self.quantities[itemName] < quantity then return false end
    self.quantities[itemName] = self.quantities[itemName] - quantity
    TurtleWarehouse_writeToFile(self)
    local count = 0
    while true do
        Turtle_goToVirtual(self.turtle, TurtleWarehouse_addressToVirtualCoords(self, self.tops[itemName]))
        for i = 1, 16 do
            self.turtle.selectFunc(i)
            if not self.turtle.suckDownFunc() then
                -- no more in top
                --
                -- if things start breaking, maybe check here to confirm available inventory slots
                -- otherwise, there would be an erroneous detection of an empty chest
                self.tops[itemName] = self.nextPtr[self.tops[itemName]]
                Turtle_goToVirtual(self.turtle,
                        addressToVirtualCoords(self.tops[name], self.turtle.maxX, self.turtle.maxY, self.turtle.maxZ))
            end
            count = count + self.turtle.getItemDetailFunc().count
            if count >= quantity then 
                turtle.dropDown(count - quantity) 
                -- count satisfied
                Turtle_goToVirtual(self.turtle, TurtleWarehouse_portToVirtualCoords(self, port))
                for i = 1, 16 do
                    self.turtle.selectFunc(i)
                    if not self.turtle.dropDownFunc() then break end
                end
                return true
            end
        end
        -- no more space in turtle
        Turtle_goToVirtual(self.turtle, TurtleWarehouse_portToVirtualCoords(self, port))
        for i = 1, 16 do self.turtle.selectFunc(i) self.turtle.dropDownFunc() end
    end
end

--[[
local turtleWarehouse = new_TurtleWarehouse_CC('temp.txt', 8, 9, 8)
TurtleWarehouse_deposit(turtleWarehouse, 2, 5)
--]]



--[[ 
function main()
    -- local turtleWarehouse = new_TurtleWarehouse_CC('warehousedata.txt', 15, 15, 10)
    local turtleWarehouse = new_TurtleWarehouse_CCFromFile('warehousedata.txt')
    handler = new_WarehouseRequestHandler(turtleWarehouse, 1, 2)
    WarehouseRequestHandler_run(handler)
end
--]]


function new_WarehouseRequestHandler(turtleWarehouse, inChannel, outChannel)
    self = {}
    self.turtleWarehouse = turtleWarehouse or error('expected argument for turtleWarehouse')
    self.inChannel = inChannel or error('expected argument for inChannel')
    self.outChannel = outChannel or error('expected argument for outChannel')
    self.modem = peripheral.find('modem') or error('no modem found')
    return self
end

--  inChannel: channel on which users send requests
--  outChannel: channel on which the turtle sends confirmations
--      there is never a guarantee that the items will actually arrive
-- 
--  format for a request:
--      turtle_warehouse requestID w/d/q/l quantity port itemID
--
--      requestID is (randomly generated by a client) an 8-character string that uniquely identifies a request
--
--      w/d/q/l is a single character for withdraw, deposit, query or list
--
--      for a withdraw request: w, quantity, port, itemID (quantity is in number of individual items)
--      for a deposit request: d, quantity, port (quantity is in number of stacks)
--      for a query request: q, quantity, port, itemID (quantity and port are an identifier of the requester, itemID is a specific item (no substring search))
--      for a list request: l, quantity, port, itemID (quantity and port are ID of requester, itemID is a substring to search (if blank, list all))
function WarehouseRequestHandler_run(self)
    self.modem.open(self.inChannel)
    self.modem.open(self.outChannel)
    while true do
        -- wait for a message
        print('waiting for a message...')
        local event, side, channel, replyChannel, message, distance
        repeat
            event, side, channel, replyChannel, message, distance = os.pullEvent('modem_message')
        until channel == self.inChannel
        print('message received: '..message or '')
        -- we just got a letter, we just got a letter, we just got a letter
        -- it doesn't matter who it's from. If it's an order, fulfill it
        WarehouseRequestHandler_processMessage(self, message)
    end
end

-- TODO: try to make this error in bugtesting
function WarehouseRequestHandler_processMessage(self, message)
    print('HERE00')
    if not message then return end
    print('HERE10')
    if string.sub(message, 1, 17) ~= 'turtle_warehouse ' then return end
    print('HERE20')
    -- possibly a valid request, set up to extract the data
    local requestID, requestType, itemID, quantity, port
    -- try to extract request id
    requestID = string.sub(message, 18, 25)
    if string.sub(message, 26, 26) ~= ' ' then return end
    print('HERE30')
    -- try to extract the type
    requestType = string.sub(message, 27, 27)
    if requestType ~= 'w' and requestType ~= 'd' and requestType ~= 'q' and requestType ~= 'l' then return end
    -- now try to extract the quantity
    if string.sub(message, 28, 28) ~= ' ' then return end
    print('HERE40')
    -- try to extract the type
    quantity = tonumber(string.sub(message, 30, 33))
    if quantity == nil then return end
    if string.sub(message, 33, 33) ~= ' ' then return end
    print('HERE50')
    -- now try to extract the port
    port = tonumber(string.sub(message, 34, 37))
    if port == nil then return end
    print('HERE60')
    if quantity > 9999 or quantity < 0 then return end 
    print('HERE70')
    if port > 9999 or port < 0 then return end 
    print('HERE80')
    -- try to extract the itemID
    if string.sub(message, 38, 38) ~= ' ' then return end
    print('HERE90')
    itemID = string.sub(message, 39, -1)

    -- we have all the information. If we've made it to this stage, then the order is valid, so
    -- let's fulfill it.
    if requestType == 'd' then
        WarehouseRequestHandler_fulfillDepositRequest(self, requestID, quantity, port)
    elseif requestType == 'w' then
        WarehouseRequestHandler_fulfillWithdrawRequest(self, requestID, itemID, quantity, port)
    elseif requestType == 'q' then
        WarehouseRequestHandler_fulfillQueryRequest(self, requestID, itemID, quantity, port)
    elseif requestType == 'l' then
        WarehouseRequestHandler_fulfillListRequest(self, requestID, itemID, quantity, port)
    end
end

function WarehouseRequestHandler_fulfillDepositRequest(self, requestID, quantity, port)
    TurtleWarehouse_deposit(self.turtleWarehouse, port, quantity)
end

function WarehouseRequestHandler_fulfillWithdrawRequest(self, requestID, itemid, quantity, port)
    print('HERE100')
    print(requestID)
    print(itemid)
    print(quantity)
    print(port)
    TurtleWarehouse_withdraw(self.turtleWarehouse, itemid, quantity, port)
end

function WarehouseRequestHandler_fulfillQueryRequest(self, requestID, itemid, quantity, port)
    local message = 'turtle_warehouse '..requestID.. ' q '..quantity..' '..port..' '..'query requests not yet implemented'
    self.modem.transmit(self.outChannel, self.inChannel, message)
    print('query requests not yet implemented')
    -- TODO: implement query requests
end

-- takes a number x and returns it as a 4 character string with possible leading zeroes
-- if x is greater than 9999, it returns 9999
-- if x is not an integer, it is floored
function toFourDigits(x) 
    local str = tostring(math.min(math.floor(x), 9999))
    if string.len(str) == 0 then return '0000'..str end
    if string.len(str) == 1 then return '000'..str end
    if string.len(str) == 2 then return '00'..str end
    if string.len(str) == 3 then return '0'..str end
    if string.len(str) == 4 then return ''..str end
    error('honestly i have no idea how this one managed to break')
end

-- returns true if a is a substring of b
function isSubstring(a, b)
    local aLength = string.len(a)
    local bLength = string.len(b)
    if bLength < aLength then return false end
    for i = 1, bLength - aLength + 1 do
        if a == string.sub(b, i, i + aLength - 1) then
            return true
        end
    end
    return false
end

function WarehouseRequestHandler_fulfillListRequest(self, requestID, itemid, quantity, port)
    local message = 'turtle_warehouse '..requestID..' l '..toFourDigits(quantity)..' '..toFourDigits(port)..' \n'
    local itemsDict = self.turtleWarehouse.quantities 
    for k, v in pairs(itemsDict) do
        if isSubstring(itemid, k) then
            message = message..'\n'..tostring(v)..' '..k
        end
    end
    self.modem.transmit(self.outChannel, self.inChannel, message)
end

--[[
main()
--]]




function new_BufferedWarehouseRequestHandler(turtleWarehouse, inChannel, outChannel, bufferCapacity)
    self = new_WarehouseRequestHandler(turtleWarehouse, inChannel, outChannel) -- super()
    -- circular buffer
    self.bufferCapacity = bufferCapacity
    self.bufferSize = 0
    self.bufferStart = 1
    self.bufferEnd = bufferCapacity
    self.buffer = {}
    self.doneProcessing = false
    return self
end

function BufferedWarehouseRequestHandler_addToBuffer(self, item)
    if self.bufferSize >= self.bufferCapacity then return nil end
    self.bufferEnd = self.bufferEnd % self.bufferCapacity + 1 -- update end
    self.buffer[self.bufferEnd] = item 
    self.bufferSize = self.bufferSize + 1

end

function BufferedWarehouseRequestHandler_removeFromBuffer(self)
    if self.bufferSize <= 0 then return nil end
    local item = self.buffer[self.bufferStart]
    self.buffer[self.bufferStart] = nil
    self.bufferStart = self.bufferStart % self.bufferCapacity + 1 -- update start
    self.bufferSize = self.bufferSize - 1
    return item 
end

function BufferedWarehouseRequestHandler_processAll(self) 
    while self.bufferSize > 0 do
        local nextItem = BufferedWarehouseRequestHandler_removeFromBuffer(self)
        -- we just got a letter, we just got a letter, we just got a letter
        -- it doesn't matter who it's from. If it's an order, fulfill it
        WarehouseRequestHandler_processMessage(self, nextItem)
        print('processed: '..nextItem)

    end
    self.doneProcessing = true
end

-- add one thing to the buffer
function BufferedWarehouseRequestHandler_receive(self)
    -- wait for a message
    local event, side, channel, replyChannel, message, distance
    repeat
        event, side, channel, replyChannel, message, distance = os.pullEvent('modem_message')
    until channel == self.inChannel
    requestType = string.sub(message, 27, 27)
    -- handle list requests instantly bc they fast, everything else goes in the buffer
    if requestType == 'l' then
        WarehouseRequestHandler_processMessage(self, message)
    else
        BufferedWarehouseRequestHandler_addToBuffer(self, message)
    end
end

-- to be run while processAll is running
function BufferedWarehouseRequestHandler_receiveUntilDoneProcessing(self)
    while not self.doneProcessing do
        BufferedWarehouseRequestHandler_receive(self)
    end
end

function BufferedWarehouseRequestHandler_run(self)
    self.modem.open(self.inChannel)
    self.modem.open(self.outChannel)
    while true do
        if self.bufferSize <= 0 then BufferedWarehouseRequestHandler_receive(self) end
        -- buffer has 1
        self.doneProcessing = false
        parallel.waitForAll(function() BufferedWarehouseRequestHandler_processAll(self) end, 
                            function() BufferedWarehouseRequestHandler_receiveUntilDoneProcessing(self) end)
    end
end

main()


