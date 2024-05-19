-- direction: unit circle but quarter turns instead of radians but 0 is 4

function new_Turtle(maxX, maxY, maxZ,
        getPosFunc, getDirFunc, forwardFunc, turnLeftFunc, turnRightFunc, downFunc, upFunc,
        getFuelLevelFunc, refuelFunc, suckDownFunc, dropDownFunc, selectFunc, getItemDetailFunc,
        absX0, absY0, absZ0)
    local self = {}
    self.maxX, self.maxY, self.maxZ = maxX, maxY, maxZ
    self.getPosFunc, self.getDirFunc = getPosFunc, getDirFunc
    self.forwardFunc, self.turnLeftFunc, self.turnRightFunc = forwardFunc, turnLeftFunc, turnRightFunc
    self.downFunc, self.upFunc = downFunc, upFunc
    self.getFuelLevelFunc, self.refuelFunc, self.suckDownFunc, self.dropDownFunc, self.selectFunc
            = getFuelLevelFunc, refuelFunc, suckDownFunc, dropDownFunc, selectFunc
    self.getItemDetailFunc = getItemDetailFunc
    self.direction = self.getDirFunc() or error("couldn't get turtle direction")
    if absX0 == nil or absY0 == nil or absZ0 == nil then
        self.absX0, self.absY0, self.absZ0 = getPosFunc()
    else
        self.absX0, self.absY0, self.absZ0 = absX0, absY0, absZ0
    end
    Turtle_turnToDirection(self, 1)
    return self
end

function Turtle_getPosition(self)
    absX, absY, absZ = self.getPosFunc()
    return absX - self.absX0 + 1, absY - self.absY0 + 1, absZ - self.absZ0 + 1
end

function Turtle_turnToDirection(self, direction)
    if self.direction == direction then return end
    if (self.direction - 1 - 1) % 4 + 1 == direction then
        self.turnRightFunc()
        self.direction = direction
        return
    end
    if (self.direction - 1 + 1) % 4 + 1 == direction then
        self.turnLeftFunc()
        self.direction = direction
        return
    end
    self.turnLeftFunc()
    self.turnLeftFunc()
    self.direction = direction
end

-- level 1 is at y = 1. Level 2 is at y = 3.
function Turtle_goToVirtual(self, destX, destLevel, destZ)
    local destY = destLevel * 2 - 1
    local x, y, z = Turtle_getPosition(self)
    if y ~= destY then
        -- go to 1, y, 1
        if x ~= 1 then Turtle_turnToDirection(self, 3) end
        for i = 1, x - 1 do
            self.forwardFunc()
        end
        if z ~= 1 then Turtle_turnToDirection(self, 2) end
        for i = 1, z - 1 do
            self.forwardFunc()
        end
        -- go up or down
        if y > destY then
            for i = 1, y - destY do
                self.downFunc()
            end
        else 
            for i = 1, destY - y do
                self.upFunc()
            end
        end
        x = 1
        y = destY
        z = 1
    end
    -- go 
    local dx, dz = destX - x, destZ - z
    if dx > 0 then
        Turtle_turnToDirection(self, 1)
        for i = 1, dx do self.forwardFunc() end
    elseif dx < 0 then
        Turtle_turnToDirection(self, 3)
        for i = 1, -dx do self.forwardFunc() end
    end
    if dz > 0 then
        Turtle_turnToDirection(self, 4)
        for i = 1, dz do self.forwardFunc() end
    elseif dz < 0 then
        Turtle_turnToDirection(self, 2)
        for i = 1, -dz do self.forwardFunc() end
    end
end

-- expects slot 1 to be empty
-- leaves self.direction in an undefined (but consistent with reality) state
function Turtle_refuelIfNecessary(self)
    if self.getFuelLevelFunc() < 50 * (self.maxX + self.maxY + self.maxZ) then
        local oldX, oldY, oldZ = Turtle_getPosition(self)
        Turtle_goToVirtual(self, 1, 1, 1)
        self.selectFunc(1)
        self.suckDownFunc()
        self.refuelFunc()
        Turtle_refuelIfNecessaryHelper(self)
        Turtle_goToVirtual(self, oldX, oldY, oldZ)
    end
end

function Turtle_refuelIfNecessaryHelper(self)
    if self.getFuelLevelFunc() > 100 * (self.maxX + self.maxY + self.maxZ) then return end
    self.selectFunc(1)
    self.suckDownFunc()
    self.refuelFunc()
    Turtle_refuelIfNecessaryHelper(self)
end
