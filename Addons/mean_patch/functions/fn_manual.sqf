// mean_patch_fnc_manual
// Displays control reference on the LEFT side (hint).
// Auto-dismisses after 8 seconds for clean closure.

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
