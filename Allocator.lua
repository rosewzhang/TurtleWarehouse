
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

