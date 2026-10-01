-- Shared mock of __quidquid__.lib.api, installed once into package.preload.
--
-- lib.surface_logic and lib.factoriopedia_action are each `require`d once and cached
-- by Lua, so under `busted --no-auto-insulate` (no per-file package.loaded reset)
-- whichever mock installed first stays loaded for every spec file after it. Before
-- this module existed, spec/factoriopedia_action_spec.lua and
-- spec/surface_logic_spec.lua each installed their own, different mock, and the
-- second file to run saw lib.surface_logic still bound to the first file's mock,
-- which failed with "attempt to call method 'match' (a nil value)" when its matcher
-- shape didn't match.
--
-- The mock matcher matches by plain case-insensitive substring and returns ranges
-- only for the field that won. quidquid-resources' spec/resource_logic_spec.lua
-- makes the same simplification, mirroring the real Matcher:match, which never hands
-- back ranges for the loser. rich_text.searchable is a pass-through, as quidquid-
-- blueprints' spec/blueprint_logic_spec.lua uses: it does not strip tags or produce
-- per-character ranges the way the real module does, so a range it returns only
-- proves the caller routed the name through it, not the exact highlighted bytes.
-- map_ranges marks every range it produces with `mapped = true`, the marker specs
-- use to tell whether a name went through it.

local calls = {
  searchable = {},
  map_ranges = {},
}

--- Clears recorded rich_text calls between examples.
local function reset()
  calls.searchable = {}
  calls.map_ranges = {}
end

local function install()
  local Matcher = {}
  Matcher.__index = Matcher

  local function ranges_of(query, value)
    if type(value) ~= "string" or query == "" then
      return nil
    end
    local start_byte, end_byte = value:lower():find(query:lower(), 1, true)
    if start_byte == nil then
      return nil
    end
    return { { start_byte = start_byte, end_byte = end_byte } }
  end

  function Matcher:match(_namespace, _id, fields)
    local display = ranges_of(self.query, fields.display)
    local internal = ranges_of(self.query, fields.internal)
    if display == nil and internal == nil then
      return nil
    end
    if display ~= nil then
      return { score = 1, display_ranges = display, internal_ranges = {} }
    end
    return { score = 1, display_ranges = {}, internal_ranges = internal }
  end

  package.preload["__quidquid__.lib.api"] = function()
    return {
      matcher = function(query)
        return setmetatable({ query = query }, Matcher)
      end,
      rich_text = {
        searchable = function(value)
          table.insert(calls.searchable, value)
          local origins = {}
          for i = 1, #value do
            origins[i] = i
          end
          return value, origins
        end,
        map_ranges = function(ranges, _origins)
          table.insert(calls.map_ranges, ranges)
          local mapped = {}
          for _, range in ipairs(ranges or {}) do
            table.insert(mapped, { start_byte = range.start_byte, end_byte = range.end_byte, mapped = true })
          end
          return mapped
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
end

if package.preload["__quidquid__.lib.api"] == nil then
  install()
end

return {
  calls = calls,
  reset = reset,
}
