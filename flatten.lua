local args = {...}
if #args < 3 then
  print("Gebruik: flatten L W D [mode]")
  print("mode: mine, fill, both (default: both)")
  return
end

local L = tonumber(args[1])
local W = tonumber(args[2])
local D = tonumber(args[3])
local modeArg = (args[4] or "both"):lower()

if not L or not W or not D or L < 1 or W < 1 or D < 1 then
  print("Geef 3 positieve getallen voor L, W en D.")
  return
end

local doMine = (modeArg == "mine" or modeArg == "both")
local doFill = (modeArg == "fill" or modeArg == "both")

if not doMine and not doFill then
  print("mode moet 'mine', 'fill' of 'both' zijn.")
  return
end

local function refuel()
  local f = turtle.getFuelLevel()
  if f == "unlimited" or f > 0 then return end
  while turtle.getFuelLevel() == 0 do
    for s = 1, 16 do
      turtle.select(s)
      if turtle.refuel(0) then
        turtle.refuel(64)
        if turtle.getFuelLevel() > 0 then break end
      end
    end
    if turtle.getFuelLevel() == 0 then
      print("Geen fuel, voeg brandstof toe en druk Enter.")
      read()
    end
  end
end

local function inventoryFull()
  for s = 1, 16 do
    if turtle.getItemCount(s) == 0 then
      return false
    end
  end
  return true
end

local function isFuelSlot(slot)
  turtle.select(slot)
  return turtle.refuel(0)
end

local function dumpNonFuel()
  for s = 1, 16 do
    turtle.select(s)
    if turtle.getItemCount(s) > 0 and not isFuelSlot(s) then
      turtle.drop()
    end
  end
end

local function safeForward()
  while true do
    refuel()
    if turtle.forward() then
      return
    end
    if turtle.detect() then
      turtle.dig()
    end
    turtle.attack()
  end
end

local function safeDown()
  while true do
    refuel()
    if turtle.down() then
      return
    end
    if turtle.detectDown() then
      turtle.digDown()
    end
    turtle.attackDown()
  end
end

local function safeUp()
  while true do
    refuel()
    if turtle.up() then
      return
    end
    if turtle.detectUp() then
      turtle.digUp()
    end
    turtle.attackUp()
  end
end

local function mineForward()
  while turtle.detect() do
    turtle.dig()
    sleep(0.05)
  end
  safeForward()
  if inventoryFull() then
    dumpNonFuel()
  end
end

local function stepToNextRow(row)
  if row % 2 == 1 then
    turtle.turnRight()
    mineForward()
    turtle.turnRight()
  else
    turtle.turnLeft()
    mineForward()
    turtle.turnLeft()
  end
end

local function backToStart()
  if W % 2 == 1 then
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, L - 1 do
      mineForward()
    end
  end
  turtle.turnRight()
  for i = 1, W - 1 do
    mineForward()
  end
  turtle.turnRight()
end

local function ensureFiller()
  while true do
    for s = 1, 16 do
      turtle.select(s)
      if turtle.getItemCount(s) > 0 and not isFuelSlot(s) then
        return
      end
    end
    print("Geen vulblokken gevonden. Vul inventory (bijv. dirt) en druk Enter.")
    read()
  end
end

local function placeFillerDown()
  ensureFiller()
  for s = 1, 16 do
    turtle.select(s)
    if turtle.getItemCount(s) > 0 and not isFuelSlot(s) then
      if turtle.placeDown() then
        return true
      end
    end
  end
  return false
end

local function removeFlowersDown()
  if turtle.detectDown() then
    local ok, data = turtle.inspectDown()
    if ok and data and data.name then
      local name = data.name
      if string.find(name, "grass") or string.find(name, "fern") or string.find(name, "flower") then
        turtle.digDown()
      end
    end
  end
end

local function fillColumn()
  removeFlowersDown()
  local placed = 0
  while not turtle.detectDown() and placed < D do
    if not placeFillerDown() then
      break
    end
    safeDown()
    placed = placed + 1
  end
  for i = 1, placed do
    safeUp()
  end
end

local function mineArea()
  for d = 1, D do
    print("Laag "..d.."/"..D)
    for w = 1, W do
      for l = 1, L - 1 do
        mineForward()
      end
      if w < W then
        stepToNextRow(w)
      end
    end
    backToStart()
    if d < D then
      if turtle.detectDown() then
        turtle.digDown()
      end
      safeDown()
    end
  end
end

local function fillArea()
  print("Vullen...")
  for w = 1, W do
    for l = 1, L do
      fillColumn()
      if l < L then
        safeForward()
      end
    end
    if w < W then
      if w % 2 == 1 then
        turtle.turnRight()
        safeForward()
        turtle.turnRight()
      else
        turtle.turnLeft()
        safeForward()
        turtle.turnLeft()
      end
    end
  end
  backToStart()
end

print("Flatten "..L.."x"..W.." D="..D.." mode="..modeArg)

if doMine then
  mineArea()
end

if doFill then
  dumpNonFuel()
  ensureFiller()
  fillArea()
end

print("Klaar.")
