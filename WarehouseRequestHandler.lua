require 'TurtleWarehouse'

function new_WarehouseRequestHandler(turtleWarehouse, inChannel, outChannel)
    self = {}
    self.turtleWarehouse = turtleWarehouse or error('expected argument for turtleWarehouse')
    self.inChannel = inChannel or error('expected argument for inChannel')
    self.outChannel = outChannel or error('expected argument for outChannel')
    return self
end

--  inChannel: channel on which users send requests
--  outChannel: channel on which the turtle sends confirmations
--      there is never a guarantee that the items will actually arrive
-- 
--  format for a request:
--      turtle_warehouse w/d/q/l quantity port itemID
--      w/d/q/l is a single character for withdraw, deposit, query or list
--      quantity is in stacks for deposits and individual items for withdraws. only withdraw and deposit care about quantity
--      quantity and port must have leading zeros to be 4-digit numbers
--      itemID is the id we look for, e.g. minecraft:stone. only withdraw and query care about itemID
--      lie! list cares about itemID, but we use this slot to convey a substring we wish to search
function WarehouseRequestHandler_run(self)
    modem = peripheral.find('modem')
    modem.open(self.inChannel)
    modem.open(self.outChannel)
    while true do
        -- wait for a message
        local event, side, channel, replyChannel, message, distance
        repeat
            event, side, channel, replyChannel, message, distance = os.pullEvent('modem_message')
        until channel == self.inChannel
        -- we just got a letter, we just got a letter, we just got a letter
        -- it doesn't matter who it's from. If it's an order, fulfill it
        WarehouseRequestHandler_processMessage(self, message)
    end
end

function WarehouseRequestHandler_processMessage(self, message)
    if string.sub(message, 1, 17) ~= 'turtle_warehouse ' then return end
    -- possibly a valid request, set up to extract the data
    local requestType, itemID, quantity, port
    -- try to extract the type
    requestType = string.sub(message, 18, 18)
    if requestType ~= 'w' and requestType ~= 'd' and requestType ~= 'q' and requestType ~= 'l' then return end
    -- now try to extract the quantity
    if string.sub(message, 19, 19) ~= ' ' then return end
    quantity = tonumber(string.sub(message, 20, 23))
    if quantity == nil then return end
    if string.sub(message, 24, 24) ~= ' ' then return end
    -- now try to extract the port
    port = tonumber(string.sub(message, 25, 28))
    if port == nil then return end
    if quantity > 9999 or quantity < 0 then return end 
    if port > 9999 or port < 0 then return end 
    -- try to extract the itemID
    print('here4')
    if string.sub(message, 29, 29) ~= ' ' then return end
    itemID = string.sub(message, 30, -1)

    -- we have all the information. If we've made it to this stage, then the order is valid, so
    -- let's fulfill it.
    print('requestType: '.. requestType or 'nil')
    print('itemID: '.. itemID or 'nil')
    print('quantity: '.. quantity or 'nil')
    print('port: '.. port or 'nil')
    if requestType == 'd' then
        WarehouseRequestHandler_fulfillDepositRequest(self, quantity, port)
    elseif requestType == 'w' then
        WarehouseRequestHandler_fulfillWithdrawRequest(self, itemID, quantity, port)
    elseif requestType == 'q' then
        WarehouseRequestHandler_fulfillQueryRequest(self, itemID)
    elseif requestType == 'l' then
        WarehouseRequestHandler_fulfillListRequest(self, itemID)
    end
end

function WarehouseRequestHandler_fulfillDepositRequest(self, quantity, port)
    TurtleWarehouse_deposit(self.turtleWarehouse, port, quantity)
end

function WarehouseRequestHandler_fulfillWithdrawRequest(self, itemid, quantity, port)
    TurtleWarehouse_deposit(self.turtleWarehouse, itemid, quantity, port)
end

function WarehouseRequestHandler_fulfillQueryRequest(self, itemid)
    local count = self.turtleWarehouse.quantities[itemid] or 0
    local message = 'warehouse_output '..tostring(count)
    rednet.transmit(outChannel, inChannel, tostring(count))
    print('query requests not yet implemented')
    -- TODO: implement query requests
end

function WarehouseRequestHandler_fulfillListRequest(self, itemid)
    print('list requests not yet implemented')
    -- TODO: implement list requests
    -- use self.turtleWarehouse.quantities
    -- send back a message
end

local turtleWarehouse = new_TurtleWarehouse_CC('temp.txt', 8, 9, 8)
handler = new_WarehouseRequestHandler(turtleWarehouse, 1, 2)
WarehouseRequestHandler_run(handler)
