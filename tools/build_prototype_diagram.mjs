import fs from "node:fs/promises";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const sharp = require("C:/Users/M2A2FAM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp");

const svg = String.raw`
<svg xmlns="http://www.w3.org/2000/svg" width="2200" height="1300" viewBox="0 0 2200 1300">
  <defs>
    <linearGradient id="tankFront" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0" stop-color="#f7fbff"/>
      <stop offset="1" stop-color="#dce9f2"/>
    </linearGradient>
    <linearGradient id="tankSide" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0" stop-color="#dae8f2"/>
      <stop offset="1" stop-color="#bfd3e1"/>
    </linearGradient>
    <linearGradient id="tankTop" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0" stop-color="#ffffff"/>
      <stop offset="1" stop-color="#e9f2f8"/>
    </linearGradient>
    <linearGradient id="water" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0" stop-color="#9cddff" stop-opacity="0.70"/>
      <stop offset="1" stop-color="#44aee0" stop-opacity="0.42"/>
    </linearGradient>
    <linearGradient id="pcb" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0" stop-color="#23aa6e"/>
      <stop offset="1" stop-color="#14784d"/>
    </linearGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="150%">
      <feDropShadow dx="12" dy="18" stdDeviation="13" flood-color="#000" flood-opacity="0.16"/>
    </filter>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto">
      <path d="M0 0 L10 5 L0 10 Z" fill="#244a62"/>
    </marker>
    <style>
      .title { font: 800 62px Arial, sans-serif; fill: #17384d; }
      .subtitle { font: 400 32px Arial, sans-serif; fill: #506879; }
      .label { font: 700 34px Arial, sans-serif; fill: #172b3a; }
      .boxlabel { font: 800 36px Arial, sans-serif; fill: #172b3a; }
      .small { font: 700 24px Arial, sans-serif; fill: #172b3a; }
      .note { font: 500 22px Arial, sans-serif; fill: #435a6b; }
      .stroke { stroke: #172b3a; stroke-width: 7; stroke-linejoin: round; stroke-linecap: round; }
      .thin { stroke: #244a62; stroke-width: 4; stroke-linecap: round; }
      .wire { fill: none; stroke: #172b3a; stroke-width: 8; stroke-linecap: round; stroke-linejoin: round; }
      .dash { fill: none; stroke: #172b3a; stroke-width: 8; stroke-dasharray: 22 18; stroke-linecap: round; stroke-linejoin: round; }
      .callout { fill: none; stroke: #244a62; stroke-width: 5; marker-end: url(#arrow); }
      .card { fill: #fff; stroke: #b6c7d3; stroke-width: 4; }
    </style>
  </defs>

  <rect width="2200" height="1300" fill="#fbfdff"/>
  <text x="1100" y="78" text-anchor="middle" class="title">SMART-GROW Prototype 3D-Style Layout</text>
  <text x="1100" y="124" text-anchor="middle" class="subtitle">IoT-based oyster mushroom humidifier system for ADHIKA</text>

  <!-- Main prototype group -->
  <g filter="url(#shadow)">
    <ellipse cx="1190" cy="1128" rx="650" ry="76" fill="#000" opacity="0.10"/>
    <polygon points="650,390 1590,390 1740,550 800,550" fill="url(#tankTop)" class="stroke"/>
    <polygon points="800,550 1740,550 1740,995 800,995" fill="url(#tankFront)" class="stroke"/>
    <polygon points="1590,390 1740,550 1740,995 1590,840" fill="url(#tankSide)" class="stroke"/>
    <polygon points="830,590 1700,590 1700,930 830,930" fill="url(#water)" opacity="0.70"/>
    <line x1="830" y1="590" x2="1700" y2="590" class="thin" opacity="0.55"/>
  </g>

  <text x="1195" y="1082" text-anchor="middle" class="title">Water Tank / Humidifier Chamber</text>

  <!-- Tube -->
  <g filter="url(#shadow)">
    <ellipse cx="1240" cy="340" rx="170" ry="52" fill="#fff" class="stroke"/>
    <path d="M1070 340 L1070 640 C1070 710 1410 710 1410 640 L1410 340" fill="#f4f9fc" class="stroke"/>
    <ellipse cx="1240" cy="640" rx="170" ry="52" fill="#fff" class="stroke"/>
    <path d="M1086 640 C1140 590 1340 590 1394 640" fill="none" stroke="#172b3a" stroke-width="7" stroke-dasharray="18 18"/>
  </g>
  <text x="1240" y="262" text-anchor="middle" class="label">Humidifier Output Tube</text>
  <path d="M1240 286 C1232 250 1235 220 1260 188" class="callout"/>
  <text x="1292" y="186" class="note">Mist exits to mushroom room</text>

  <!-- Intake fan -->
  <g>
    <rect x="820" y="475" width="132" height="132" rx="20" fill="#fff" class="stroke"/>
    <circle cx="886" cy="541" r="50" fill="#f9fcff" class="stroke"/>
    <circle cx="886" cy="541" r="13" fill="#172b3a"/>
    <path d="M886 493 C922 491 930 515 900 528 Z" fill="#172b3a"/>
    <path d="M937 543 C943 579 919 590 901 558 Z" fill="#172b3a"/>
    <path d="M871 588 C838 575 839 548 875 552 Z" fill="#172b3a"/>
    <path d="M837 524 C842 492 869 487 875 522 Z" fill="#172b3a"/>
    <path d="M742 525 C775 525 785 502 810 502" fill="none" stroke="#172b3a" stroke-width="6"/>
    <path d="M742 556 C775 556 785 579 810 579" fill="none" stroke="#172b3a" stroke-width="6"/>
    <text x="886" y="452" text-anchor="middle" class="label">Intake Fan</text>
  </g>

  <!-- UV -->
  <g>
    <circle cx="1370" cy="815" r="86" fill="#fff" class="stroke"/>
    <circle cx="1370" cy="815" r="50" fill="#eef8ff" stroke="#172b3a" stroke-width="7"/>
    <text x="1370" y="835" text-anchor="middle" font-family="Arial" font-size="52" font-weight="800" fill="#172b3a">UV</text>
    <g stroke="#f6bd39" stroke-width="8">
      <line x1="1370" y1="708" x2="1370" y2="738"/>
      <line x1="1370" y1="892" x2="1370" y2="922"/>
      <line x1="1262" y1="815" x2="1292" y2="815"/>
      <line x1="1448" y1="815" x2="1478" y2="815"/>
      <line x1="1294" y1="739" x2="1317" y2="762"/>
      <line x1="1423" y1="868" x2="1446" y2="891"/>
      <line x1="1446" y1="739" x2="1423" y2="762"/>
      <line x1="1317" y1="868" x2="1294" y2="891"/>
    </g>
    <text x="1370" y="950" text-anchor="middle" class="label">UV Disinfection Light</text>
  </g>

  <!-- Piezo disk -->
  <g>
    <circle cx="700" cy="820" r="64" fill="#fff" class="stroke"/>
    <circle cx="700" cy="820" r="19" fill="#fff" stroke="#172b3a" stroke-width="6"/>
    <path d="M716 837 L760 862 L735 881 L708 846" fill="#e8edf2" stroke="#172b3a" stroke-width="5"/>
    <text x="700" y="740" text-anchor="middle" class="label">Piezoelectric Disk</text>
  </g>

  <!-- internal wiring -->
  <path d="M700 820 L815 820 L886 541" class="dash"/>
  <path d="M700 820 L1370 815" class="dash"/>
  <path d="M700 820 L800 995" class="dash"/>

  <!-- Power/controller callout card -->
  <g filter="url(#shadow)">
    <rect x="105" y="230" width="455" height="315" rx="22" class="card"/>
    <text x="332" y="196" text-anchor="middle" class="boxlabel">Power / Microcontroller Box</text>
    <rect x="150" y="295" width="150" height="118" rx="20" fill="#f8fbff" class="stroke"/>
    <circle cx="225" cy="354" r="42" fill="#fff" class="stroke"/>
    <circle cx="225" cy="354" r="10" fill="#172b3a"/>
    <path d="M225 315 C253 315 262 337 238 348 Z" fill="none" stroke="#172b3a" stroke-width="6"/>
    <path d="M264 354 C264 382 242 391 231 367 Z" fill="none" stroke="#172b3a" stroke-width="6"/>
    <path d="M225 393 C197 393 188 371 212 360 Z" fill="none" stroke="#172b3a" stroke-width="6"/>
    <path d="M186 354 C186 326 208 317 219 341 Z" fill="none" stroke="#172b3a" stroke-width="6"/>
    <text x="225" y="270" text-anchor="middle" class="small">ATX PSU</text>
    <rect x="350" y="310" width="160" height="96" rx="12" fill="url(#pcb)" stroke="#172b3a" stroke-width="6"/>
    <rect x="408" y="344" width="36" height="30" rx="5" fill="#1c2730"/>
    <rect x="374" y="326" width="40" height="18" rx="4" fill="#1c2730"/>
    <rect x="458" y="326" width="24" height="18" rx="4" fill="#91c6e8"/>
    <g fill="#dcefe6">
      <circle cx="380" cy="386" r="6"/><circle cx="402" cy="386" r="6"/>
      <circle cx="465" cy="386" r="6"/><circle cx="487" cy="386" r="6"/>
    </g>
    <text x="430" y="270" text-anchor="middle" class="small">ESP32</text>
    <text x="332" y="480" text-anchor="middle" class="note">Power conversion and control logic</text>
  </g>
  <path d="M560 390 C640 398 680 410 745 470" class="callout"/>

  <!-- Controller sub-box card -->
  <g filter="url(#shadow)">
    <polygon points="130,760 320,718 445,790 445,1010 255,1060 130,1010" fill="#fff" class="stroke"/>
    <polygon points="130,760 320,718 445,790 255,835" fill="#f8fbff" class="stroke"/>
    <text x="255" y="842" text-anchor="middle" class="small">Controller Sub-box</text>
    <rect x="245" y="875" width="145" height="92" rx="12" fill="url(#pcb)" stroke="#172b3a" stroke-width="6"/>
    <rect x="270" y="905" width="47" height="40" rx="6" fill="#6b6561" stroke="#172b3a" stroke-width="5"/>
    <g stroke="#dcefe6" stroke-width="6">
      <line x1="330" y1="900" x2="375" y2="900"/>
      <line x1="330" y1="928" x2="375" y2="928"/>
      <line x1="330" y1="956" x2="375" y2="956"/>
    </g>
    <text x="318" y="1009" text-anchor="middle" class="note">Humidifier driver</text>
  </g>
  <path d="M445 918 C520 890 575 852 636 826" class="wire"/>
  <path d="M255 760 L255 545" class="wire"/>
  <text x="225" y="665" class="label" transform="rotate(-90 225 665)">10 m cable</text>

  <!-- Sensor card -->
  <g filter="url(#shadow)">
    <rect x="1800" y="250" width="235" height="150" rx="24" class="card"/>
    <text x="1917" y="217" text-anchor="middle" class="boxlabel">SCD40 Sensor</text>
    <circle cx="1870" cy="322" r="25" fill="#172b3a"/>
    <circle cx="1965" cy="322" r="25" fill="#172b3a"/>
    <rect x="1852" y="365" width="130" height="15" rx="8" fill="#23aa6e"/>
    <text x="1917" y="445" text-anchor="middle" class="small">CO2 + Temperature + RH</text>
  </g>
  <path d="M1800 395 C1710 470 1660 540 1625 655" class="callout"/>

  <!-- Pump -->
  <g filter="url(#shadow)">
    <path d="M1740 700 L1860 700 L1860 760 L1925 760" class="wire"/>
    <rect x="1935" y="785" width="190" height="112" rx="26" fill="#101820"/>
    <rect x="1970" y="745" width="95" height="48" rx="14" fill="#101820"/>
    <rect x="1908" y="820" width="28" height="64" rx="10" fill="#101820"/>
    <rect x="2125" y="820" width="28" height="64" rx="10" fill="#101820"/>
    <rect x="1975" y="897" width="150" height="26" rx="8" fill="#101820"/>
    <g stroke="#fff" stroke-width="8" stroke-linecap="round">
      <line x1="1978" y1="822" x2="2060" y2="822"/>
      <line x1="1978" y1="852" x2="2060" y2="852"/>
      <line x1="1978" y1="882" x2="2060" y2="882"/>
    </g>
    <text x="2028" y="970" text-anchor="middle" class="label">Self-priming</text>
    <text x="2028" y="1010" text-anchor="middle" class="label">Water Pump</text>
  </g>

  <!-- Legend -->
  <g>
    <rect x="1560" y="1130" width="520" height="120" rx="24" fill="#fff" stroke="#b7c7d3" stroke-width="5"/>
    <line x1="1605" y1="1170" x2="1710" y2="1170" class="wire"/>
    <text x="1745" y="1178" class="note">External cable / pipe route</text>
    <line x1="1605" y1="1218" x2="1710" y2="1218" class="dash"/>
    <text x="1745" y="1226" class="note">Internal connection inside tank</text>
  </g>
</svg>`;

await fs.writeFile("analysis_outputs/smart_grow_prototype_3d_spacious.svg", svg);
await sharp(Buffer.from(svg)).png().resize({ width: 2600 }).toFile("analysis_outputs/smart_grow_prototype_3d_spacious.png");
console.log("analysis_outputs/smart_grow_prototype_3d_spacious.png");
