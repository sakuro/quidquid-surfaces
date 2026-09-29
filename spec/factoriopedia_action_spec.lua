-- Quidquid's public API cannot load under busted, and lib.factoriopedia_action requires
-- it at load, even though these tests only call .resolve_prototype and never reach
-- api.run_action; a table with the shape the module expects is enough.
package.preload["__quidquid__.lib.api"] = function()
  return {
    matcher = function(query, _locale)
      return { query = query }
    end,
    rich_text = {
      searchable = function(value)
        return value, {}
      end,
      map_ranges = function(_ranges, _origins)
        return {}
      end,
    },
    run_action = function(candidate, player_index, resolve_fn, apply_fn, fallback_locale_key)
      local player = game.get_player(player_index)
      if player == nil then
        return nil
      end
      local payload, locale_key = resolve_fn(candidate, player)
      if payload == nil then
        local key = locale_key or fallback_locale_key
        return key ~= nil and { key } or nil
      end
      return apply_fn(payload, candidate, player)
    end,
  }
end

local FactoriopediaAction = require("lib.factoriopedia_action")
local SurfaceAccess = require("lib.surface_access")

describe("FactoriopediaAction", function()
  local original_resolve = SurfaceAccess.resolve
  local original_planet_prototype = SurfaceAccess.planet_prototype

  after_each(function()
    _G.prototypes = nil
    SurfaceAccess.resolve = original_resolve
    SurfaceAccess.planet_prototype = original_planet_prototype
  end)

  describe(".resolve_prototype", function()
    it("resolves the space-platform prototype for a platform surface", function()
      _G.prototypes = { surface = { ["space-platform"] = "space-platform-prototype" } }
      SurfaceAccess.resolve = function(_candidate, _player)
        return { platform = {} }
      end

      assert.are.equal(
        "space-platform-prototype",
        FactoriopediaAction.resolve_prototype({ type = "surface", id = 1 }, {})
      )
    end)

    it("resolves a generated planet's prototype from the real surface", function()
      SurfaceAccess.resolve = function(_candidate, _player)
        return { planet = { prototype = "nauvis-prototype" } }
      end

      assert.are.equal("nauvis-prototype", FactoriopediaAction.resolve_prototype({ type = "surface", id = 1 }, {}))
    end)

    it("falls back to the planet prototype when the planet has no generated surface yet", function()
      SurfaceAccess.resolve = function(_candidate, _player)
        return nil
      end
      SurfaceAccess.planet_prototype = function(_candidate)
        return "vulcanus-prototype"
      end

      assert.are.equal(
        "vulcanus-prototype",
        FactoriopediaAction.resolve_prototype({ type = "surface", planet_name = "vulcanus" }, {})
      )
    end)

    it("returns nil for an unresolvable surface candidate", function()
      SurfaceAccess.resolve = function(_candidate, _player)
        return nil
      end
      SurfaceAccess.planet_prototype = function(_candidate)
        return nil
      end

      assert.is_nil(FactoriopediaAction.resolve_prototype({ type = "surface", id = 1 }, {}))
    end)
  end)
end)
