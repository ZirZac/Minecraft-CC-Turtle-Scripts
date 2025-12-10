local args = {...}
if #args < 3 then
  print("Gebruik: miner L W D [richting]")
  return
end

local L = tonumber(args[1])
local W = tonumber(args[2])
local D = tonumber(args[3])
if not L or not W or not D or L < 1 or W < 1 or D < 1 then
  print("L, W en D moeten positieve getallen zijn.")
  return
end

local dirArg = (args[4] or "right"):lower()
local sideRight = (dirArg == "right" or dirArg == "r")

print("Mine "..L.." x "..W.." blokken, "..D.." lagen diep, breedte naar "..(sideRight and "RIGHT" or "LEFT"))

-- richting: 0 = +X (vooruit), 1 = +Z (rechts), 2 = -X, 3 = -Z
local dir = 0
local x, z = 0, 0

local function refuel()
  local f = turtle.getFuelLevel()
  if f == "unlimited" or f > 0 then return end
  while turtle.getFuelLevel() == 0 do
    for slot = 1, 16 do
      turtle.select(slot)
      if turtle.refuel(0) then
        turtle.refuel(64)
        if turtle.getFuelLevel() > 0 then break end
      end
    end
    if turtle.getFuelLevel() == 0 then
      print("GEEN FUEL. Voeg fuel toe en druk Enter.")
      read()
    end
  end
end

local function turnRight()
  turtle.turnRight()
  dir = (dir + 1) % 4
end

local function turnLeft()
  turtle.turnLeft()
  dir = (dir + 3) % 4
end

local function face(d)
  while dir ~= d do turnRight() end
end

local function stepForward()
  refuel()
  while not turtle.forward() do
    if turtle.detect() then turtle.dig() end
    turtle.attack()
  end
  if dir == 0 then
    x = x + 1
  elseif dir == 2 then
    x = x - 1
  elseif dir == 1 then
    z = z + 1
  else
    z = z - 1
  end
end

local function mineForward()
  while turtle.detect() do
    turtle.dig()
    sleep(0.05)
  end
  stepForward()
end

local function goTo(tx, tz)
  if tx > x then
    face(0)
    while x < tx do mineForward() end
  elseif tx < x then
    face(2)
    while x > tx do mineForward() end
  end
  if tz > z then
    face(1)
    while z < tz do mineForward() end
  elseif tz < z then
    face(3)
    while z > tz do mineForward() end
  end
end

local function downSafe()
  refuel()
  while not turtle.down() do
    if turtle.detectDown() then turtle.digDown() end
    turtle.attackDown()
  end
end

local function stepSide(forwardPos)
  -- forwardPos = true als we nu +X kant op gaan
  local sideStep
  if sideRight then
    sideStep = forwardPos and 1 or -1
  else
    sideStep = forwardPos and -1 or 1
  end
  if sideStep == 1 then
    face(1)  -- +Z
  else
    face(3)  -- -Z
  end
  mineForward()
end

print("Start mining...")

for layer = 1, D do
  print("Laag "..layer.." / "..D)
  face(0) -- altijd beginnen kijkend +X
  local forwardPos = true -- eerste rij richting +X

  for row = 1, W do
    if forwardPos then face(0) else face(2) end
    for i = 1, L - 1 do mineForward() end
    if row < W then
      stepSide(forwardPos)
      forwardPos = not forwardPos
    end
  end

  -- terug naar (0,0) boven op deze laag
  goTo(0, 0)
  face(0)

  if layer < D then
    if turtle.detectDown() then turtle.digDown() end
    downSafe()
  end
end

print("Klaar met minen.")
