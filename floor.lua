-- floor.lua
-- Gebruik: floor <L> <W> [right|left]
-- Turtle start in een hoek op vloerniveau (de vloer komt ONDER de turtle).
-- Turtle kijkt langs de LENGTE (L). Breedte (W) loopt naar rechts of links.

local a={...}
if #a<2 then print("Gebruik: floor <L> <W> [right|left]") return end
local L=tonumber(a[1]); local W=tonumber(a[2])
local side=(a[3] or "right"):lower()
local right = (side=="right" or side=="r")
if not L or not W or L<1 or W<1 then print("L/W moeten positieve getallen zijn.") return end

-- slots die fuel bevatten (worden niet gebruikt om te bouwen)
local fuelSlot={}
for i=1,16 do
  turtle.select(i)
  if turtle.refuel(0) then fuelSlot[i]=true end
end

local function refuelIfNeeded()
  local f=turtle.getFuelLevel()
  if f=="unlimited" or f>0 then return end
  while turtle.getFuelLevel()==0 do
    for i=1,16 do
      if fuelSlot[i] then
        turtle.select(i)
        turtle.refuel(1)
        if turtle.getFuelLevel()>0 then return end
      end
    end
    print("Geen fuel. Voeg fuel toe en druk Enter.")
    read()
    -- her-scan fuel slots (misschien heb je nieuw fuel toegevoegd)
    fuelSlot={}
    for i=1,16 do
      turtle.select(i)
      if turtle.refuel(0) then fuelSlot[i]=true end
    end
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

local function selectBuildSlot()
  for i=1,16 do
    if not fuelSlot[i] and turtle.getItemCount(i)>0 then
      turtle.select(i)
      return true
    end
  end
  return false
end

local function ensureBlocks()
  while not selectBuildSlot() do
    print("Blokken op. Vul inventory (geen fuel) en druk Enter.")
    read()
    -- fuel slots opnieuw bepalen (voor het geval je per ongeluk fuel toevoegt/verplaatst)
    fuelSlot={}
    for i=1,16 do
      turtle.select(i)
      if turtle.refuel(0) then fuelSlot[i]=true end
    end
  end
end

local function placeFloor()
  -- haal flowers/gras/etc weg en plaats 1 blok als vloer
  if turtle.detectDown() then turtle.digDown() end
  ensureBlocks()
  turtle.placeDown()
end

local function stepToNextRow(row)
  if right then
    if row%2==1 then
      turtle.turnRight(); safeForward(); turtle.turnRight()
    else
      turtle.turnLeft();  safeForward(); turtle.turnLeft()
    end
  else
    if row%2==1 then
      turtle.turnLeft();  safeForward(); turtle.turnLeft()
    else
      turtle.turnRight(); safeForward(); turtle.turnRight()
    end
  end
end

local function returnToStart()
  -- terug naar start van deze laag/plane: zelfde logica als flatten
  if W%2==1 then
    turtle.turnLeft(); turtle.turnLeft()
    for i=1,L-1 do safeForward() end
  end
  turtle.turnRight()
  for i=1,W-1 do safeForward() end
  turtle.turnRight()
end

print("floor L="..L.." W="..W.." dir="..(right and "right" or "left"))

for row=1,W do
  for col=1,L do
    placeFloor()
    if col<L then safeForward() end
  end
  if row<W then stepToNextRow(row) end
end

returnToStart()
print("Klaar.")
