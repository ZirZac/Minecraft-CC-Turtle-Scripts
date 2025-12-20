-- floor.lua (CraftOS 1.8 / CC:Tweaked compatible)
-- Gebruik: floor <L> <W> [left|right]
-- Turtle staat op een hoekblok (vloerblok ligt al onder hem). Hij legt een 1-laags vloer aan.
-- Hij breekt GEEN blokken onder zich. Hij plaatst alleen als er lucht onder zit.
-- Refuel: ALLEEN coal/charcoal.

local args = { ... }
if #args < 2 then
  print("Gebruik: floor L W [left|right]")
  return
end

local L = tonumber(args[1])
local W = tonumber(args[2])
local dirArg = (args[3] or "right"):lower()
local sideRight = (dirArg == "right" or dirArg == "r")

if not L or not W or L < 1 or W < 1 then
  print("L en W moeten positieve getallen zijn.")
  return
end

print("floor L=" .. L .. " W=" .. W .. " dir=" .. (sideRight and "right" or "left"))

local function isCoalSlot(slot)
  local d = turtle.getItemDetail(slot)
  if not d then return false end
  return d.name == "minecraft:coal" or d.name == "minecraft:charcoal"
end

local function tryRefuelOnce()
  for s = 1, 16 do
    if isCoalSlot(s) then
      turtle.select(s)
      if turtle.refuel(1) then return true end
    end
  end
  return false
end

local function ensureFuel()
  local f = turtle.getFuelLevel()
  if f == "unlimited" then return end
  if f > 0 then return end
  while turtle.getFuelLevel() == 0 do
    if not tryRefuelOnce() then
      print("Geen fuel. Voeg coal/charcoal toe en druk Enter.")
      read()
    end
  end
end

local buildSlot = nil

local function findBuildSlot()
  for s = 1, 16 do
    if turtle.getItemCount(s) > 0 and not isCoalSlot(s) then
      turtle.select(s)
      if turtle.placeDown() then
        -- we hebben net geplaatst; dit willen we NIET hier doen in find
        -- dus breek 'm niet: we gaan dit slot gewoon gebruiken, maar we moeten terugdraaien:
        -- oplossing: placeDown alleen proberen in ensureFloor; hier alleen selecteren.
        -- Daarom: terugplaatsen is fout. Dus: nooit placeDown hier.
      end
    end
  end
  return nil
end

local function selectBuildSlot()
  if buildSlot and turtle.getItemCount(buildSlot) > 0 and not isCoalSlot(buildSlot) then
    turtle.select(buildSlot)
    return true
  end
  for s = 1, 16 do
    if turtle.getItemCount(s) > 0 and not isCoalSlot(s) then
      buildSlot = s
      turtle.select(s)
      return true
    end
  end
  buildSlot = nil
  return false
end

local function ensureBlocks()
  while not selectBuildSlot() do
    print("Geen bouwblokken. Vul inventory met blokken (geen fuel) en druk Enter.")
    read()
  end
end

local function ensureFloor()
  -- Plaats alleen als er lucht onder zit
  if turtle.detectDown() then return true end
  ensureBlocks()
  while not turtle.placeDown() do
    -- Als het niet lukt, kan het zijn dat slot leeg is of block niet placeable hier
    if turtle.getItemCount(turtle.getSelectedSlot()) == 0 then
      buildSlot = nil
    end
    ensureBlocks()
    if turtle.detectDown() then return true end
  end
  return true
end

local function safeForward()
  ensureFuel()
  if turtle.forward() then return true end
  -- niet graven: als iets blokkeert, stop
  print("Geblokkeerd voor turtle. Ruim de weg en druk Enter.")
  read()
  return turtle.forward()
end

local function turnToSide(stepSign)
  -- stepSign: +1 = rechts, -1 = links (relatief)
  if stepSign == 1 then turtle.turnRight() else turtle.turnLeft() end
end

local function moveSide(stepSign)
  turnToSide(stepSign)
  local ok = safeForward()
  if stepSign == 1 then turtle.turnLeft() else turtle.turnRight() end
  return ok
end

-- Bouw patroon: snake
-- Turtle staat op startcel (0,0) waar al een blok onder zit. We vullen ook die cel als er lucht is.
for row = 1, W do
  for col = 1, L do
    ensureFloor()
    if col < L then
      safeForward()
    end
  end

  if row < W then
    local stepSign
    -- snake: elke rij omdraaien
    if sideRight then
      stepSign = (row % 2 == 1) and 1 or -1
    else
      stepSign = (row % 2 == 1) and -1 or 1
    end

    moveSide(stepSign)
    turtle.turnLeft()
    turtle.turnLeft()
  end
end

print("Klaar.")
