const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

// CRC32 table
const crcTable = [];
for (let n = 0; n < 256; n++) {
  let c = n;
  for (let k = 0; k < 8; k++) {
    c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
  }
  crcTable[n] = c >>> 0;
}

function crc32(buf) {
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) {
    crc = (crc >>> 8) ^ crcTable[(crc ^ buf[i]) & 0xFF];
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function createChunk(type, data) {
  const len = data.length;
  const chunk = Buffer.alloc(12 + len);
  chunk.writeUInt32BE(len, 0);
  chunk.write(type, 4, 4, 'ascii');
  data.copy(chunk, 8);
  const typeAndData = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  chunk.writeUInt32BE(crc32(typeAndData), 8 + len);
  return chunk;
}

function createPng(width, height, pixelFn) {
  const signature = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  // IHDR
  const ihdrData = Buffer.alloc(13);
  ihdrData.writeUInt32BE(width, 0);
  ihdrData.writeUInt32BE(height, 4);
  ihdrData[8] = 8; // bit depth
  ihdrData[9] = 6; // color type: RGBA
  ihdrData[10] = 0; // compression
  ihdrData[11] = 0; // filter
  ihdrData[12] = 0; // interlace
  const ihdrChunk = createChunk('IHDR', ihdrData);

  // Raw image data with row filter bytes
  const rowSize = 1 + width * 4;
  const rawData = Buffer.alloc(height * rowSize);

  for (let y = 0; y < height; y++) {
    const rowOffset = y * rowSize;
    rawData[rowOffset] = 0; // Filter: None
    for (let x = 0; x < width; x++) {
      const pxOffset = rowOffset + 1 + x * 4;
      const [r, g, b, a] = pixelFn(x, y, width, height);
      rawData[pxOffset] = r;
      rawData[pxOffset + 1] = g;
      rawData[pxOffset + 2] = b;
      rawData[pxOffset + 3] = a;
    }
  }

  const compressedData = zlib.deflateSync(rawData);
  const idatChunk = createChunk('IDAT', compressedData);
  const iendChunk = createChunk('IEND', Buffer.alloc(0));

  return Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
}

// Draw Festive Durga Puja Trishul & Bike Logo
function drawFestiveLogo(x, y, w, h) {
  const cx = w / 2;
  const cy = h / 2;
  const dx = x - cx;
  const dy = y - cy;
  const dist = Math.sqrt(dx * dx + dy * dy);
  const radius = w * 0.46;

  // Background outside circle: transparent
  if (dist > radius) {
    return [0, 0, 0, 0];
  }

  // Outer Golden Ring with Durga Puja decorative border
  if (dist >= radius - (w * 0.05)) {
    // Glowing festive gold ring
    const angle = Math.atan2(dy, dx);
    const flowerPattern = Math.sin(angle * 16);
    if (flowerPattern > 0) {
      return [245, 158, 11, 255]; // Bright Gold
    } else {
      return [217, 119, 6, 255]; // Deep Amber
    }
  }

  // Inner ring highlight
  if (dist >= radius - (w * 0.065)) {
    return [254, 240, 138, 255]; // Pale Gold rim
  }

  // Inner Background: Deep Sindoor Crimson to Midnight Navy gradient
  const gradT = (y / h);
  let bgR = Math.round(185 * (1 - gradT * 0.5)); // 185 -> 92
  let bgG = Math.round(28 * (1 - gradT * 0.4));  // 28 -> 17
  let bgB = Math.round(28 * (1 - gradT * 0.3) + 35 * gradT); // 28 -> 45
  let bgA = 255;

  const nx = (x - cx) / (w * 0.5);
  const ny = (y - cy) / (h * 0.5);

  // 1. Center Trishul (Trident 🔱) Motif
  // Vertical stem
  const stemWidth = 0.07;
  const stemTop = -0.55;
  const stemBottom = 0.45;
  if (Math.abs(nx) < stemWidth && ny >= stemTop && ny <= stemBottom) {
    // Gold gradient stem
    const highlight = Math.abs(nx) < 0.025;
    return highlight ? [254, 240, 138, 255] : [245, 158, 11, 255];
  }

  // Central spear tip (triangle at top)
  if (ny < stemTop && ny >= -0.75) {
    const tipWidth = (ny - (-0.75)) * 0.35;
    if (Math.abs(nx) <= tipWidth) {
      return [254, 240, 138, 255];
    }
  }

  // Left & Right Prongs (curved wings)
  const prongCurvature = Math.pow(nx, 2) * 1.6 - 0.28;
  if (Math.abs(nx) >= 0.07 && Math.abs(nx) <= 0.32 && ny <= -0.15 && ny >= -0.65) {
    const prongDist = Math.abs(ny - prongCurvature);
    if (prongDist < 0.06) {
      return [245, 158, 11, 255];
    }
  }

  // Left and Right prong arrow tips
  if (ny <= -0.55 && ny >= -0.68) {
    if (Math.abs(nx - 0.27) < 0.045 || Math.abs(nx + 0.27) < 0.045) {
      return [254, 240, 138, 255];
    }
  }

  // Decorative Crossbar
  if (Math.abs(ny - (-0.18)) < 0.04 && Math.abs(nx) <= 0.30) {
    return [253, 230, 138, 255];
  }

  // 2. Third Eye / Trinayan (ত্রিনয়ন) in the upper center
  const eyeDx = nx;
  const eyeDy = (ny - (-0.38)) * 1.8;
  const eyeDist = eyeDx * eyeDx + eyeDy * eyeDy;
  if (eyeDist < 0.012) {
    if (eyeDist < 0.003) {
      return [220, 38, 38, 255]; // Red Bindi
    }
    return [254, 240, 138, 255]; // Golden Eye outline
  }

  // 3. Motorcycle silhouette at lower half (y from 0.1 to 0.45)
  // Left Wheel (Back wheel)
  const w1Dist = Math.sqrt(Math.pow(nx - (-0.22), 2) + Math.pow(ny - 0.25, 2));
  if (w1Dist < 0.12 && w1Dist > 0.065) {
    return [254, 240, 138, 255]; // Wheel rim
  }
  if (w1Dist <= 0.03) {
    return [254, 240, 138, 255]; // Hub
  }

  // Right Wheel (Front wheel)
  const w2Dist = Math.sqrt(Math.pow(nx - 0.22, 2) + Math.pow(ny - 0.25, 2));
  if (w2Dist < 0.12 && w2Dist > 0.065) {
    return [254, 240, 138, 255]; // Wheel rim
  }
  if (w2Dist <= 0.03) {
    return [254, 240, 138, 255]; // Hub
  }

  // Bike Frame & Handlebar line
  const bikeFrameDist = Math.abs((ny - 0.25) - (-0.35 * nx));
  if (nx >= -0.20 && nx <= 0.20 && bikeFrameDist < 0.035 && ny >= 0.14 && ny <= 0.26) {
    return [255, 255, 255, 255]; // Bike white frame
  }
  // Fuel Tank curve
  const tankDist = Math.sqrt(Math.pow(nx - (-0.02), 2) + Math.pow((ny - 0.16) * 1.6, 2));
  if (tankDist < 0.08) {
    return [245, 158, 11, 255]; // Amber tank
  }
  // Handlebar
  if (Math.abs(nx - 0.16) < 0.03 && ny >= 0.08 && ny <= 0.16) {
    return [255, 255, 255, 255];
  }

  return [bgR, bgG, bgB, bgA];
}

// Generate all target icon sizes
const sizes = [
  { name: 'app_logo.png', dir: 'assets/images', size: 512 },
  { name: 'ic_launcher.png', dir: 'android_res/mipmap-mdpi', size: 48 },
  { name: 'ic_launcher.png', dir: 'android_res/mipmap-hdpi', size: 72 },
  { name: 'ic_launcher.png', dir: 'android_res/mipmap-xhdpi', size: 96 },
  { name: 'ic_launcher.png', dir: 'android_res/mipmap-xxhdpi', size: 144 },
  { name: 'ic_launcher.png', dir: 'android_res/mipmap-xxxhdpi', size: 192 },
  { name: 'logo.png', dir: '../', size: 256 }, // for PWA web app
];

console.log('Generating Festive Durga Puja App Icons...');

sizes.forEach(({ name, dir, size }) => {
  const targetDir = path.resolve(__dirname, '..', dir);
  fs.mkdirSync(targetDir, { recursive: true });
  const targetPath = path.join(targetDir, name);
  const buf = createPng(size, size, drawFestiveLogo);
  fs.writeFileSync(targetPath, buf);
  console.log(`✓ Generated ${targetPath} (${size}x${size}) [${buf.length} bytes]`);
});

console.log('--- All App Icons Generated Successfully ---');
