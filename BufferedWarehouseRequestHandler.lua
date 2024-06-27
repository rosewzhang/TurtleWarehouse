function main()
    -- local turtleWarehouse = new_TurtleWarehouse_CC('warehousedata.txt', 15, 15, 10)
    local turtleWarehouse = new_TurtleWarehouse_CCFromFile('warehousedata.txt')
    handler = new_BufferedWarehouseRequestHandler(turtleWarehouse, 1, 2, 10)
    BufferedWarehouseRequestHandler_run(handler)
end

require 'TurtleWarehouse'
require 'WarehouseRequestHandler'

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

-- TODO: handle query requests instantly bc they fast
-- add one thing to the buffer
function BufferedWarehouseRequestHandler_receive(self)
    -- wait for a message
    print('(b) waiting for a message...')
    local event, side, channel, replyChannel, message, distance
    repeat
        event, side, channel, replyChannel, message, distance = os.pullEvent('modem_message')
    until channel == self.inChannel
    print('(b) message received: '..message or '')
    BufferedWarehouseRequestHandler_addToBuffer(self, message)
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
