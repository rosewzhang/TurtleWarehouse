
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
