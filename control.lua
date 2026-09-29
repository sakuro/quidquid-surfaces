local flib_dictionary = require("__flib__.dictionary")
local api = require("__quidquid__.lib.api")
local SurfaceSource = require("lib.surface_source")
local RemoteViewAction = require("lib.remote_view_action")
local FactoriopediaAction = require("lib.factoriopedia_action")

SurfaceSource.add_interface()
RemoteViewAction.add_interface()
FactoriopediaAction.add_interface()

-- flib_dictionary.new/.add may only run before flib's first on_tick, so the dictionary
-- is registered from on_init and on_configuration_changed, which both reset flib's
-- dictionary state first.
script.on_init(function()
  flib_dictionary.on_init()
  SurfaceSource.register_dictionary()
end)
script.on_configuration_changed(function()
  flib_dictionary.on_configuration_changed()
  SurfaceSource.register_dictionary()
end)
script.on_event(defines.events.on_tick, flib_dictionary.on_tick)
script.on_event(defines.events.on_string_translated, flib_dictionary.on_string_translated)
script.on_event(defines.events.on_player_joined_game, flib_dictionary.on_player_joined_game)
script.on_event(defines.events.on_player_locale_changed, flib_dictionary.on_player_locale_changed)

-- Track viewed tile positions for surface navigation; discard references when their
-- player or surface is removed so reused indices cannot inherit old positions.
script.on_event(defines.events.on_player_changed_position, RemoteViewAction.on_player_changed_position)
script.on_event(defines.events.on_player_removed, RemoteViewAction.on_player_removed)

-- The surface search keys are cached by surface name; on_pre_surface_deleted only
-- gives surface_index, so the surface (still valid here) is looked up for its name.
script.on_event(defines.events.on_pre_surface_deleted, function(event)
  RemoteViewAction.on_pre_surface_deleted(event)
  local surface = game.get_surface(event.surface_index)
  if surface ~= nil then
    api.forget("surface", surface.name)
  end
end)
