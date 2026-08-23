import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import path from "node:path";
import fs from "node:fs/promises";

const require = createRequire(import.meta.url);
const sharp = require("/Users/aryansingh/Downloads/Projects/Indiehouse.io Website/node_modules/sharp");

const root = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
const inputDir = path.join(root, "submission", "screenshots");
const outputDir = path.join(inputDir, "marketing");
const mascotPath = path.join(root, "submission", "assets", "sprig-mascot.png");
const width = 1320;
const height = 2868;
const screenWidth = 1030;
const screenLeft = 145;
const screenTop = 620;
const screenHeight = Math.round(screenWidth * height / width);

const colors = {
  paper: "#F7F0DF",
  ink: "#18264E",
  green: "#2BA957",
  blue: "#2141DE",
  yellow: "#F5C620",
  coral: "#F16D61",
  mint: "#D9F1D8",
};

const escapeXml = (value) => String(value)
  .replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;")
  .replaceAll('"', "&quot;")
  .replaceAll("'", "&apos;");

const textLines = (lines, { x = 72, y = 188, size = 100, lineHeight = 106, family = "Georgia, Times New Roman, serif", weight = 700, fill = colors.ink, letterSpacing = 0 } = {}) => {
  const tspans = lines.map((line, index) => `<tspan x="${x}" dy="${index === 0 ? 0 : lineHeight}">${escapeXml(line)}</tspan>`).join("");
  return `<text x="${x}" y="${y}" font-family="${family}" font-size="${size}px" font-weight="${weight}" letter-spacing="${letterSpacing}px" fill="${fill}">${tspans}</text>`;
};

const backgroundSvg = ({ title, subtitle, badge, badgeColor, accentColor, titleSize = 100, mascotX, mascotY, mascotWidth, mascotAngle }) => {
  const badgeWidth = Math.max(250, badge.length * 17 + 82);
  const subtitleLines = subtitle.length > 43 ? [subtitle.slice(0, subtitle.lastIndexOf(" ", 43)), subtitle.slice(subtitle.lastIndexOf(" ", 43) + 1)] : [subtitle];
  const subtitleMarkup = textLines(subtitleLines, {
    x: 76,
    y: subtitleLines.length === 1 ? 382 : 362,
    size: 38,
    lineHeight: 47,
    family: "Arial, Helvetica, sans-serif",
    weight: 600,
    fill: colors.ink,
  });
  return `
  <svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
    <rect width="${width}" height="${height}" fill="${colors.paper}"/>
    <path d="M1040 0h280v345c-112-34-200-114-280-222V0Z" fill="${accentColor}" opacity="0.14"/>
    <circle cx="1218" cy="206" r="80" fill="${accentColor}" opacity="0.18"/>
    <circle cx="1014" cy="486" r="12" fill="${colors.coral}"/>
    <circle cx="1050" cy="514" r="7" fill="${colors.blue}"/>
    <path d="M1150 438c34-40 54-38 74 0-28 20-52 20-74 0Z" fill="${colors.green}" stroke="${colors.ink}" stroke-width="6"/>
    <path d="M1187 438c8-18 17-33 35-48" fill="none" stroke="${colors.ink}" stroke-width="6" stroke-linecap="round"/>
    <text x="76" y="70" font-family="Arial, Helvetica, sans-serif" font-size="24px" font-weight="700" letter-spacing="4px" fill="${colors.ink}">HOUSEPLANTS.AI</text>
    <path d="M77 93c18-16 39-16 57 0-18 16-39 16-57 0Z" fill="${colors.green}" stroke="${colors.ink}" stroke-width="5"/>
    ${textLines(title, { x: 72, y: 188, size: titleSize, lineHeight: titleSize + 8 })}
    ${subtitleMarkup}
    <rect x="72" y="456" width="${badgeWidth}" height="68" rx="34" fill="${badgeColor}"/>
    <text x="106" y="501" font-family="Arial, Helvetica, sans-serif" font-size="25px" font-weight="800" letter-spacing="1.5px" fill="${badgeColor === colors.yellow ? colors.ink : "#FFFFFF"}">${escapeXml(badge.toUpperCase())}</text>
    <path d="M72 564h${Math.min(530, badgeWidth + 78)}" stroke="${accentColor}" stroke-width="9" stroke-linecap="round"/>
    <circle cx="${Math.min(72 + badgeWidth + 88, 760)}" cy="560" r="9" fill="${colors.coral}"/>
    <circle cx="${Math.min(72 + badgeWidth + 116, 790)}" cy="560" r="6" fill="${colors.blue}"/>
    <rect x="${screenLeft + 18}" y="${screenTop + 24}" width="${screenWidth}" height="${screenHeight}" rx="54" fill="${colors.ink}"/>
    <rect x="${screenLeft + 10}" y="${screenTop + 14}" width="${screenWidth}" height="${screenHeight}" rx="54" fill="${accentColor}"/>
    <rect x="${screenLeft}" y="${screenTop}" width="${screenWidth}" height="${screenHeight}" rx="54" fill="#FFFFFF" stroke="${colors.ink}" stroke-width="6"/>
  </svg>`;
};

async function roundedScreen(fileName) {
  const resized = await sharp(path.join(inputDir, fileName))
    .resize({ width: screenWidth })
    .png()
    .toBuffer();
  const mask = Buffer.from(`<svg width="${screenWidth}" height="${screenHeight}"><rect width="${screenWidth}" height="${screenHeight}" rx="54" fill="white"/></svg>`);
  return sharp(resized)
    .composite([{ input: mask, blend: "dest-in" }])
    .png()
    .toBuffer();
}

async function makeFrame(spec, mascot) {
  const background = Buffer.from(backgroundSvg(spec));
  const screen = await roundedScreen(spec.screen);
  const placedMascot = await sharp(mascot)
    .resize({ width: spec.mascotWidth })
    .rotate(spec.mascotAngle, { background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();
  const outputPath = path.join(outputDir, spec.output);
  await sharp(background)
    .composite([
      { input: screen, left: screenLeft, top: screenTop },
      { input: placedMascot, left: spec.mascotX, top: spec.mascotY },
    ])
    .jpeg({ quality: 95, chromaSubsampling: "4:4:4" })
    .toFile(outputPath);
  return outputPath;
}

const specs = [
  {
    screen: "iphone-catalog.jpg",
    output: "iphone-catalog-fun.jpg",
    title: ["Find your next", "plant friend"],
    subtitle: "Browse 200+ plants, matched to your life.",
    badge: "200+ plants to discover",
    badgeColor: colors.yellow,
    accentColor: colors.green,
    mascotX: 1020,
    mascotY: 122,
    mascotWidth: 230,
    mascotAngle: 5,
  },
  {
    screen: "iphone-my-jungle.jpg",
    output: "iphone-my-jungle-fun.jpg",
    title: ["Your jungle,", "finally in sync"],
    subtitle: "Smart reminders for every plant you love.",
    badge: "care that keeps up",
    badgeColor: colors.green,
    accentColor: colors.blue,
    mascotX: 1034,
    mascotY: 120,
    mascotWidth: 214,
    mascotAngle: -5,
  },
  {
    screen: "iphone-plant-detail.jpg",
    output: "iphone-plant-detail-fun.jpg",
    title: ["Know what your", "plant needs"],
    subtitle: "Clear care facts, right when you need them.",
    badge: "care without guesswork",
    badgeColor: colors.coral,
    accentColor: colors.yellow,
    titleSize: 91,
    mascotX: 1025,
    mascotY: 120,
    mascotWidth: 228,
    mascotAngle: 4,
  },
  {
    screen: "iphone-tools.jpg",
    output: "iphone-tools-fun.jpg",
    title: ["Big plant care,", "small daily wins"],
    subtitle: "Identify, water, and protect your green crew.",
    badge: "tools for every plant parent",
    badgeColor: colors.blue,
    accentColor: colors.coral,
    titleSize: 92,
    mascotX: 1025,
    mascotY: 118,
    mascotWidth: 226,
    mascotAngle: -4,
  },
];

await fs.mkdir(outputDir, { recursive: true });
const mascot = await fs.readFile(mascotPath);
const outputs = [];
for (const spec of specs) outputs.push(await makeFrame(spec, mascot));
console.log(outputs.join("\n"));
