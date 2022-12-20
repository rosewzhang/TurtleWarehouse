require 'Turtle'

consoleTurtleX = 1
consoleTurtleY = 1
consoleTurtleZ = 1
consoleTurtleDirection = 2

function consoleTurtleGetPosFunc() return consoleTurtleX, consoleTurtleY, consoleTurtleZ end
function consoleTurtleGetDirFunc() return consoleTurtleDirection end

function consoleTurtleForwardFunc()
    print('going forward')
    if consoleTurtleDirection == 1 then
        consoleTurtleX = consoleTurtleX + 1
    elseif consoleTurtleDirection == 2 then
        consoleTurtleZ = consoleTurtleZ - 1
    elseif consoleTurtleDirection == 3 then
        consoleTurtleX = consoleTurtleX - 1
    elseif consoleTurtleDirection == 4 then
        consoleTurtleZ = consoleTurtleZ + 1
    end
end

function consoleTurtleTurnLeftFunc()
    print('turning left')
    consoleTurtleDirection = (consoleTurtleDirection + 1 - 1) % 4 + 1
end

function consoleTurtleTurnRightFunc()
    print('turning right')
    consoleTurtleDirection = (consoleTurtleDirection - 1 - 1) % 4 + 1
end

function consoleTurtleUpFunc()
    print('going up')
    consoleTurtleY = consoleTurtleY + 1
end

function consoleTurtleDownFunc()
    print('going down')
    consoleTurtleY = consoleTurtleY - 1
end

function new_ConsoleTurtle(maxX, maxY, maxZ)
    return new_Turtle(maxX, maxY, maxZ, consoleTurtleGetPosFunc, consoleTurtleGetDirFunc,
            consoleTurtleForwardFunc, consoleTurtleTurnLeftFunc, consoleTurtleTurnRightFunc,
            consoleTurtleDownFunc, consoleTurtleUpFunc)
end

turtle = new_ConsoleTurtle(10, 10, 10)
Turtle_goToVirtual(turtle, 2, 2, 2)
