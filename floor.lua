-- floor.lua
-- Gebruik: floor <L> <W> [dir]
-- Turtle start op het hoekblok van de vloer. Legt 1-laags vloer onder zich (placeDown).
-- Breekt niets. Plaatst alleen als er geen blok onder zit.
-- dir: right (default) of left = welke kant de breedte op gaat t.o.v. kijkrichting.

local a={...}
if #a<2 then print("Gebruik: floor L W [dir]") return end
local L=tonumber(a[1]); local W=tonumber(a[2])
local dirArg=(a[3] or "right"):lower()
if not L or not W or L<1 or W<1 then print("Geef L en W als positieve getallen.") return end
local sideRight = (dirArg=="right" or dirArg=="r")

-- cache slot voor bouwblokken en fuel
local buildSlot=nil
local fuelSlot=nil

local function findBuildSlot()
  -- Kies eerste slot met blocks (alles met placeDown).
  -- We testen niet elk item met placeDown (dat zou rommelen), we pakken gewoon een slot met count>0
  -- en proberen te plaatsen als nodig.
  for s=1,16 do
    if turtle.getItemCount(s)>0 then
      -- fuelSlot overslaan als die gezet is (we willen coal niet als bouwblok gebruiken)
      if s~=fuelSlot then
        buildSlot=s
        turtle.select(buildSlot)
        return true
      end
    end
  end
  return false
end

local function findFuelSlot()
  for s=1,16 do
    if turtle.getItemCount(s)>0 then
      turtle.select(s)
      if turtle.refuel(0) then
        fuelSlot=s
        return true
      end
    end
  end
  return false
end

local function ensureFuel(need)
  local lvl=turtle.getFuelLevel()
  if lvl=="unlimited" then return true end
  if turtle.getFuelLevel()>=need then return true end

  while turtle.getFuelLevel()<need do
    if not fuelSlot or turtle.getItemCount(fuelSlot)==0 then
      fuelSlot=nil
      if not findFuelSlot() then
        print("Geen fuel gevonden. Vul inventory met fuel en druk Enter.")
        read()
      end
    end
    turtle.select(fuelSlot)
    turtle.refuel(1)
  end
  return true
end

local function ensureBuildSlot()
  if buildSlot and turtle.getItemCount(buildSlot)>0 then
    turtle.select(buildSlot)
    return true
  end
  buildSlot=nil
  if findBuildSlot() then return true end
  print("Geen bouwblokken. Vul inventory met blokken en druk Enter.")
  read()
  return ensureBuildSlot()
end

local function placeDownIfEmpty()
  if turtle.detectDown() then return true end
  ensureBuildSlot()
  while not turtle.placeDown() do
    -- Kan falen door item dat geen block is of door entity; probeer volgende stack
    buildSlot=nil
    if not findBuildSlot() then
      print("Blokken op. Vul inventory met blokken en druk Enter.")
      read()
    end
  end
  return true
end

local function forwardSafe()
  ensureFuel(1)
  while not turtle.forward() do
    -- We breken niets. Alleen wachten/attack voor mobs.
    turtle.attack()
    sleep(0.2)
  end
end

local function turnToSide(step)
  -- step = +1 => naar "rechts" van turtle; step = -1 => naar "links"
  if step==1 then turtle.turnRight() else turtle.turnLeft() end
end

local function turnBackFromSide(step)
  if step==1 then turtle.turnLeft() else turtle.turnRight() end
end

-- minimaal fuel voor run (ruwe schatting): stappen L*W + zijstappen + marge
ensureFuel(L*W + (W-1) + 20)

print(("floor L=%d W=%d dir=%s"):format(L,W,sideRight and "right" or "left"))

for row=1,W do
  for col=1,L do
    placeDownIfEmpty()
    if col<L then forwardSafe() end
  end

  if row<W then
    -- naar volgende rij in slangenpatroon
    local step = 1
    -- Als je breedte naar links wil, spiegel je de side-step op oneven/even rijen
    if sideRight then
      step = (row%2==1) and 1 or -1
    else
      step = (row%2==1) and -1 or 1
    end

    turnToSide(step)
    forwardSafe()
    turnToSide(step)
  end
end

print("Klaar.")
