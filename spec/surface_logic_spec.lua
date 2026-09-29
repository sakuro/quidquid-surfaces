-- Quidquid's public API cannot load under busted, and this spec tests the extension's
-- own logic, not Quidquid's; Quidquid specs its own matcher and rich-text helpers.
-- See spec/support/quidquid_api.lua for the mock's shape and why it must be required
-- before any lib.* module.
local quidquid_api = require("spec.support.quidquid_api")

local SurfaceLogic = require("lib.surface_logic")

describe("SurfaceLogic", function()
  before_each(function()
    quidquid_api.reset()
  end)

  local function planet(overrides)
    local value = {
      kind = "planet",
      id = "nauvis",
      name = "nauvis",
      label = { "space-location-name.nauvis" },
      icon = "space-location/nauvis",
      unlocked = true,
      hidden = false,
      search_name = "ナウヴィス",
    }
    for key, entry in pairs(overrides or {}) do
      value[key] = entry
    end
    return value
  end

  -- (...) truncates remote_view_availability's (ok, reason) pair to just ok, for
  -- specs below that only care about the boolean and already have their own
  -- coverage of the specific reason (see the two "...not-visited"/"...not-unlocked"
  -- cases further down).
  local function can_open(descriptor, include_hidden)
    return (SurfaceLogic.remote_view_availability(descriptor, include_hidden))
  end

  local function platform(overrides)
    local value = {
      kind = "platform",
      id = "platform-1",
      name = "platform-1",
      label = "Cargo Express",
      search_name = "Cargo Express",
      icon = "surface/space-platform",
      own = true,
      friendly = false,
      hidden = false,
      force_name = "Blue Team",
    }
    for key, entry in pairs(overrides or {}) do
      value[key] = entry
    end
    return value
  end

  it("shows locked planets but prevents opening them in remote view", function()
    for _, include_hidden in ipairs({ false, true }) do
      assert.is_true(SurfaceLogic.is_visible(planet({ unlocked = false }), include_hidden))
      assert.are.equal(1, #SurfaceLogic.build_candidates("nauv", { planet({ unlocked = false }) }, include_hidden))
      assert.is_false(can_open(planet({ unlocked = false }), include_hidden))
      assert.is_true(can_open(planet(), include_hidden))
    end
  end)

  it("requires ownership or friendship independently of the hidden setting", function()
    for _, include_hidden in ipairs({ false, true }) do
      assert.is_false(SurfaceLogic.is_visible(platform({ own = false }), include_hidden))
      assert.is_true(SurfaceLogic.is_visible(platform(), include_hidden))
      assert.is_true(SurfaceLogic.is_visible(platform({ own = false, friendly = true }), include_hidden))
    end
  end)

  it("applies ownership and hidden rules to remote view too", function()
    assert.is_false(can_open(platform({ own = false }), true))
    assert.is_false(can_open(platform({ hidden = true }), false))
    assert.is_true(can_open(platform({ hidden = true }), true))
    assert.is_true(can_open(platform({ own = false, friendly = true }), false))
    assert.is_false(can_open(planet({ hidden = true }), false))
    assert.is_false(can_open(planet({ hidden = true, unlocked = false }), true))
  end)

  describe(".remote_view_availability", function()
    it("names the not-visited reason for an ungenerated planet", function()
      local ok, reason = SurfaceLogic.remote_view_availability(planet({ generated = false }), false)

      assert.is_false(ok)
      assert.are.equal("quidquid-surfaces.action-open-remote-view-not-visited", reason)
    end)

    it("names the not-unlocked reason for a locked planet", function()
      local ok, reason = SurfaceLogic.remote_view_availability(planet({ unlocked = false }), false)

      assert.is_false(ok)
      assert.are.equal("quidquid-surfaces.action-open-remote-view-not-unlocked", reason)
    end)

    it("gives no reason for a surface that isn't independently visible", function()
      local ok, reason = SurfaceLogic.remote_view_availability(platform({ own = false }), false)

      assert.is_false(ok)
      assert.is_nil(reason)
    end)

    it("gives no reason when remote view is actually available", function()
      local ok, reason = SurfaceLogic.remote_view_availability(planet(), false)

      assert.is_true(ok)
      assert.is_nil(reason)
    end)
  end)

  it("applies the hidden preference only to accessible surfaces", function()
    for _, value in ipairs({
      planet({ hidden = true }),
      platform({ hidden = true }),
      platform({ own = false, friendly = true, hidden = true }),
    }) do
      assert.is_false(SurfaceLogic.is_visible(value, false))
      assert.is_true(SurfaceLogic.is_visible(value, true))
    end
    assert.is_false(SurfaceLogic.is_visible({ kind = "other" }, true))
  end)

  it("matches internal names case insensitively and translated planet names", function()
    assert.are.equal(1, #SurfaceLogic.build_candidates("NAUV", { planet() }, false))
    assert.are.equal(1, #SurfaceLogic.build_candidates("ヴィス", { planet() }, false))
    assert.are.equal(0, #SurfaceLogic.build_candidates("vulcanus", { planet() }, false))
    assert.are.equal(1, #SurfaceLogic.build_candidates("nauv", { planet({ search_name = false }) }, false))
  end)

  it("does not mark a candidate as numeric -- only the calculator source's own results are", function()
    local candidates = SurfaceLogic.build_candidates("nauv", { planet() }, false)

    assert.is_nil(candidates[1].numeric)
  end)

  it("includes an ungenerated planet but does not allow remote view", function()
    local ungenerated = planet({
      id = "vulcanus",
      name = "vulcanus",
      planet_name = "vulcanus",
      search_name = "Vulcanus",
      generated = false,
      unlocked = true,
    })

    local candidates = SurfaceLogic.build_candidates("vulcanus", { ungenerated }, false)

    assert.are.equal("vulcanus", candidates[1].id)
    assert.are.equal("vulcanus", candidates[1].planet_name)
    assert.is_false(can_open(ungenerated, false))
  end)

  it("matches platform display names and annotates only foreign ownership", function()
    local own = SurfaceLogic.build_candidates("express", { platform() }, false)[1]
    assert.are.equal("Cargo Express", own.label)
    assert.are.equal("Cargo Express", own.search_display_name)
    assert.is_nil(own.search_internal_name)
    local foreign = SurfaceLogic.build_candidates("express", { platform({ own = false, friendly = true }) }, false)[1]
    assert.are.same({ "quidquid-surfaces.surface-with-force", "Cargo Express", "Blue Team" }, foreign.label)
  end)

  it("finds a platform named with tags only", function()
    -- Under the mock, this matches the tag text verbatim rather than through real tag
    -- extraction; it still proves SurfaceLogic passes an all-tag name through the
    -- matching pipeline instead of skipping it.
    local candidates = SurfaceLogic.build_candidates("science", {
      platform({ search_name = "[item=space-science-pack][virtual-signal=signal-1]" }),
    }, false)

    assert.are.equal(1, #candidates)
  end)

  it("highlights platform name text around a rich-text tag, mapped back through rich_text", function()
    local rich_name = "[item=iron-plate] Cargo Express"

    local candidates = SurfaceLogic.build_candidates("express", { platform({ search_name = rich_name }) }, false)
    local ranges = candidates[1].search_display_ranges

    assert.are.equal(rich_name, candidates[1].search_display_name)
    assert.is_true(#ranges > 0)
    for _, range in ipairs(ranges) do
      assert.is_true(range.mapped)
    end
  end)

  it("returns highlighted display-name ranges, mapped through rich_text", function()
    local candidates = SurfaceLogic.build_candidates("express", { platform() }, false)
    local ranges = candidates[1].search_display_ranges

    assert.is_true(#ranges > 0)
    for _, range in ipairs(ranges) do
      assert.is_true(range.mapped)
    end
    assert.are.same({}, candidates[1].search_internal_ranges)
  end)

  it("does not route a planet's display name through rich_text -- only platforms are", function()
    local candidates = SurfaceLogic.build_candidates("ヴィス", { planet() }, false)
    local ranges = candidates[1].search_display_ranges

    assert.is_true(#ranges > 0)
    for _, range in ipairs(ranges) do
      assert.is_nil(range.mapped)
    end
    assert.are.same({}, quidquid_api.calls.searchable)
  end)

  it("does not match a platform by its surface name", function()
    local candidates = SurfaceLogic.build_candidates("platform-1", { platform() }, false)
    assert.are.same({}, candidates)
  end)

  it("returns no candidates for an empty query", function()
    local candidates =
      SurfaceLogic.build_candidates("", { platform({ id = "platform-9" }), planet(), platform() }, false)
    assert.are.same({}, candidates)
  end)

  it("keeps same-name platforms distinct and orders by id", function()
    local candidates = SurfaceLogic.build_candidates("a", {
      platform({ id = "platform-9" }),
      planet({ name = "a", search_name = "a" }),
      platform(),
    }, false)
    assert.are.equal(3, #candidates)
    assert.are.same({ "nauvis", "platform-1", "platform-9" }, { candidates[1].id, candidates[2].id, candidates[3].id })
    assert.are.equal("surface", candidates[1].type)
    assert.are.equal("space-location/nauvis", candidates[1].icon)
    assert.are.equal("surface/space-platform", candidates[2].icon)
  end)
end)
