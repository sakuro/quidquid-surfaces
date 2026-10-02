# Quidquid: Surfaces

[![Downloads](https://img.shields.io/badge/dynamic/json.svg?label=Downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Fquidquid-surfaces&query=%24.downloads_count)](https://mods.factorio.com/mod/quidquid-surfaces)

Adds planet and space-platform search to the
[Quidquid](https://mods.factorio.com/mod/quidquid) palette. It moved out of
Quidquid in 0.11.0.

By default, planets and space platforms appear in the palette's search along
with everything else. Type `s ` or `surface ` to restrict the search to them.
Turning off "Include surfaces in the default search" leaves them to the
restricted search only.

Search for planets and space platforms available to your force. A platform
owned by another force is listed with that force's name.

Planets your force has not unlocked yet are listed too: remote view says they
are not unlocked, and Factoriopedia still opens them. Quidquid's "Include
hidden entries" setting does not affect this. It only covers planets and
platforms that the game or a mod marks as hidden, and no base-game or Space
Age planet is.

| Key | Action |
| --- | --- |
| Left click | Open in remote view |
| `Alt` + left click | Open in Factoriopedia |

Remote view opens at the position you last occupied on that surface, whether in
person or in remote view. Without such a position it opens at the space
platform's hub, or at your force's spawn position on a planet.

Remote view also needs the planet to be unlocked by your force and its surface
to be generated; Quidquid: Surfaces says which of the two is missing.
Factoriopedia works for a locked or ungenerated planet either way.

Space platforms are listed when owned by your force or when their owner
considers your force a friend. An icon written into a platform's name, such
as `[item=space-science-pack]`, is searchable by what it shows
(`space-science-pack`) but never highlighted. Space locations such as Solar
System Edge are not surfaces and are not included.

Surfaces that a mod creates by script, with no planet prototype behind them,
are left out too, such as Space Exploration's zones, Subsurface's underground
layers and Factorissimo's factory interiors. A planet added by a mod the Space
Age way is listed like any other planet. See
[issue #4](https://github.com/sakuro/quidquid-surfaces/issues/4).
