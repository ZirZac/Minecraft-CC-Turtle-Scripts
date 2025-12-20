-- floor.lua  (CraftOS 1.8 / CC:Tweaked)
-- Gebruik: floor <L> <W> [left|right]
-- Turtle start in een hoek, kijkt langs de LENGTE (L). Vloer wordt 1 laag onder de turtle geplaatst.

local a = {...}
if #a < 2 then
  print("Gebruik: floor L W [left|right]")
  return
end

local L = tonumber(a[1])
local W = tonumber(a[2])
local side = (a[3] or "right"):lower()
local sideRight = (side == "right" or side == "r")

if not L or not W or L < 1 or W < 1 then
  print("Geef L en W als positieve getallen.")
  return
end

print("floor L="..L.." W="..W.." dir="..(sideRight and "right" or "left"))

-- ---------------- helpers ----------------

local function isFuelSlot(slot)
  local cur = turtle.getSelectedSlot()
  turtle.select(slot)
  local ok = turtle.refuel(0)
  turtle.select(cur)
  return ok
end

local function refuelIfNeeded()
  local f = turtle.getFuelLevel()
  if f == "unlimited" then return true end
  if f > 0 then return true end

  while turtle.getFuelLevel() == 0 do
    local fueled = false
    for s=1,16 do
      turtle.select(s)
      if turtle.refuel(0) then
        turtle.refuel(64)
        fueled = turtle.getFuelLevel() > 0
        if fueled then break end
      end
    end
    if turtle.getFuelLevel() == 0 then
      print("Fuel op. Vul inventory (met fuel) en druk Enter.")
      read()
    end
  end
  return true
end

local function selectBlockSlot()
  -- liever geen fuel gebruiken als bouwblok
  for s=1,16 do
    if turtle.getItemCount(s) > 0 and not isFuelSlot(s) then
      turtle.select(s)
      return true
    end
  end
  -- als er echt niks anders is: desnoods fuel als bouwblok
  for s=1,16 do
    if turtle.getItemCount(s) > 0 then
      turtle.select(s)
      return true
    end
  end
  return false
end

local function ensureBlocks()
  while not selectBlockSlot() do
    print("Blokken op. Vul inventory (geen fuel nodig) en druk Enter.")
    read()
  end
end

local function safeForward()
  refuelIfNeeded()
  while not turtle.forward() do
    if turtle.detect() then turtle.dig() end
    turtle.attack()
    sleep(0.05)
  end
end

local function placeDownIfNeeded()
  -- Breek planten/rommel onder de turtle als het kan, anders laat het staan.
  if not turtle.detectDown() then
    ensureBlocks()
    while not turtle.placeDown() do
      if turtle.detectDown() then
        turtle.digDown()
      else
        -- geen plek? probeer andere blokslot
        ensureBlocks()
      end
      sleep(0.05)
      if turtle.detectDown() then break end
    end
  end
end

local function rowTurn(row)
  -- Slangenpatroon, met instelbare breedte-kant
  local odd = (row % 2 == 1)
  if sideRight then
    if odd then
      turtle.turnRight()
      safeForward()
      turtle.turnRight()
    else
      turtle.turnLeft()
      safeForward()
      turtle.turnLeft()
    end
  else
    if odd then
      turtle.turnLeft()
      safeForward()
      turtle.turnLeft()
    else
      turtle.turnRight()
      safeForward()
      turtle.turnRight()
    end
  end
end

-- ---------------- main ----------------

-- start-cel ook vullen
placeDownIfNeeded()

for row=1,W do
  for col=1,L-1 do
    safeForward()
    placeDownIfNeeded()
  end
  if row < W then
    rowTurn(row)
    placeDownIfNeeded()
  end
end

print("Klaar.")
