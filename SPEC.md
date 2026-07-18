# Spec: Ivory Siren System Patch for Means Emergency Vehicle Pack

## Problem Statement

The Means Emergency Vehicle Pack (37 police/EMS vehicles across 6 models) uses an animation-phase-based siren system that:

- Only has 2 siren tones (Wail, Yelp) with hardcoded sleep timers
- Uses short, non-rebindable keyboard shortcuts via Arma's `UserActions` (`shortcut="sitDown"`)
- Has no multi-tone switching (no Priority or HiLo tones)
- Has no horn-as-audio control system (horn is a weapon horn with `CfgWeapons`)
- Has no Read Manual command

The Ivory Car Pack has a much better system — realistic SS2000 siren tones (4 phases), CBA-rebindable keybinds, a horn audio loop, and a Read Manual system. The user wants Mean vehicles to use Ivory's siren audio, horn audio, keybinding, and manual systems **without modifying the original Mean mod files**.

## Solution

A standalone compatibility patch addon (`mean_patch`) that:

1. Overrides the `init` event handler of every Mean emergency vehicle class
2. The replacement init keeps Mean's original lightbar, flasher, and radar scripts running (they handle only visual/model animations — model-specific behavior)
3. The replacement init **replaces** the original `sirenscv.sqf` with Ivory's `fn_sirens.sqf` and `fn_horn.sqf` via direct function calls
4. Registers CBA keybinds that mirror Ivory's exactly, setting both Mean animation phases (for the original lightbar/radar scripts to read) and Ivory variables (for the siren/horn audio loops to read)
5. Adds a "Read Manual" UserAction to each vehicle class (additive, alongside existing door and radar actions)

The Mean mod and Ivory mod themselves are **never modified** — they are only loaded as dependencies.

## User Stories

1. As a player driving a Mean CVPI, I want to press R to toggle the siren on/off, so that I can activate emergency audio with a single key
2. As a player driving a Mean vehicle, I want pressing R (siren on) to also turn on the lightbar automatically, so that lights and siren activate together for full emergency response
3. As a player driving a Mean vehicle, I want pressing R (siren off) to turn off only the siren while the lightbar stays on, so that I can run silent with lights visible
4. As a player driving a Mean vehicle, I want pressing T to toggle the lightbar, and turning the lightbar off also kills any active siren, so that one key shuts down all emergency visuals and audio
5. As a player driving a Mean vehicle, I want to press Shift+R to cycle through 4 siren tones (Wail → Yelp → Priority → HiLo), so that I can select the appropriate tone for the situation
6. As a player driving a Mean vehicle, I want to press keys 1-4 to directly jump to a specific siren tone, so that I can quickly switch without cycling
7. As a player driving a Mean vehicle, I want to hold F to sound the horn continuously, so that I can alert other vehicles audibly
8. As a player driving a Mean vehicle, I want all emergency keybinds to be rebindable in Arma's CBA Controls menu (ESC → Configure → Addons), so that I can customize the controls to my preferences
9. As a player driving a Mean vehicle, I want a "Read Manual" scroll-wheel action that shows the control reference, so that I can discover the keybindings while in-game
10. As a player using both Ivory and Mean vehicles in the same session, I want the Ivory keybinds to work on Ivory vehicles and the Mean patch keybinds to work on Mean vehicles without either interfering with the other
11. As a player driving a Mean vehicle, I want the original lightbar flashing patterns, flasher animations, and police radar to continue working unchanged, so that the visual equipment behaves as designed
12. As a server administrator, I want to install this patch by placing a single addon folder alongside the existing mods, so that deployment is simple
13. As a player driving a Mean Charger, Tahoe, Taurus, Ambulance, or Silverado, I want the same siren and keybind experience as in the CVPI, so that all emergency vehicles share consistent controls
14. As a player driving a Mean Undercover (UC) variant, I want the siren audio and keybinds to work even though the vehicle has no visible lightbar, so that audio controls remain functional

## Implementation Decisions

### Addon architecture
- The patch is a single addon: `ivory-mean-compact/Addons/mean_patch/`
- CfgPatches class name: `mean_patch` with `tag = "mean_patch"`
- Required addons: `Meanscars`, `Ivory_Data`, `cba_main`
- Uses CBA CfgFunctions to compile SQF functions and run a postInit for keybind registration
- All function calls use the absolute Arma P-drive paths (e.g. `\mean_patch\functions\fn_initCar.sqf`)

### Config override approach
- Each of the 37 Mean vehicle concrete classes gets its `EventHandlers.init` overridden in the patch mod's `config.cpp`
- The replacement init calls `mean_patch_fnc_initCar`
- Each override uses additive class inheritance (`class M_CVPI: M_CVPI {}`) so other config properties are inherited unchanged
- A custom config property (`emergencySiren = 1`) is added to each base class so Ivory's `fn_sirens.sqf` knows which siren set to use (SS2000 vs PA300)
- UserAction for "Read Manual" is added additively (`class UserActions: UserActions`) so door open/close actions remain

### InitCar bridge function
- A single `fn_initCar.sqf` uses a `switch` on `typeOf` to determine which vehicle model the current vehicle belongs to
- For each detected model, it `execVM`s the original Mean scripts for Lightbar, Flashers, and Radar (using the original Mean paths) but deliberately skips `sirenscv.sqf`
- It then initializes Ivory-style variables (`ani_siren`, `ani_horn`, `ani_lightbar`) on the vehicle and spawns `ivory_fnc_horn` and `ivory_fnc_sirens`
- The function runs client-side (checks `isDedicated` or `hasInterface`)

### Dual-state keybind mechanism
- Each CBA keybind sets both:
  - An animation phase via `animate` (for the original Mean lightbar/flasher scripts to read)
  - A vehicle variable via `setVariable` (for Ivory's siren/horn audio loops to read)
- Mean uses `ani_sirens` (with trailing 's') as the animation source name — the keybinds animate this to 0.2 (on) or 0 (off)
- Ivory's siren uses `ani_siren` (no trailing 's') as the variable name — the keybinds set this to 0-4
- Both Mean and Ivory use `ani_lightbar` for lightbar control but through different subsystems (Mean reads it as animation phase, Ivory reads it as variable) — this is safe since animation phases and variables are separate namespaces

### State machine for siren/lightbar interlock
- The R key (siren toggle) implements the exact Ivory interlock behavior:
  - Siren OFF → ON: sets both `ani_siren` variable AND `ani_lightbar` variable/anim, plus `ani_sirens` animation
  - Siren ON → OFF: sets only `ani_siren` variable and `ani_sirens` animation to off; lightbar is unchanged
- The T key (lightbar toggle):
  - Lightbar OFF → ON: sets lightbar variable and animation to the current pattern
  - Lightbar ON → OFF: sets lightbar variable and animation to off, ALSO sets siren variable and animation to off (kills siren)
- These behaviors are captured in the keybind callback closures, not in a separate state machine script

### Key bindings
| Key | Action |
|---|---|
| F (hold) | Horn |
| R | Siren on/off |
| Shift+R | Next siren tone (Wail→Yelp→Priority→HiLo→Wail) |
| 1 | Siren: Wail |
| 2 | Siren: Yelp |
| 3 | Siren: Priority |
| 4 | Siren: HiLo |
| T | Lightbar on/off |
| Shift+T | Next lightbar pattern |
| \ | Read Manual |

### Siren audio system
- Sound classes are references to Ivory's `CfgSounds` entries (`ivory_ss2000_wail`, `ivory_ss2000_yelp`, `ivory_ss2000_priority`, `ivory_ss2000_hilo`, `ivory_ss2000_airhorn`)
- No new CfgSounds entries are created in the patch mod — all sounds come from Ivory
- The siren audio uses Ivory's spawned while-loop pattern with `say3D` on a `#particlesource` dummy entity for positional 3D audio
- The horn audio uses Ivory's `ivory_fnc_horn` which plays `ivory_ss2000_airhorn` on a loop while `ani_horn` variable is 1

### Vehicle model routing table
- CVPI variants (`M_CVPI*`) → original scripts at `\MeansCars\2011_CVPI\data\scripts\`
- Charger variants (`M_Charger12*`) → `\MeansCars\2012_Charger\data\scripts\`
- Tahoe variants (`M_Tahoe*`) → `\MeansCars\2015_Tahoe\data\scripts\`
- Taurus/FPIS variants (`M_FPIS*`) → `\MeansCars\Ford_Torus\data\scripts\`
- Ambulance (`M_Ambulance*`) → `\MeansCars\Ambulance\data\scripts\`
- Silverado variants (`M_Silverado*`) → `\MeansCars\2012_Charger\data\scripts\` (reuses Charger scripts as per original config)

### File structure
```
ivory-mean-compact/
  Addons/
    mean_patch/
      config.cpp                    CfgPatches, CfgVehicles overrides, CfgFunctions
      scripts/
        init.sqf                    CBA keybinds and CBA settings (postInit)
      functions/
        fn_initCar.sqf              Replacement init that bridges Mean → Ivory
        fn_manual.sqf               Read Manual display function
```

## Testing Decisions

### What makes a good test
Testing is manual (the Arma 3 modding ecosystem does not have automated SQF test frameworks). A good test verifies external player-observable behavior, not internal state:
- Does pressing key X produce the correct audio and visual result?
- Does behavior match Ivory's exactly (interlock, mode switching)?
- Are there any conflicts with the original system (doubled audio, broken animations)?

### Test scenarios
1. **Init test per vehicle model**: Spawn one of each of the 6 vehicle base types. Verify the lightbar flashes correctly. Verify no doubled siren sounds. Verify radar still works.
2. **Keybind test**: Press each bound key (F, R, T, 1-4, Shift+R, Shift+T, \) on a Mean CVPI. Verify correct response.
3. **Interlock test**: Press R → verify lightbar and siren both activate. Press R again → verify siren stops but lightbar continues. Press T → verify lightbar stops (and siren if it was on). Press R again → verify both turn on.
4. **Ivory non-interference test**: Spawn an Ivory vehicle and a Mean vehicle. Verify Ivory keybinds work on Ivory vehicle, Mean patch keybinds work on Mean vehicle.
5. **Multi-vehicle test**: Verify all 37 concrete vehicle classes spawn and respond to controls correctly (spot-check representative variants from each model).

### Prior art
The Ivory Car Pack itself is the reference implementation. The patch mirrors its behavior exactly — an Ivory vehicle and a patched Mean vehicle should behave identically for siren, horn, and keybind interactions.

## Out of Scope

- **Lightbar visuals**: The physical lightbar flashing (texture swaps, light patterns) remains handled by Mean's original `lightbar.sqf` and `Flashers.sqf`. This patch does not change any visual aspects of the models.
- **Radar functionality**: The original Mean `radar.sqf` continues to run unchanged.
- **MegaPhone/TFAR integration**: Not included. Ivory's megaPhone keybind (Tab) is commented out in Ivory itself and is not replicated.
- **Navigation/GPS**: Ivory's A3GPS navigation system is not ported to Mean vehicles.
- **Cruise control, spoiler control, high beams, spotlight**: Not applicable to Mean vehicles and not replicated.
- **Expanpoli mod**: This patch only covers the Means Emergency Vehicle Pack. A separate patch for Expanpoli would be a separate project.
- **Civillian vehicles**: The Mean mod has no civilian vehicles (it is purely emergency vehicles). If civilian Mean vehicles are added in future, this patch would not cover them.

## Further Notes

- The patch requires all three mods (Mean, Ivory, and CBA_A3) to be loaded. Missing dependencies will cause Arma to error on startup.
- The original Mean `UserActions` for Code One/Two/Three remain visible in the scroll-wheel menu but are superseded by the CBA keybinds. Players will naturally stop using them.
- On the Windows Arma P-drive, the file paths use backslashes (`\`) following standard Arma 3 conventions. The code written here must use backslash path separators.
- Ivory's function tag system (`ivory_fnc_*`) compiles functions at CBA postInit — Mean vehicles that spawn before postInit (rare) would not have access to these functions until postInit completes.
- The `emergencySiren` config property is set to `1` (SS2000) for all Mean vehicles. If future Mean variants wanted PA300 (EMS-style) tones, they could override this to `2`.
