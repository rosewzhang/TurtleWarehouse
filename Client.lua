function main() 
    modem = peripheral.find('modem') or error('no modem found')
    modem.open(1)
    modem.open(2)

    COMMAND_MODE = false
    search_query = ''
    command_buffer = ''
    item_list = get_item_list()

    while true do
        local event, key, is_held = os.pullEvent("key")
        print('DEBUG: got key '..keys.getName(key))
        if COMMAND_MODE then
            -- process command mode key event
            if keys.getName(key) == 'tab' then
                COMMAND_MODE = false
                print('DEBUG: changed mode to query update')
                COMMAND_MODE = true
            elseif keys.getName(key) == 'enter' then
                send_command()
            elseif keys.getName(key) == 'delete' then
                clear_command()
            else
                command_buffer = command_buffer .. keys.getName(key)
            end
        else 
            -- process query editing mode key event
            if keys.getName(key) == 'tab' then
                COMMAND_MODE = false
                print('DEBUG: changed mode to command')
            elseif keys.getName(key) == 'delete' then
                clear_search_query()
            else
                search_query = search_query .. keys.getName(key)
                update_query()
            end
        end
    end
end

function clear_command() 
    print('DEBUG: cleared commmand buffer')
    command_buffer = ''
end

function send_command() 
    print('DEBUG: sending command: '..command_buffer)
    -- TODO: send
    command_buffer = ''
end

function clear_search_query() 
    print('DEBUG: cleared search query')
    search_query = ''
end

function update_query()
    print('DEBUG: updating query for substring '..search_query)
end

function get_item_list()
    modem.transmit(1, 2, outMessage)
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    return item_list
end


while true do
    print('Input message to send. Format:')
    print('turtle_warehouse w/d/q/l quantity port id')
    outMessage = io.read()
    modem.transmit(1, 2, outMessage)
    print(outMessage.sub(19, 19))
    local type = string.sub(outMessage, 18, 18)
    if type == 'q' or type == 'l' then
        repeat
            event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        until channel == 2
        print(message)
    end
end

main()
