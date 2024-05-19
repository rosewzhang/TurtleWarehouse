require 'Turtle'

function getTurtleDirHelper(maxTurns)
    if maxTurns < 0 then error('turtle is surrounded on all sides, cannot get direction') end
    if turtle.inspect() then
        turtle.turnLeft()
        local value = ((getTurtleDirHelper(maxTurns - 1) - 1 - 1) % 4) + 1
        turtle.turnRight()
        return value
    end
    local x1, y1, z1 = gps.locate()
    turtle.forward()
    local x2, y2, z2 = gps.locate()
    turtle.back()
    local dx, dz = x2-x1, z2-z1
    if dx == 1 then return 1
    elseif dx == -1 then return 3
    elseif dz == 1 then return 4
    elseif dz == -1 then return 2
    else error("direction is not possible! dx, dz = "..tostring(dx)..", "..tostring(dz))
    end
end

function getTurtleDir()
    return getTurtleDirHelper(3)
end

function new_CCTurtle(maxX, maxY, maxZ, absX0, absY0, absZ0)
    return new_Turtle(maxX, maxY, maxZ, gps.locate, getTurtleDir, turtle.forward, turtle.turnLeft,
            turtle.turnRight, turtle.down, turtle.up, turtle.getFuelLevel, turtle.refuel, 
            turtle.suckDown, turtle.dropDown, turtle.select, turtle.getItemDetail, absX0, absY0, absZ0) 
end
