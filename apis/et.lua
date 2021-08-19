--[[
    Name: Extended Turtle API
    Author: Coaster3000
    Creation Date: 6/30/2021
    Updated Date: 8/4/2021
    Version: 0.2.1

    COPYRIGHT NOTICE
	© C3K 2021, Some Rights Reserved 
	Except where otherwise noted, this work is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0

	You are free:
		* to Share - to copy, distribute and transmit the work in accordance that is stays under non profit distribution
		* to Remix - to adapt the work

	Under the following conditions:
		* Attribution. You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work).
   		* Share Alike. If you alter, transform, or build upon this work, you may distribute the resulting work only under the same, similar or a compatible license.
   		* Non-Profit. You must distribute it in a non-profit way.
   		* For any reuse or distribution, you must make clear to others the license terms of this work. The best way to do this is with a link to this web page.
		* Any of the above conditions can be waived if you get permission from the copyright holder.
		* Nothing in this license impairs or restricts the author's moral rights.
	
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/. 
]]--
if not turtle then
    error("Cannot load api on a non turtle device...")
end

-- -- Install Step since we do not like the settings api the way it is.
-- if not fs.exists('apis/persist.lua') then
--     fs.makeDir("apis")
--     fs.copy("rom/apis/settings.lua", "apis/persist.lua")
-- end
-- local persistFile = ".et_persist"
-- os.loadAPI("apis/persist")

settings.define('et.position', {description = "The vector position of the turtle. [x, y, z]", default = {x = 0, y = 0, z = 0}, type = "table"})
settings.define('et.direction', {description = "The direction of the turtle.", default = 0, type = "number"})

settings.define("et.attempt_limit", {description = "The limit of attempts for certain actions before automatically ending.", default = 500, type = "number"})

local dig_delay = 0.5
local posdirects = {vector.new(1,0,0), vector.new(0,0,1), vector.new(-1,0,0), vector.new(0,0,-1)}
local posUP = vector.new(0,1,0)
local posDOWN = vector.new(0,-1,0)

native = turtle.native or turtle

function _G.assert(condition, msg, level) level = (level or 1) + 1 if not condition then error(msg, level) end return condition end -- Custom assert function. Based of theOriginalBit's assert function link: http://theoriginalbit.net46.net/index.html

local function cust_fmod(num, div)
	local b = math.fmod(num, div)
	if b < 0 then
		b = (div-1) + b
	end
	return b
end
-- Directional vectors for each dir value 0 - 3

local attemptLimit = settings.get('et.attempt_limit')
local pos = vector.new(unpack(settings.get('et.position')))
local dir = settings.get('et.direction')

function saveData() 
	settings.set('et.position', pos)
	settings.set('et.direction', dir)

	settings.set('et.attempt_limit', attemptLimit)

	-- settings.save(persistFile)
	settings.save()
end

function loadData()
	settings.load()
	-- settings.load(persistFile)

	local v = settings.get("et.position")
	local v = {v.x, v.y, v.z}

	pos = vector.new(unpack(v))
	dir = settings.get('et.direction')
	attemptLimit = settings.get('et.attempt_limit')
end

loadData()


function dump()
	printError("Memory Dump Of Data...")
	printError("Position: ".. pos:tostring())
	printError("Direction: "..dir)
	printError("Fuel: "..getFuelLevel())
	printError("End of Memory Dump")
end

-- direction = 1 for forward and direction = -1 for back
local function incPos(direction)
    assert(direction == 1 or direction == -1)
    local b = cust_fmod(dir, 4)
	if (direction < 0) then
		b = cust_fmod(b + 2, 4)
	end
    if b >= 0 and b <= 3 then
		pos = pos:add(posdirects[b+1])
    else
        printError("ET Api had a critical error...")
        dump()
        error("",0)
    end

	saveData()
end

function getLimit()
	return attemptLimit
end

function setLimit(num)
	attemptLimit = num or attemptLimit
	settings.set("attempt_limit", attemptLimit)
	settings.save(persistFile)
end

function getPosition()
	return pos
end

function getDirection()
	return dir
end

function setDirection(num)
	dir = cust_fmod((num or dir), 4)
	settings.set('direction', dir)
end

function setPosition(x, y, z)
	if type(x) == "table" then
		assert(type(x.x) == "number" and type(x.y) == "number" and type(x.z) == "number", "Not valid arguments for setPosition. Either X, Y, Z are accepted, or a vector!", 2)
		setPosition(x.x, x.y, x.z)
	elseif type(x) == "nil" then
		setPosition(gps.locate())
	else
		pos = vector.new(x, y, z)
	end
end

function refuel(amount, searchFuel)
	local retslot = getSelectedSlot()
	local sf = searchFuel or false
	if sf then
		if amount > getFuelLevel() then
			for i=1,16 do
				if getFuelLevel() > amount then return true end
				if isFuel(i) then
					select(i)
					refuel(1)
				end
			end
			select(retslot)
		end
	else
		return native.refuel(amount)
	end
end

function isFuel(_slot)
	local retSlot = getSelectedSlot()
	_slot = _slot or retSlot
	select(_slot)
	local bFuel = refuel(0)
	select(retSlot)
	return bFuel
end

function back(moveCount)
	if not moveCount or moveCount == 1 then
		local good = native.back()
		if good then
			incPos(-1)
		end
		return good
	else 
		local count = 0
		for i=1,moveCount do
			if back() then
				count = count + 1
			end
		end
		local good = count == moveCount
		return good, count
	end
end

function forward(moveCount)
	if not moveCount or moveCount == 1 then
		local good = native.forward()
		if good then
			incPos(1)
		end
		return good
	else
		local count = 0
		for i=1,moveCount do
			if forward() then
				count = count + 1
			end
		end
		local good = count == moveCount
		return good, count
	end
end

function turnRight(turnCount)
	if not turnCount or turnCount == 1 then
		local good = native.turnRight()
		if good then
			setDirection(cust_fmod(dir + 1, 4))
		end
		return good
	else
		local count = 0
		for i=1,turnCount do
			if turnRight() then
				count = count + 1
			end
		end
		local good = count == turnCount
		return good, count
	end
end

function turnLeft(turnCount)
	if not turnCount or turnCount == 1 then
		local good = native.turnLeft()
		if good then
			setDirection(cust_fmod(dir - 1, 4))
		end
		return good
	else
		local count = 0
		for i=1,turnCount do
			if turnLeft() then
				count = count + 1
			end
		end
		local good = count == turnCount
		return good, count
	end
end

function strafeLeft(moveCount, _refuel)
	if type(moveCount) == "nil" then moveCount = 1 end
	local doRefuel = _refuel or false
	if doRefuel then assert(refuel(moveCount, true), "Do not have enough fuel for refuel to strafe left "..moveCount.." blocks...", 2) end
	assert(getFuelLevel() >= moveCount, "Not enough fuel to strafe left "..moveCount.." blocks... ", 2)
	turnLeft()
	forward(moveCount)
	turnRight()
end

function strafeRight(moveCount, _refuel)
	if type(moveCount) == "nil" then moveCount = 1 end
	local doRefuel = _refuel or false
	if doRefuel then assert(refuel(moveCount, true), "Do not have enough fuel for refuel to strafe right "..moveCount.." blocks...", 2) end
	assert(getFuelLevel() >= moveCount, "Not enough fuel to strafe right "..moveCount.." blocks... ", 2)
	turnRight()
	forward(moveCount)
	turnLeft()
end

function dig(clearBlock)
	if not clearBlock then
		return native.dig()
	else
		local count = 0
		while native.dig() do
			count = count + 1
			sleep(dig_delay)
			if count > attemptLimit then
				return false, count
			end
		end
		if count == 0 then
			return false, count
		else
			return true, count
		end
	end
end

function digDown(clearBlock)
	if not clearBlock then
		return native.digDown()
	else
		local count = 0
		while native.digDown() do
			count = count + 1
			sleep(dig_delay)
			if count > attemptLimit then
				return false, count
			end
		end
		if count == 0 then
			return false, count
		else
			return true, count
		end
	end
end

function digUp(clearBlock)
	if not clearBlock then
		return native.digUp()
	else
		local count = 0
		while native.digUp() do
			count = count + 1
			sleep(dig_delay)
			if count > attemptLimit then
				return false, count
			end
		end
		if count == 0 then
			return false, count
		else
			return true, count
		end
	end
end

function up(moveCount)
	if not moveCount or moveCount == 1 then
		local good = native.up()
		if good then
			pos = pos + posUP
		end
		return good
	else
		local count = 0
		for i=1,moveCount do
			if up() then
				count = count + 1
			end
		end
		local good = count == moveCount
		return good, count
	end
end

function down(moveCount)
	if not moveCount or moveCount == 1 then
		local good = native.down()
		if good then
			pos = pos + posDOWN
		end
		return good
	else
		local count = 0
		for i=1,moveCount do
			if down() then
				count = count + 1
			end
		end
		local good = count == moveCount
		return good, count
	end
end

local env = _ENV
for k,v in pairs(turtle) do
	if type(env[k]) == 'nil' then
		env[k] = v
	elseif k == "select" then -- Forgot select was in the environment already? Where though?
		env[k] = v
	end
end

