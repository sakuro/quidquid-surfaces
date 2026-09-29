local function action(name, fields)
  fields.contract_version = 4
  fields.types = { "surface" }
  return { type = "mod-data", name = "quidquid-surfaces-" .. name, data_type = "quidquid.action", data = fields }
end

-- Both reuse Quidquid's shared inputs and wording (EXTENDING.md "Shared inputs"), so
-- the player has one binding for each whatever the candidate type.
data:extend({
  action("remote-view", {
    label = { "quidquid.action-open-remote-view" },
    hint = { "quidquid.action-open-remote-view-hint" },
    input_name = "quidquid-open-remote-view",
    interface = "quidquid-surfaces.remote-view",
  }),
  action("factoriopedia", {
    label = { "quidquid.action-open-factoriopedia" },
    hint = { "quidquid.action-open-factoriopedia-hint" },
    input_name = "quidquid-open-factoriopedia",
    interface = "quidquid-surfaces.factoriopedia",
  }),
})
