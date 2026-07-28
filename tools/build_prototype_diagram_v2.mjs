import fs from "node:fs/promises";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const sharp = require("C:/Users/M2A2FAM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp");

const svg = String.raw`
<svg xmlns="http://www.w3.org/2000/svg" width="2400" height="1500" viewBox="0 0 2400 1500">
  <defs>
    <linearGradient id="tankTop" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0" stop-color="#ffffff"/>
      <stop offset="1" stop-color="#e8f2f8"/>
    </linearGradient>
    <linearGradient id="tankFront" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0" stop-color="#f7fbff"/>
      <stop offset="1" stop-color="#dce9f2"/>
    </linearGradient>
    <linearGradient id="tankSide" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0" stop-color="#d6e5ef"/>
      <stop offset="1" stop-color="#bed3e2"/>
    </linearGradient>
    <linearGradient id="water" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0" stop-color="#9cddff" stop-opacity="0.70"/>
      <stop offset="1" stop-color="#43adde" stop-opacity="0.42"/>
    </linearGradient>
    <linearGradient id="pcb" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0" stop-color="#25aa70"/>
      <stop offset="1" stop-color="#14794e"/>
    </linearGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="150%">
      <feDropShadow dx="12" dy="18" stdDeviation="12" flood-color="#000" flood-opacity="0.15"/>
    </filter>
    <style>
      .title { font: 800 58px Arial, sans-serif; fill: #17384d; }
      .subtitle { font: 400 30px Arial, sans-serif; fill: #506879; }
      .label { font: 800 32px Arial, sans-serif; fill: #172b3a; }
      .small { font: 700 23px Arial, sans-serif; fill: #172b3a; }
      .legend { font: 500 24px Arial, sans-serif; fill: #263f51; }
      .legendHead { font: 800 30px Arial, sans-serif; fill: #17384d; }
      .stroke { stroke: #172b3a; stroke-width: 7; stroke-linejoin: round; stroke-linecap: round; }
      .wire { fill: none; stroke: #172b3a; stroke-width: 8; stroke-linecap: round; stroke-linejoin: round; }
      .dash { fill: none; stroke: #172b3a; stroke-width: 8; stroke-dasharray: 22 18; stroke-linecap: round; stroke-linejoin: round; }
      .thin { stroke: #244a62; stroke-width: 4; stroke-linecap: round; }
      .card { fill: #fff; stroke: #b6c7d3; stroke-width: 4; }
      .marker { fill: #17384d; stroke: #ffffff; stroke-width: 6; }
      .markerText { font: 800 28px Arial, sans-serif; fill: #ffffff; }
    </style>
  </defs>

  <rect width="2400" height="1500" fill="#fbfdff"/>
  <text x="1200" y="75" text-anchor="middle" class="title">SMART-GROW Prototype 3D-Style Layout</text>
  <text x="1200" y="118" text-anchor="middle" class="subtitle">IoT-based oyster mushroom humidifier system for ADHIKA</text>

  <!-- Main prototype -->
  <g filter="url(#shadow)">
    <ellipse cx="1375" cy="1235" rx="760" ry="78" fill="#000" opacity="0.10"/>
    <polygon points="765,415 1765,415 1935,585 935,585" fill="url(#tankTop)" class="stroke"/>
    <polygon points="935,585 1935,585 1935,1085 935,1085" fill="url(#tankFront)" class="stroke"/>
    <polygon points="1765,415 1935,585 1935,1085 1765,918" fill="url(#tankSide)" class="stroke"/>
    <polygon points="980,650 1885,650 1885,1000 980,1000" fill="url(#water)" opacity="0.75"/>
    <line x1="980" y1="650" x2="1885" y2="650" class="thin" opacity="0.55"/>
  </g>
  <text x="1435" y="1165" text-anchor="middle" class="title">Water Tank / Humidifier Chamber</text>

  <!-- Output tube -->
  <g filter="url(#shadow)">
    <ellipse cx="1425" cy="365" rx="165" ry="50" fill="#fff" class="stroke"/>
    <path d="M1260 365 L1260 675 C1260 740 1590 740 1590 675 L1590 365" fill="#f4f9fc" class="stroke"/>
    <ellipse cx="1425" cy="675" rx="165" ry="50" fill="#fff" class="stroke"/>
    <path d="M1276 675 C1327 630 1523 630 1574 675" fill="none" stroke="#172b3a" stroke-width="7" stroke-dasharray="18 18"/>
  </g>
  <text x="1425" y="285" text-anchor="middle" class="label">Humidifier Output Tube</text>
  <path d="M1425 315 C1420 260 1440 225 1485 195" fill="none" stroke="#244a62" stroke-width="7"/>
  <path d="M1485 195 l-18 52 l-28 -34 z" fill="#244a62"/>
  <text x="1535" y="205" class="legend">Mist outlet</text>

  <!-- Intake fan -->
  <g>
    <rect x="1015" y="535" width="135" height="135" rx="20" fill="#fff" class="stroke"/>
    <circle cx="1082" cy="602" r="51" fill="#f9fcff" class="stroke"/>
    <circle cx="1082" cy="602" r="13" fill="#172b3a"/>
    <path d="M1082 553 C1118 551 1127 576 1097 589 Z" fill="#172b3a"/>
    <path d="M1134 604 C1140 640 1115 652 1098 619 Z" fill="#172b3a"/>
    <path d="M1067 650 C1034 637 1035 609 1071 613 Z" fill="#172b3a"/>
    <path d="M1033 585 C1038 552 1065 548 1071 583 Z" fill="#172b3a"/>
    <path d="M930 585 C965 585 975 562 1005 562" fill="none" stroke="#172b3a" stroke-width="6"/>
    <path d="M930 622 C965 622 975 645 1005 645" fill="none" stroke="#172b3a" stroke-width="6"/>
  </g>

  <!-- UV -->
  <g>
    <circle cx="1555" cy="870" r="88" fill="#fff" class="stroke"/>
    <circle cx="1555" cy="870" r="51" fill="#eef8ff" stroke="#172b3a" stroke-width="7"/>
    <text x="1555" y="891" text-anchor="middle" font-family="Arial" font-size="52" font-weight="800" fill="#172b3a">UV</text>
    <g stroke="#f6bd39" stroke-width="8">
      <line x1="1555" y1="760" x2="1555" y2="792"/>
      <line x1="1555" y1="948" x2="1555" y2="980"/>
      <line x1="1445" y1="870" x2="1477" y2="870"/>
      <line x1="1633" y1="870" x2="1665" y2="870"/>
      <line x1="1477" y1="792" x2="1502" y2="817"/>
      <line x1="1608" y1="923" x2="1633" y2="948"/>
      <line x1="1633" y1="792" x2="1608" y2="817"/>
      <line x1="1502" y1="923" x2="1477" y2="948"/>
    </g>
  </g>

  <!-- Piezoelectric disk -->
  <g>
    <circle cx="830" cy="920" r="66" fill="#fff" class="stroke"/>
    <circle cx="830" cy="920" r="20" fill="#fff" stroke="#172b3a" stroke-width="6"/>
    <path d="M848 938 L895 965 L868 986 L839 947" fill="#e8edf2" stroke="#172b3a" stroke-width="5"/>
  </g>

  <!-- Wiring, kept low and clear -->
  <path d="M830 920 L950 920 L1082 602" class="dash"/>
  <path d="M830 920 L1555 870" class="dash"/>
  <path d="M830 920 L935 1085" class="dash"/>

  <!-- Power box -->
  <g filter="url(#shadow)">
    <rect x="145" y="235" width="480" height="310" rx="24" class="card"/>
    <text x="385" y="198" text-anchor="middle" class="label">Power / Microcontroller Box</text>
    <text x="265" y="300" text-anchor="middle" class="small">ATX PSU</text>
    <rect x="185" y="330" width="160" height="125" rx="20" fill="#f8fbff" class="stroke"/>
    <circle cx="265" cy="392" r="43" fill="#fff" class="stroke"/>
    <circle cx="265" cy="392" r="10" fill="#172b3a"/>
    <path d="M265 352 C294 352 303 375 278 386 Z" fill="none" stroke="#172b3a" stroke-width="6"/>
    <path d="M306 392 C306 421 283 430 272 405 Z" fill="none" stroke="#172b3a" stroke-width="6"/>
    <path d="M265 432 C236 432 227 409 252 398 Z" fill="none" stroke="#172b3a" stroke-width="6"/>
    <path d="M224 392 C224 363 247 354 258 379 Z" fill="none" stroke="#172b3a" stroke-width="6"/>
    <text x="485" y="300" text-anchor="middle" class="small">ESP32</text>
    <rect x="405" y="345" width="170" height="100" rx="13" fill="url(#pcb)" stroke="#172b3a" stroke-width="6"/>
    <rect x="465" y="381" width="40" height="32" rx="5" fill="#1c2730"/>
    <rect x="430" y="362" width="42" height="18" rx="4" fill="#1c2730"/>
    <rect x="520" y="362" width="26" height="20" rx="4" fill="#91c6e8"/>
    <g fill="#dcefe6">
      <circle cx="435" cy="428" r="6"/><circle cx="460" cy="428" r="6"/>
      <circle cx="530" cy="428" r="6"/><circle cx="555" cy="428" r="6"/>
    </g>
    <text x="385" y="505" text-anchor="middle" class="legend">Power conversion and control logic</text>
  </g>
  <path d="M625 390 C705 410 760 450 835 520" class="wire"/>

  <!-- Controller sub-box -->
  <g filter="url(#shadow)">
    <polygon points="150,805 355,760 500,842 500,1082 295,1137 150,1082" fill="#fff" class="stroke"/>
    <polygon points="150,805 355,760 500,842 295,895" fill="#f8fbff" class="stroke"/>
    <text x="325" y="735" text-anchor="middle" class="label">Controller Sub-box</text>
    <rect x="285" y="930" width="160" height="100" rx="13" fill="url(#pcb)" stroke="#172b3a" stroke-width="6"/>
    <rect x="314" y="963" width="52" height="44" rx="7" fill="#6b6561" stroke="#172b3a" stroke-width="5"/>
    <g stroke="#dcefe6" stroke-width="6">
      <line x1="382" y1="957" x2="432" y2="957"/>
      <line x1="382" y1="988" x2="432" y2="988"/>
      <line x1="382" y1="1019" x2="432" y2="1019"/>
    </g>
    <text x="365" y="1085" text-anchor="middle" class="legend">Humidifier driver</text>
  </g>
  <path d="M500 992 C595 970 675 940 764 920" class="wire"/>
  <path d="M300 805 L300 545" class="wire"/>
  <text x="265" y="675" class="label" transform="rotate(-90 265 675)">10 m cable</text>

  <!-- SCD40 sensor -->
  <g filter="url(#shadow)">
    <rect x="2040" y="295" width="235" height="150" rx="24" class="card"/>
    <text x="2157" y="257" text-anchor="middle" class="label">SCD40 Sensor</text>
    <circle cx="2110" cy="367" r="25" fill="#172b3a"/>
    <circle cx="2205" cy="367" r="25" fill="#172b3a"/>
    <rect x="2092" y="410" width="130" height="15" rx="8" fill="#23aa6e"/>
    <text x="2157" y="493" text-anchor="middle" class="small">CO2 + Temp + RH</text>
  </g>

  <!-- Pump -->
  <g filter="url(#shadow)">
    <path d="M1935 760 L2055 760 L2055 828 L2115 828" class="wire"/>
    <rect x="2140" y="850" width="190" height="112" rx="26" fill="#101820"/>
    <rect x="2174" y="810" width="95" height="48" rx="14" fill="#101820"/>
    <rect x="2112" y="885" width="28" height="64" rx="10" fill="#101820"/>
    <rect x="2330" y="885" width="28" height="64" rx="10" fill="#101820"/>
    <rect x="2182" y="962" width="150" height="26" rx="8" fill="#101820"/>
    <g stroke="#fff" stroke-width="8" stroke-linecap="round">
      <line x1="2185" y1="887" x2="2268" y2="887"/>
      <line x1="2185" y1="917" x2="2268" y2="917"/>
      <line x1="2185" y1="947" x2="2268" y2="947"/>
    </g>
    <text x="2235" y="1037" text-anchor="middle" class="label">Self-priming</text>
    <text x="2235" y="1077" text-anchor="middle" class="label">Water Pump</text>
  </g>

  <!-- Numbered component markers -->
  <g>
    <circle cx="1425" cy="360" r="28" class="marker"/><text x="1425" y="370" text-anchor="middle" class="markerText">1</text>
    <circle cx="1082" cy="602" r="28" class="marker"/><text x="1082" y="612" text-anchor="middle" class="markerText">2</text>
    <circle cx="1555" cy="870" r="28" class="marker"/><text x="1555" y="880" text-anchor="middle" class="markerText">3</text>
    <circle cx="830" cy="920" r="28" class="marker"/><text x="830" y="930" text-anchor="middle" class="markerText">4</text>
    <circle cx="385" cy="390" r="28" class="marker"/><text x="385" y="400" text-anchor="middle" class="markerText">5</text>
    <circle cx="365" cy="970" r="28" class="marker"/><text x="365" y="980" text-anchor="middle" class="markerText">6</text>
    <circle cx="2157" cy="367" r="28" class="marker"/><text x="2157" y="377" text-anchor="middle" class="markerText">7</text>
    <circle cx="2235" cy="905" r="28" class="marker"/><text x="2235" y="915" text-anchor="middle" class="markerText">8</text>
  </g>

  <!-- Legend panel, separate from graphics -->
  <g>
    <rect x="665" y="1205" width="1000" height="245" rx="24" fill="#fff" stroke="#b7c7d3" stroke-width="5"/>
    <text x="705" y="1260" class="legendHead">Component Legend</text>
    <text x="705" y="1310" class="legend">1 Humidifier output tube</text>
    <text x="705" y="1350" class="legend">2 Intake fan</text>
    <text x="705" y="1390" class="legend">3 UV disinfection light</text>
    <text x="1085" y="1310" class="legend">4 Piezoelectric disk</text>
    <text x="1085" y="1350" class="legend">5 Power / microcontroller box</text>
    <text x="1085" y="1390" class="legend">6 Humidifier driver sub-box</text>
    <text x="1455" y="1310" class="legend">7 SCD40 sensor</text>
    <text x="1455" y="1350" class="legend">8 Self-priming water pump</text>
    <line x1="1455" y1="1390" x2="1535" y2="1390" class="wire"/>
    <text x="1555" y="1398" class="legend">External cable / pipe</text>
    <line x1="1455" y1="1430" x2="1535" y2="1430" class="dash"/>
    <text x="1555" y="1438" class="legend">Internal connection</text>
  </g>
</svg>`;

await fs.writeFile("analysis_outputs/smart_grow_prototype_3d_clean.svg", svg);
await sharp(Buffer.from(svg)).png().resize({ width: 2800 }).toFile("analysis_outputs/smart_grow_prototype_3d_clean.png");
console.log("analysis_outputs/smart_grow_prototype_3d_clean.png");

