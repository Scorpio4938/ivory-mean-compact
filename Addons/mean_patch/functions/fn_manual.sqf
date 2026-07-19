// mean_patch_fnc_manual
// Displays the control reference for Means vehicles using the Ivory siren system.

params [["_car", objNull]];

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

hintC _text;
