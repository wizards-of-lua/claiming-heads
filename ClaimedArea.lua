-- claiming-heads/ClaimedArea.lua

declare('ClaimedArea')

function ClaimedArea:isValid()
  return true
end

function ClaimedArea:mayBuild(player)
  return false
end

function ClaimedArea:getChunks()
  return {}
end

function ClaimedArea:contains(pos)
  return false
end

function ClaimedArea:isOverlapping(claimedSquare)
  return false
end

declare('ClaimedSquare', ClaimedArea)

function ClaimedSquare.new(pos, width, ownerId)
  local result = {
    ownerId = ownerId,
    pos = pos:floor(),
    width = width
  }
  setmetatable(result, ClaimedSquare)
  return result
end

function ClaimedSquare:mayBuild(player)
  if type(player)=="Player" then
    return self.ownerId == player.uuid
  elseif type(player)=="string" then
    return self.ownerId == player
  end
  error("Expected argument to be a player or a string, but was %s",type(player))
end

function ClaimedSquare:getChunks()
  local pos = self.pos
  local width = self.width
  local minChunkX = (pos.x - width) // 16
  local maxChunkX = (pos.x + width) // 16
  local minChunkZ = (pos.z - width) // 16
  local maxChunkZ = (pos.z + width) // 16
  local result = {}
  for chunkX=minChunkX,maxChunkX,1 do
    for chunkZ=minChunkZ,maxChunkZ,1 do
      table.insert(result, chunkX..'/'..chunkZ)
    end
  end
  return result
end

function ClaimedSquare:contains(pos)
  local sPos = self.pos
  local width = self.width
  return sPos.x - width <= pos.x
     and sPos.z - width <= pos.z
     and sPos.x + width + 1 > pos.x
     and sPos.z + width + 1 > pos.z
end

function ClaimedSquare:isOverlapping(claimedSquare)
  local sPos = self.pos
  local sWidth = self.width
  local oPos = claimedSquare.pos
  local oWidth = claimedSquare.width
  return sPos.x - sWidth < oPos.x + oWidth + 1
     and sPos.z - sWidth < oPos.z + oWidth + 1
     and sPos.x + sWidth + 1 > oPos.x - oWidth
     and sPos.z + sWidth + 1 > oPos.z - oWidth
end

declare('HeadClaim', ClaimedSquare)

function HeadClaim.new(pos, width, ownerId)
  local result = ClaimedSquare.new(pos, width, ownerId)
  setmetatable(result, HeadClaim)
  return result
end

function HeadClaim.deserialize(data)
  local x = data[1]
  local y = data[2]
  local z = data[3]
  local pos = Vec3(x, y, z)
  local width = data[4]
  local ownerId = data[5]
  return HeadClaim.new(pos, width, ownerId)
end

function HeadClaim:serialize()
  local pos = self.pos
  return { pos.x, pos.y, pos.z, self.width, self.ownerId }
end

local function isHead(block)
  return block.name == 'skull' and block.nbt and block.nbt.Owner and block.nbt.Owner.Name and block.nbt.Owner.Id
end

function HeadClaim.getHeadOwnerId(block)
  if isHead(block) then
    return block.nbt.Owner.Id
  end
end

function HeadClaim:isValid()
  local block = spell:getBlock(self.pos)
  local result = HeadClaim.getHeadOwnerId(block) == self.ownerId
  return result;
end

function HeadClaim:__tostring()
  return 'claimed area located at '..self.pos.x..' '..self.pos.y..' '..self.pos.z
end
