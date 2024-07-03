--[[ 
function main()
    -- local turtleWarehouse = new_TurtleWarehouse_CC('warehousedata.txt', 15, 15, 10)
    local turtleWarehouse = new_TurtleWarehouse_CCFromFile('warehousedata.txt')
    handler = new_WarehouseRequestHandler(turtleWarehouse, 1, 2)
    WarehouseRequestHandler_run(handler)
end
--]]

require 'TurtleWarehouse'

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
    if not message then return end
    if string.sub(message, 1, 17) ~= 'turtle_warehouse ' then return end
    -- possibly a valid request, set up to extract the data
    local requestID, requestType, itemID, quantity, port
    -- try to extract request id
    requestID = string.sub(message, 18, 25)
    if string.sub(message, 26, 26) ~= ' ' then return end
    -- try to extract the type
    requestType = string.sub(message, 27, 27)
    if requestType ~= 'w' and requestType ~= 'd' and requestType ~= 'q' and requestType ~= 'l' then return end
    -- now try to extract the quantity
    if string.sub(message, 28, 28) ~= ' ' then return end
    quantity = tonumber(string.sub(message, 20, 23))
    if quantity == nil then return end
    if string.sub(message, 33, 33) ~= ' ' then return end
    -- now try to extract the port
    port = tonumber(string.sub(message, 34, 37))
    if port == nil then return end
    if quantity > 9999 or quantity < 0 then return end 
    if port > 9999 or port < 0 then return end 
    -- try to extract the itemID
    if string.sub(message, 38, 38) ~= ' ' then return end
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
    TurtleWarehouse_withdraw(self.turtleWarehouse, itemid, quantity, port)
end

function WarehouseRequestHandler_fulfillQueryRequest(self, requestID, itemid, quantity, port)
    local message = 'turtle_warehouse q '..requestID..' '..quantity..' '..port..' '..'query requests not yet implemented'
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
    local message = 'turtle_warehouse l '..requestID..' '..toFourDigits(quantity)..' '..toFourDigits(port)..' \n'
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
