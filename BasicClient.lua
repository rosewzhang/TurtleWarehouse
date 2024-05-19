modem = peripheral.find('modem') or error()
modem.open(1)
modem.open(2)
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

