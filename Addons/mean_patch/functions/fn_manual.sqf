// ============================================================
// mean_patch_fnc_manual — control reference display
// ============================================================
//
// Displays control reference on the LEFT side of the screen (via hint).
// Auto-dismisses after 8 seconds for clean closure.
//
// Ivory approach: similar help display pattern (parseText + hint).
//
// Why hint instead of hintC / hintC_t / parseText with hintC:
//   - hintC displays multi-line text but shows on the RIGHT side (chat area),
//     which looks unnatural for a control reference.
//   - hint with parseText displays formatted text on the LEFT side
//     (notification area), which is where players expect keybind info.
//   - hintC + parseText doesn't render colored formatting correctly on
//     some Arma versions — hint with parseText works reliably.
//
// Why the terminate guard (mean_patch_manual_dismiss):
//   Prevents double-press race: if the player presses \ twice in quick
//   succession, two auto-dismiss timers would run. The first one would
//   call hintSilent "" after 8s, clearing the hint prematurely (before
//   the second timer's 8s). The guard kills any existing timer before
//   starting a new one, ensuring the last press's 8s timer is the only
//   one active.
//
// Why 8 seconds:
//   Long enough to read (30+ keybinds), short enough to not need manual
//   dismissal. Matches similar mod reference displays.
//
// ============================================================

params [["_car", objNull]];

// Cancel any pending auto-dismiss from previous press
if (!isNil "mean_patch_manual_dismiss") then { terminate mean_patch_manual_dismiss; };

private _text = parseText (
    "<t size='1.3' align='center'>Mean Vehicle Controls</t><br/>" +
    "<br/>" +
    "<t color='#FFC400' align='center'>EMERGENCY</t><br/>" +
    "  <t color='#4EB1BA'>R</t>          — Siren on / off<br/>" +
    "  <t color='#4EB1BA'>Shift+R</t>    — Next siren tone<br/>" +
    "  <t color='#4EB1BA'>T</t>          — Lightbar on / off<br/>" +
    "  <t color='#4EB1BA'>F</t> (hold)   — Horn<br/>" +
    "  <t color='#4EB1BA'>C</t> (hold)   — Takedown tone<br/>" +
    "<br/>" +
    "<t color='#FFC400' align='center'>SIREN TONES</t><br/>" +
    "  <t color='#4EB1BA'>1</t>          — Wail<br/>" +
    "  <t color='#4EB1BA'>2</t>          — Yelp<br/>" +
    "  <t color='#4EB1BA'>3</t>          — Priority<br/>" +
    "  <t color='#4EB1BA'>4</t>          — HiLo"
);

hint _text;

mean_patch_manual_dismiss = [] spawn {
    sleep 8;
    hintSilent "";
    mean_patch_manual_dismiss = nil;
};
