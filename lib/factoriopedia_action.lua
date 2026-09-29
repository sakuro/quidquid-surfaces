local api = require("__quidquid__.lib.api")
local SurfaceAccess = require("lib.surface_access")

local FactoriopediaAction = {}

-- Dispatches on the LuaSurface's own kind rather than SurfaceAccess's descriptor,
-- which is only carried for the ungenerated-planet fallback.
local function surface_prototype(surface)
  if surface.platform ~= nil then
    return prototypes.surface["space-platform"]
  elseif surface.planet ~= nil then
    return surface.planet.prototype
  end
  return nil
end

--- The prototype whose Factoriopedia page a surface candidate should open.
---
--- A generated surface resolves through its LuaSurface, while an ungenerated planet
--- has only its prototype to offer.
---@param candidate table
---@param player LuaPlayer
---@return LuaPrototypeBase|nil  nil when the candidate no longer resolves
function FactoriopediaAction.resolve_prototype(candidate, player)
  local surface = SurfaceAccess.resolve(candidate, player)
  if surface ~= nil then
    return surface_prototype(surface)
  end
  return SurfaceAccess.planet_prototype(candidate)
end

local function resolve(candidate, player)
  local prototype = FactoriopediaAction.resolve_prototype(candidate, player)
  if prototype == nil then
    return nil, "quidquid-surfaces.action-open-factoriopedia-unavailable"
  end
  return prototype, nil
end

local function execute(candidate, player_index)
  return api.run_action(candidate, player_index, resolve, function(prototype, _candidate, player)
    player.open_factoriopedia_gui(prototype)
  end)
end

--- Adds the interface that prototypes/actions.lua names.
function FactoriopediaAction.add_interface()
  remote.add_interface("quidquid-surfaces.factoriopedia", { execute = execute })
end

return FactoriopediaAction
