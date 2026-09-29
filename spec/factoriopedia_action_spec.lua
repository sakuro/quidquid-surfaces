-- lib.factoriopedia_action requires __quidquid__.lib.api at load, even though these
-- tests only call .resolve_prototype and never reach api.run_action; the shared mock
-- covers it. See spec/support/quidquid_api.lua for why it must be required before any
-- lib.* module.
require("spec.support.quidquid_api")

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
