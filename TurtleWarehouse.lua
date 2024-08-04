require 'CCTurtle'
require 'Turtle'
require 'Allocator'

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
        -- a reasonable upper bound: nonexistent items should always be treated as if they'll be allocated
        -- at a very high numbered barrel
        local biggest = self.turtle.maxX * self.turtle.maxY * self.turtle.maxZ
        for i = 1, stacksThisTrip do
            self.turtle.selectFunc(i)
            self.turtle.suckDownFunc()
            local itemDetail = self.turtle.getItemDetailFunc()
            if itemDetail == nil then 
                stacksThisTrip = i - 1
                numStacks = 0
                break
            else
                slotTops[i] = self.tops[itemDetail.name] or biggest
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
