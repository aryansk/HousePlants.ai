import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import path from "node:path";
import fs from "node:fs/promises";

const require = createRequire(import.meta.url);
const sharp = require("/Users/aryansingh/Downloads/Projects/Indiehouse.io Website/node_modules/sharp");

const root = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
const inputDir = path.join(root, "submission", "screenshots");
const outputDir = path.join(inputDir, "scrapbook");
const stickerPath = path.join(root, "submission", "assets", "pressed-leaf-sticker.png");
const width = 1320;
const height = 2868;
const screenWidth = 960;
const screenHeight = Math.round(screenWidth * 2868 / 1320);
const cardWidth = 1030;
const cardHeight = 2200;
const cardX = 142;
const cardY = 650;

const colors = {
  paper: "#F5EEDC",
  paperWhite: "#FFFDF7",
  ink: "#17244D",
  green: "#2A9D58",
  blue: "#2444DC",
  yellow: "#F5C52A",
  coral: "#F0796A",
  pink: "#F6B5B0",
  mint: "#DCEED8",
};

const escapeXml = (value) => String(value)
  .replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;")
  .replaceAll('"', "&quot;")
  .replaceAll("'", "&apos;");

const linesMarkup = (lines, { x, y, size, lineHeight, family, weight = 700, fill = colors.ink, italic = false, letterSpacing = 0 }) => {
  const tspans = lines.map((line, index) => `<tspan x="${x}" dy="${index === 0 ? 0 : lineHeight}">${escapeXml(line)}</tspan>`).join("");
  return `<text x="${x}" y="${y}" font-family="${family}" font-size="${size}px" font-weight="${weight}"${italic ? " font-style=\"italic\"" : ""} letter-spacing="${letterSpacing}px" fill="${fill}">${tspans}</text>`;
};

const tape = ({ x, y, w, h, color, rotation }) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="5" fill="${color}" opacity="0.84" transform="rotate(${rotation} ${x + w / 2} ${y + h / 2})"/>`;

const backgroundSvg = (spec) => {
  const titlePaper = `
    <g transform="rotate(-1.5 430 250)">
      <path d="M55 112L820 104l22 22-8 38 12 35-14 30 12 38-20 35 10 43-28 36-764-8-14-31 12-34-10-35 13-34-12-39 19-34-15-41Z" fill="${colors.paperWhite}" stroke="${colors.ink}" stroke-width="5"/>
      ${tape({ x: 160, y: 82, w: 206, h: 64, color: spec.tape, rotation: -5 })}
      ${linesMarkup(spec.title, { x: 86, y: 216, size: spec.titleSize || 88, lineHeight: 96, family: "Georgia, Times New Roman, serif" })}
    </g>`;
  const subtitle = linesMarkup(spec.subtitle, {
    x: 86,
    y: 414,
    size: 34,
    lineHeight: 43,
    family: "Marker Felt, Noteworthy, Comic Sans MS, cursive",
    weight: 600,
    fill: colors.ink,
    italic: true,
  });
  return `
  <svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
    <defs>
      <pattern id="paperDots" width="84" height="84" patternUnits="userSpaceOnUse">
        <circle cx="9" cy="14" r="2" fill="${colors.ink}" opacity="0.08"/>
        <circle cx="58" cy="48" r="1.5" fill="${colors.coral}" opacity="0.08"/>
        <path d="M20 72l16-2" stroke="${colors.ink}" stroke-width="1" opacity="0.05"/>
      </pattern>
    </defs>
    <rect width="${width}" height="${height}" fill="${colors.paper}"/>
    <rect width="${width}" height="${height}" fill="url(#paperDots)"/>
    <path d="M990 0h330v332c-98-30-176-94-230-196Z" fill="${spec.accent}" opacity="0.12"/>
    <path d="M1120 486c36-36 72-28 101 10-40 26-73 22-101-10Z" fill="none" stroke="${colors.ink}" stroke-width="6" stroke-linecap="round"/>
    <path d="M1180 495c15-19 27-40 34-64" fill="none" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round"/>
    ${tape({ x: 54, y: 46, w: 156, h: 48, color: spec.tape, rotation: -7 })}
    <text x="80" y="82" font-family="Marker Felt, Noteworthy, Comic Sans MS, cursive" font-size="24px" font-weight="700" letter-spacing="2px" fill="${colors.ink}">FIELD NOTE / ${spec.page}</text>
    ${titlePaper}
    ${subtitle}
    <path d="M86 506c134 5 252-8 370 0" fill="none" stroke="${spec.accent}" stroke-width="8" stroke-linecap="round"/>
    <path d="M470 505c14-12 28-12 42 0-14 12-28 12-42 0Z" fill="${colors.coral}"/>
    <path d="M530 505c14-12 28-12 42 0-14 12-28 12-42 0Z" fill="${colors.blue}"/>
    <path d="M78 580h256l16 12-16 13H78l-14-13Z" fill="${spec.badgeColor}" stroke="${colors.ink}" stroke-width="4"/>
    <text x="100" y="610" font-family="Marker Felt, Noteworthy, Comic Sans MS, cursive" font-size="24px" font-weight="700" letter-spacing="1.4px" fill="${spec.badgeColor === colors.yellow ? colors.ink : "#FFFFFF"}">${escapeXml(spec.badge.toUpperCase())}</text>
    <text x="1038" y="615" font-family="Marker Felt, Noteworthy, Comic Sans MS, cursive" font-size="25px" font-weight="700" fill="${colors.ink}" transform="rotate(5 1038 615)">swipe + grow</text>
    <path d="M1116 535c36-24 68-22 97 2-31 26-65 25-97-2Z" fill="${colors.green}" stroke="${colors.ink}" stroke-width="5" transform="rotate(-12 1165 540)"/>
    <path d="M1164 543c-8-30-9-52-2-73" fill="none" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round" transform="rotate(-12 1165 540)"/>
    <rect x="${cardX + 28}" y="${cardY + 34}" width="${cardWidth - 20}" height="${cardHeight - 30}" rx="12" fill="${colors.ink}" opacity="0.9" transform="rotate(${spec.cardRotation} ${cardX + cardWidth / 2} ${cardY + cardHeight / 2})"/>
    <rect x="${cardX + 20}" y="${cardY + 25}" width="${cardWidth - 20}" height="${cardHeight - 30}" rx="12" fill="${spec.accent}" transform="rotate(${spec.cardRotation} ${cardX + cardWidth / 2} ${cardY + cardHeight / 2})"/>
    <rect x="${cardX + 8}" y="${cardY + 10}" width="${cardWidth - 20}" height="${cardHeight - 30}" rx="12" fill="${colors.paperWhite}" stroke="${colors.ink}" stroke-width="5" transform="rotate(${spec.cardRotation} ${cardX + cardWidth / 2} ${cardY + cardHeight / 2})"/>
    ${tape({ x: cardX + 380, y: cardY - 30, w: 238, h: 92, color: spec.tape, rotation: spec.tapeRotation })}
    <path d="M${cardX + 914} ${cardY + 92}l42 20-28 27-42-20Z" fill="${colors.pink}" stroke="${colors.ink}" stroke-width="4" transform="rotate(8 ${cardX + 935} ${cardY + 120})"/>
    <text x="${cardX + 50}" y="${cardY + cardHeight - 30}" font-family="Marker Felt, Noteworthy, Comic Sans MS, cursive" font-size="22px" font-weight="700" fill="${colors.ink}" transform="rotate(-2 ${cardX + 50} ${cardY + cardHeight - 30})">houseplant field notes</text>
  </svg>`;
};

async function roundedScreen(fileName) {
  const resized = await sharp(path.join(inputDir, fileName))
    .resize({ width: screenWidth })
    .png()
    .toBuffer();
  const mask = Buffer.from(`<svg width="${screenWidth}" height="${screenHeight}"><rect width="${screenWidth}" height="${screenHeight}" rx="34" fill="white"/></svg>`);
  return sharp(resized)
    .composite([{ input: mask, blend: "dest-in" }])
    .png()
    .toBuffer();
}

async function makeFrame(spec, sticker) {
  const screen = await roundedScreen(spec.screen);
  const cardSvg = Buffer.from(`
    <svg xmlns="http://www.w3.org/2000/svg" width="${cardWidth}" height="${cardHeight}">
      <rect width="${cardWidth}" height="${cardHeight}" fill="none"/>
    </svg>`);
  const card = await sharp(cardSvg)
    .composite([{ input: screen, left: 35, top: 65 }])
    .png()
    .toBuffer();
  const rotatedCard = await sharp(card)
    .rotate(spec.cardRotation, { background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();
  const placedSticker = await sharp(sticker)
    .resize({ width: spec.stickerWidth })
    .rotate(spec.stickerRotation, { background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();
  const background = Buffer.from(backgroundSvg(spec));
  const output = path.join(outputDir, spec.output);
  await sharp(background)
    .composite([
      { input: rotatedCard, left: spec.cardLeft, top: spec.cardTop },
      { input: placedSticker, left: spec.stickerX, top: spec.stickerY },
    ])
    .jpeg({ quality: 95, chromaSubsampling: "4:4:4" })
    .toFile(output);
  return output;
}

const specs = [
  {
    screen: "iphone-catalog.jpg",
    output: "iphone-catalog-scrapbook.jpg",
    page: "01",
    title: ["Find your next", "plant friend"],
    subtitle: ["Browse 200+ plants,", "matched to your life."],
    badge: "plant hunt",
    badgeColor: colors.yellow,
    tape: colors.yellow,
    accent: colors.green,
    cardRotation: -1.1,
    tapeRotation: -4,
    cardLeft: 126,
    cardTop: 644,
    stickerX: 970,
    stickerY: 108,
    stickerWidth: 258,
    stickerRotation: 5,
  },
  {
    screen: "iphone-my-jungle.jpg",
    output: "iphone-my-jungle-scrapbook.jpg",
    page: "02",
    title: ["Your jungle,", "finally in sync"],
    subtitle: ["Smart reminders for", "every plant you love."],
    badge: "care log",
    badgeColor: colors.green,
    tape: colors.blue,
    accent: colors.blue,
    cardRotation: 1.1,
    tapeRotation: 5,
    cardLeft: 132,
    cardTop: 644,
    stickerX: 972,
    stickerY: 105,
    stickerWidth: 254,
    stickerRotation: -6,
  },
  {
    screen: "iphone-plant-detail.jpg",
    output: "iphone-plant-detail-scrapbook.jpg",
    page: "03",
    title: ["Know what your", "plant needs"],
    subtitle: ["Clear care facts,", "right when you need them."],
    badge: "plant profile",
    badgeColor: colors.coral,
    tape: colors.coral,
    accent: colors.yellow,
    titleSize: 82,
    cardRotation: -0.8,
    tapeRotation: -6,
    cardLeft: 128,
    cardTop: 646,
    stickerX: 978,
    stickerY: 104,
    stickerWidth: 250,
    stickerRotation: 4,
  },
  {
    screen: "iphone-tools.jpg",
    output: "iphone-tools-scrapbook.jpg",
    page: "04",
    title: ["Big plant care,", "small daily wins"],
    subtitle: ["Identify, water, and", "protect your green crew."],
    badge: "the toolbox",
    badgeColor: colors.blue,
    tape: colors.mint,
    accent: colors.coral,
    titleSize: 82,
    cardRotation: 0.9,
    tapeRotation: 4,
    cardLeft: 130,
    cardTop: 646,
    stickerX: 970,
    stickerY: 108,
    stickerWidth: 258,
    stickerRotation: -4,
  },
];

await fs.mkdir(outputDir, { recursive: true });
const sticker = await fs.readFile(stickerPath);
const outputs = [];
for (const spec of specs) outputs.push(await makeFrame(spec, sticker));
console.log(outputs.join("\n"));
