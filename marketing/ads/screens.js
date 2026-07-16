/* Builds faithful HousePlants.ai app-screen markup for ad mockups. */

const STATUS = `
<div class="statusbar">
  <span>9:41</span>
  <div class="icons"><span><i class="ti ti-antenna-bars-5"></i></span>
  <span><i class="ti ti-wifi"></i></span><span><i class="ti ti-battery-3"></i></span></div>
</div>`;

/* --- SVG plant "photo" tiles (no network, always render) --- */
function leaf(variant) {
  const bg = {
    monstera: ['#dff0d8', '#a7cf7e'], snake: ['#e3efe0', '#7faf6a'],
    fig:      ['#e8f1de', '#9ec77a'], pothos: ['#e0efe2', '#84c08e'],
    zz:       ['#dfeedd', '#6fa85f'], calathea: ['#e9efdd', '#9bbf6f']
  }[variant] || ['#e3efda', '#9cc377'];
  const shapes = {
    monstera: `<path d="M195 60 C120 70 95 150 110 210 C150 205 175 175 195 150 C215 175 240 205 280 210 C295 150 270 70 195 60 Z" fill="#3f6b2c"/>
      <path d="M150 120 l18 8 M170 160 l20 6 M225 120 l-18 8 M210 160 l-20 6" stroke="#dff0d8" stroke-width="6" stroke-linecap="round"/>`,
    snake: `<g fill="#3a6b34"><rect x="150" y="40" width="22" height="180" rx="11"/><rect x="184" y="55" width="22" height="165" rx="11"/><rect x="218" y="42" width="22" height="178" rx="11"/></g>
      <g stroke="#bcd99a" stroke-width="4"><line x1="161" y1="50" x2="161" y2="210"/><line x1="195" y1="62" x2="195" y2="210"/><line x1="229" y1="52" x2="229" y2="210"/></g>`,
    fig: `<g fill="#3f6b2c"><ellipse cx="150" cy="90" rx="40" ry="52"/><ellipse cx="240" cy="100" rx="38" ry="50"/><ellipse cx="195" cy="170" rx="44" ry="56"/></g>
      <path d="M195 70 v150 M150 90 v40 M240 100 v40" stroke="#cfe6ad" stroke-width="5"/>`,
    pothos: `<g fill="#3a7a4a"><path d="M195 60 c-50 0 -80 40 -70 90 c40 0 65 -30 70 -70 c5 40 30 70 70 70 c10 -50 -20 -90 -70 -90Z"/><ellipse cx="120" cy="190" rx="30" ry="22"/><ellipse cx="270" cy="190" rx="30" ry="22"/></g>`,
    zz: `<g fill="#2f5e2c"><ellipse cx="140" cy="120" rx="22" ry="40" transform="rotate(-25 140 120)"/><ellipse cx="180" cy="100" rx="22" ry="42"/><ellipse cx="220" cy="120" rx="22" ry="40" transform="rotate(25 220 120)"/><ellipse cx="165" cy="180" rx="22" ry="40" transform="rotate(-12 165 180)"/><ellipse cx="225" cy="180" rx="22" ry="40" transform="rotate(12 225 180)"/></g>`,
    calathea: `<g fill="#3f6b2c"><ellipse cx="170" cy="130" rx="48" ry="70" transform="rotate(-18 170 130)"/><ellipse cx="225" cy="150" rx="46" ry="66" transform="rotate(20 225 150)"/></g>
      <path d="M150 80 C165 130 165 170 165 200 M245 95 C228 145 225 175 222 205" stroke="#c9e3a4" stroke-width="5" fill="none"/>`
  };
  return `<svg viewBox="0 0 390 230" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg">
    <rect width="390" height="230" fill="${bg[0]}"/><circle cx="320" cy="40" r="120" fill="${bg[1]}" opacity=".45"/>
    ${shapes[variant] || shapes.pothos}</svg>`;
}

function card(name, latin, variant, diff, diffColor) {
  return `<div class="card">
    <div class="photo">${leaf(variant)}</div>
    <div class="body"><h3>${name}</h3><div class="latin">${latin}</div>
      <span class="badge" style="background:${diffColor}1f;color:${diffColor}"><i class="ti ti-leaf"></i>${diff}</span>
    </div></div>`;
}

/* --- Discover tab --- */
function discoverScreen() {
  return STATUS + `
  <div class="appheader">
    <div class="kicker">HousePlants</div>
    <h1>Discover</h1>
    <div class="sub">Find your next houseplant</div>
    <div class="loc"><i class="ti ti-map-pin"></i> San Francisco</div>
  </div>
  <div class="search"><i class="ti ti-search"></i> Search plants, species, care tips…</div>
  <div class="pills">
    <div class="pill on"><i class="ti ti-leaf"></i> All</div>
    <div class="pill">Tropical</div><div class="pill">Succulent</div><div class="pill">Low light</div>
  </div>
  <div class="sectiontitle"><h2>Explore all plants</h2><span class="count">512</span></div>
  <div class="scroll"><div class="grid">
    ${card('Monstera', 'Monstera deliciosa', 'monstera', 'Easy', '#1d9e75')}
    ${card('Snake Plant', 'Dracaena trifasciata', 'snake', 'Very easy', '#639922')}
    ${card('Fiddle Leaf Fig', 'Ficus lyrata', 'fig', 'Medium', '#BA7517')}
    ${card('Golden Pothos', 'Epipremnum aureum', 'pothos', 'Very easy', '#639922')}
  </div></div>` + tabbar(0);
}

/* --- Tools tab --- */
function toolsScreen() {
  const tool = (ic, color, h, p) => `<div class="tool">
    <div class="ic" style="background:${color}1f;color:${color}"><i class="ti ${ic}"></i></div>
    <div><h4>${h}</h4><p>${p}</p></div><div class="chev"><i class="ti ti-chevron-right"></i></div></div>`;
  return STATUS + `
  <div class="appheader"><div class="kicker">HousePlants</div><h1>Tools</h1>
    <div class="sub">Advanced aids for your interior ecosystem</div></div>
  <div class="featured">
    <div style="display:flex;align-items:center;gap:14px">
      <div class="fticon"><i class="ti ti-camera"></i></div>
      <div><div class="ft-k">FEATURED TOOL</div><h3>Plant Identifier</h3></div></div>
    <p>Snap a photo of any plant and instantly discover its name and care guide.</p>
    <div class="cta">Identify now <i class="ti ti-arrow-right"></i></div>
  </div>
  <div class="toolgroup">Essential care</div>
  <div class="scroll" style="padding:0">
    ${tool('ti-sun', '#e08e2a', 'Sun Seeker', 'Light meter to find the perfect spot.')}
    ${tool('ti-droplet', '#378add', 'Watering Guide', 'Schedules tuned to your micro-climate.')}
    ${tool('ti-stethoscope', '#e24b4a', 'Plant Doctor', 'Diagnose pests and diseases fast.')}
    ${tool('ti-shield-check', '#1d9e75', 'Toxicity Checker', 'Verify pet & child safety instantly.')}
  </div>` + tabbar(1);
}

/* --- Plant Identifier camera screen --- */
function identifyScreen() {
  return STATUS + `
  <div class="camera">
    <div class="viewfinder">
      ${leaf('monstera')}
      <div class="corner tl"></div><div class="corner tr"></div>
      <div class="corner bl"></div><div class="corner br"></div>
    </div>
    <div class="shutter"></div>
  </div>
  <div class="id-result">
    <div class="match"><i class="ti ti-circle-check"></i> 98% MATCH</div>
    <h2>Swiss Cheese Plant</h2>
    <div class="latin">Monstera deliciosa</div>
  </div>` + tabbar(1);
}

function tabbar(active) {
  const t = [['ti-leaf','Discover'],['ti-tools','Tools'],['ti-heart','My Jungle'],['ti-user','Profile']];
  return `<div class="tabbar">${t.map((x,i)=>`<div class="tab ${i===active?'on':''}">
    <i class="ti ${x[0]}"></i>${x[1]}</div>`).join('')}</div>`;
}

function phone(screenHTML) {
  return `<div class="phone"><div class="notch"></div><div class="screen">${screenHTML}</div></div>`;
}
