WAREHOUSE_OUT_PORT = 1
WAREHOUSE_IN_PORT = 2

function main() 
    modem = peripheral.find('modem') or error('no modem found')
    modem.open(1)
    modem.open(2)

    inCommandMode = false
    searchQuery = ''
    commandBuffer = ''
    itemList = getItemList()
    searchResults = {}

    updateQuery()
    drawWindow()
    while true do
        local event, key, isHeld = os.pullEvent('key')
        -- searchResults[10] = keys.getName(key)
        if inCommandMode then
            -- process command mode key event
            if keys.getName(key) == 'tab' then
                inCommandMode = false
            elseif keys.getName(key) == 'enter' then
                sendCommand()
            elseif keys.getName(key) == 'backspace' then
                clearCommand()
            elseif keys.getName(key) == 'space' then
                commandBuffer = commandBuffer .. ' '
            elseif isDigit(keys.getName(key)) then
                commandBuffer = commandBuffer .. digits[keys.getName(key)]
                updateQuery()
            elseif keys.getName(key) == 'semicolon' then
                commandBuffer = commandBuffer .. ':'
            elseif keys.getName(key) == 'minus' then
                commandBuffer = commandBuffer .. '_'
                updateQuery()
            elseif keys.getName(key) == 'period' then
                commandBuffer = commandBuffer .. '.'
                updateQuery()
            elseif string.match (keys.getName(key), '^[a-z]$') or isDigit(keys.getName(key)) then
                commandBuffer = commandBuffer .. keys.getName(key)
            end
        else -- not inCommandMode 
            -- process query editing mode key event
            if keys.getName(key) == 'tab' then
                inCommandMode = true
            elseif keys.getName(key) == 'backspace' then
                clearSearchQuery()
                updateQuery()
            elseif keys.getName(key) == 'space' then
                searchQuery = searchQuery.. ' '
                updateQuery()
            elseif keys.getName(key) == 'semicolon' then
                searchQuery = searchQuery .. ':'
                updateQuery()
            elseif keys.getName(key) == 'minus' then
                searchQuery = searchQuery .. '_'
            elseif keys.getName(key) == 'period' then
                searchQuery = searchQuery .. '.'
            elseif isDigit(keys.getName(key)) then
                searchQuery = searchQuery .. digits[keys.getName(key)]
                updateQuery()
            elseif string.match (keys.getName(key), '^[a-z]$') then
                searchQuery = searchQuery .. keys.getName(key)
                updateQuery()
            end
        end
        drawWindow()
    end
end

digits = {}
digits['one'] = '1'
digits['two'] = '2'
digits['three'] = '3'
digits['four'] = '4'
digits['five'] = '5'
digits['six'] = '6'
digits['seven'] = '7'
digits['eight'] = '8'
digits['nine'] = '9'
digits['zero'] = '0'
function isDigit(keyName) 
    return digits[keyName] and true or false
end

function drawWindow() 
    local myWindow = window.create(term.current(), 1, 1, 52, 19)
    myWindow.setBackgroundColour(colours.black)
    myWindow.setTextColour(colours.white)
    myWindow.clear()
    myWindow.setCursorPos(2, 2) myWindow.write('Search for an item...')
    myWindow.setCursorPos(2, 17) myWindow.write('Send a command...')
    myWindow.setCursorPos(2, 3) myWindow.write(inCommandMode and '    '..searchQuery or '>>> '..searchQuery..'_')
    myWindow.setCursorPos(2, 18) myWindow.write(inCommandMode and '>>> '..commandBuffer..'_' or '    '..commandBuffer)

    for i = 1, 11 do
        local line = i + 4
        myWindow.setCursorPos(2, line) myWindow.write(searchResults[i] and searchResults[i] or '                                                 ')
    end


    for i = 2, 18 do myWindow.setCursorPos(1, i) myWindow.write('|') end
    for i = 2, 18 do myWindow.setCursorPos(51, i) myWindow.write('|') end
    myWindow.setCursorPos(1, 1) myWindow.write('+-------------------------------------------------+')
    myWindow.setCursorPos(1, 4) myWindow.write('+-------------------------------------------------+')
    myWindow.setCursorPos(1, 16) myWindow.write('+-------------------------------------------------+')
    myWindow.setCursorPos(1, 19) myWindow.write('+-------------------------------------------------+')
end

function clearCommand() 
    commandBuffer = ''
end

function constructWithdrawMessage(quantity, name, port)
    if not name or name == '.' then name = searchQuery end
    if not port or port == '.' then port = WAREHOUSE_OUT_PORT end
    -- substring search in itemList
    local candidates = {}
    local i = 1
    firstLine = true
    for line in toLines(itemList) do
        if i > 2 then 
            if isSubstring(name, line) then
                candidates[#candidates + 1] = line
            end
        else 
            firstLine = false
        end
        i = i + 1
    end
    -- pick the shortest candidate
    if #candidates == 0 then return end
    shortest_candidate = candidates[1]
    for i, candidate in pairs(candidates) do
        if string.len(candidate) < string.len(shortest_candidate) then 
            shortest_candidate = candidate
        end
    end
    words = {}
    for word in toWords(shortest_candidate) do
        words[#words + 1] = word
    end
    if not words[2] then return end
    return 'turtle_warehouse w '..toFourDigits(quantity)..' '..toFourDigits(port)..' '..words[2]
end

function sendCommand() 
    words = {}
    for word in toWords(commandBuffer) do
        words[#words + 1] = word
    end

    if words[1] == 'r' then 
        itemList = getItemList() 
        updateQuery()
        drawWindow()
    elseif words[1] == 'w' then
        local outMessage = constructWithdrawMessage(words[2], words[3], words[4])
        if outMessage then modem.transmit(1, 2, outMessage) end
    elseif words[1] == 'd' then
        quantity = tonumber(words[2])
        local outMessage = 'turtle_warehouse d '..toFourDigits(words[2] or 27)..' '..toFourDigits(words[3] or WAREHOUSE_IN_PORT)..' '
        modem.transmit(1, 2, outMessage)
    end

    commandBuffer = ''
end

function clearSearchQuery() 
    searchQuery = ''
end

function updateQuery()
    searchResults = {}
    i = 1
    firstLine = true
    for line in toLines(itemList) do
        if i > 2 then 
            if isSubstring(searchQuery, line) then
                searchResults[#searchResults + 1] = line
            end
        else 
            firstLine = false
        end
        i = i + 1
    end

end

function getItemList()
    local outMessage = 'turtle_warehouse l 0000 0000 '

    modem.transmit(1, 2, outMessage)
    local type = string.sub(outMessage, 18, 18)
    if type == 'q' or type == 'l' then
        repeat
            event, side, channel, replyChannel, message, distance = os.pullEvent('modem_message')
        until channel == 2
        print('message: '..message)
    end
    return message
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

function toWords(s)
    if s:sub(-1)~=" " then s=s.." " end
    return s:gmatch("(.-) ")
end

function toLines(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
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

main()


