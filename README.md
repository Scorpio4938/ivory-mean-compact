# Mean Patch

Ports the Ivory Car Pack siren audio system onto Means Emergency Vehicle Pack vehicles. Supports all 37 Mean vehicle classes.

## Dependencies

- [Means Emergency Vehicle Pack](https://steamcommunity.com/sharedfiles/filedetails/?id=2105316635)
- [Ivory Car Pack](https://steamcommunity.com/sharedfiles/filedetails/?id=108976015)
- [CBA](https://steamcommunity.com/workshop/filedetails/?id=450814997)

## Controls

| Key | Action |
|---|---|
| **R** | Siren on / off |
| **Shift+R** | Next siren tone |
| **T** | Lightbar on / off |
| **F** (hold) | Horn |
| **C** (hold) | Takedown tone |
| **1** – **4** | Direct tone select (Wail, Yelp, Priority, HiLo) |
| **\\** | Read Manual |

## What's Patched

- **Siren audio** — playable through all 4 tones (Wail, Yelp, Priority, HiLo) via `#particlesource` + `say3D`, dual-dummy alternation prevents loop-boundary gaps
- **Horn** — hold-to-play airhorn, cancellable on release
- **Takedown** — hold-to-play priority/wail tone
- **Lightbar toggle** — on/off, kills siren when turned off
- **Keybinds** — all controls mapped via CBA (can be rebound)
- **Interior audio** — config-level occlusion fix makes sirens audible inside the cabin

Mean's original lightbar visuals, flashers, and radar are unaffected.

## GitHub

<https://github.com/Scorpio4938/ivory-mean-compact>

## Credits

- **Means** — Means Emergency Vehicle Pack. Credit given, and love and affection delivered to all 37 cars.
- **Ivory** — Ivory Car Pack (siren audio system).
- **CBA Team** — Community Base Addons.

## License

This repo's original code (the `mean_patch` addon) is licensed under the [MIT License](LICENSE). Our code uses and adapts systems from the source mods listed in Credits — please respect their terms as stated above.
