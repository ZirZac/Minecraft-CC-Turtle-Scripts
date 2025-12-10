-- miner.lua
-- Gebruik: miner L W D
-- Turtle staat in een hoek, kijkt langs de LENGTE-richting

local tArgs = {...}
if #tArgs < 3 then
  print("Gebruik: miner L W D")
  return
end

local L = tonumber(tArgs[1])
local W = tonumber(tArgs[2])
local D = tonumber(tArgs[3])

if not L or not W or not D or L < 1 or W < 1 or D < 1 then
  print("L, W en D moeten positieve getallen zijn.")
  return
end

local function refuel()
  local fuel = turtle.getFuelLevel()
  if fuel == "unlimited" or fuel > 0 then
    return
  end
  print("Geen fuel, proberen te refuelen...")
  while turtle.getFuelLevel() == 0 do
    for slot = 1, 16 do
      turtle.select(slot)
      if turtle.refuel(0) then
        turtle.refuel(64)
        if turtle.getFuelLevel() > 0 then
          break
        end
      end
    end
    if turtle.getFuelLevel() == 0 then
      print("Stop fuel in de turtle en druk Enter.")
      read()
    end
  end
end

local function safeForward()
  refuel()
  while not turtle.forward() do
    if turtle.detect() then
      turtle.dig()
    end
    turtle.attack()
  end
end

local function safeDown()
  refuel()
  while not turtle.down() do
    if turtle.detectDown() then
      turtle.digDown()
    end
    turtle.attackDown()
  end
end

local function mineForward()
  while turtle.detect() do
    turtle.dig()
    sleep(0.1)
  end
  safeForward()
end

local function nextRow(row)
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

local function returnToLayerStart()
  -- We staan nu in de ZUID-rand van het gebied
  -- Bij oneven W staan we aan de andere L-kant
  if W % 2 == 1 then
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, L - 1 do
      safeForward()
    end
  end
  turtle.turnRight()
  for i = 1, W - 1 do
    safeForward()
  end
  turtle.turnRight()
end

print("Miner start: L="..L.." W="..W.." D="..D)

for d = 1, D do
  print("Laag "..d.." / "..D)
  for w = 1, W do
    for l = 1, L - 1 do
      mineForward()
    end
    if w < W then
      nextRow(w)
    end
  end

  returnToLayerStart()

  if d < D then
    if turtle.detectDown() then
      turtle.digDown()
    end
    safeDown()
  end
end

print("Klaar.")

