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
    local f = fs.open(self.fileName, 'w')
    f.writeLine(tostring(self.turtle.maxX))
    f.writeLine(tostring(self.turtle.maxY))
    f.writeLine(tostring(self.turtle.maxZ))
    f.writeLine('')
    for itemName, quantity in pairs(self.quantities) do
        f.writeLine(itemName)
        f.writeLine(tostring(math.floor(quantity)))
        local top = self.tops[itemName]
        while top ~= nil do
            f.writeLine(top)
            top = self.nextPtr[top]
        end
        f.writeLine('')
    end
    f.close()
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

function new_TurtleWarehouse_CC(fileName, maxX, maxY, maxZ)
    return new_TurtleWarehouse(new_CCTurtle(maxX, maxY, maxZ), fileName)
end

function new_TurtleWarehouse_CCFromFile(fileName)
    local f = fs.open(fileName, 'r')
    local maxX = tonumber(fs.readLine())
    local maxY = tonumber(fs.readLine())
    local maxZ = tonumber(fs.readLine())
    local self = new_TurtleWarehouse_CC(filename, maxX, maxY, maxZ)
    fs.readLine()
    local nextLine = fs.readLine()
    while nextLine ~= nil do
        local itemName = fs.readLine()
        local quantity = fs.readLine()
        self.quantities[itemName] = quantity
        self.tops[itemName] = tonumber(fs.readLine())
        nextLine = fs.readLine()
        local bottom = self.tops[itemName]
        while nextLine ~= '' and nextLine ~= nil do
            self.nextPtr[bottom] = tonumber(nextLine)
            bottom = tonumber(nextLine)
            nextLine = fs.readLine()
        end
    end
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
        if newCount == 0 then return end
        -- count is not zero, so the barrel is full, so we must request a new barrel from the allocator
        local newTop = Allocator_requestAllocation(self.allocator)
        self.nextPtr[newTop] = self.tops[name]
        self.tops[name] = newTop
        Turtle_goToVirtual(self.turtle,
                addressToVirtualCoords(self.tops[name], self.turtle.maxX, self.turtle.maxY, self.turtle.maxZ))
        self.turtle.dropDownFunc()
        self.quantities[name] = self.quantities[name] + newCount
        -- TODO: fix this garbage
        -- TODO: allow more than a barrel of storage per item
    else
        local address = Allocator_requestAllocation(self.allocator)
        self.tops[name] = address
        self.nextPtr[address] = nil
        self.quantities[name] = self.quantities[name] + count
        Turtle_goToVirtual(self.turtle,
                addressToVirtualCoords(self.tops[name], self.turtle.maxX, self.turtle.maxY, self.turtle.maxZ))
        self.turtle.dropDownFunc()
    end
end

function TurtleWarehouse_deposit(self, port, numStacks)
    Turtle_refuelIfNecessary(self.turtle)
    -- outer loop loops over once every trip
    while numStacks > 0 do
        Turtle_goToVirtual(self.turtle, portToVirtualCoords(port, self.turtle.maxX, self.turtle.maxY,
                self.turtle.maxZ))
        local stacksThisTrip
        if numStacks > 16 then 
            stacksThisTrip = 16
            numStacks = numStacks - 16
        else
            stacksThisTrip = numStacks
            numStacks = 0
        end
        self.turtle.selectFunc(1)
        for i = 1, stacksThisTrip do self.turtle.suckDownFunc() end
        for i = 1, stacksThisTrip do
            if self.turtle.getItemDetailFunc(i) == nil then return end
            TurtleWarehouse_depositItemInSlot(self, i)
        end
    end
end

-- returns true if successful and false if not
function TurtleWarehouse_withdraw(self, itemName, quantity, port)
    if self.quantities[itemName] == nil or self.quantities[itemName] < quantity then return false end
    self.quantities[itemName] = self.quantities[itemName] - quantity
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
