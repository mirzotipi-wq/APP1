function runReview() {
  "use strict";
  const inputSHA = "c76e176fa60d29f8ebd49845d7e8ea883c11b64f";
  const sourceBlob = "24a00f8bb13717c86377590a22d22faeab4153f4";
  const buffer = new ArrayBuffer(8);
  const view = new DataView(buffer);
  const eps32 = 2 ** -23;
  const eps64 = Number.EPSILON;
  function invariant(value, message) { if (!value) throw new Error(message); }
  function nextFloat(value, direction) {
    if (value === 0) return direction > 0 ? Number.MIN_VALUE : -Number.MIN_VALUE;
    view.setFloat64(0, value, false);
    let bits = view.getBigUint64(0, false);
    bits += ((value > 0) === (direction > 0)) ? 1n : -1n;
    view.setBigUint64(0, bits, false);
    return view.getFloat64(0, false);
  }
  function gcd(a, b) { while (b) { const c = a % b; a = b; b = c; } return a < 0n ? -a : a; }
  function fraction(n, d) { const k = gcd(n, d); return { n: n / k, d: d / k }; }
  function rational(value) {
    view.setFloat64(0, value, false);
    const bits = view.getBigUint64(0, false);
    const exponent = Number((bits >> 52n) & 2047n);
    let numerator = bits & ((1n << 52n) - 1n);
    if (exponent !== 0) numerator += 1n << 52n;
    if ((bits >> 63n) !== 0n) numerator = -numerator;
    const power = exponent === 0 ? -1074 : exponent - 1075;
    return power >= 0 ? fraction(numerator << BigInt(power), 1n) : fraction(numerator, 1n << BigInt(-power));
  }
  // This function deliberately transcribes the frozen Swift interval path.
  // Only the separate fullPixels function is the independent geometry oracle.
  function intervalModel(width, distance, focal) {
    const height = width * 2 / 3;
    const margin = 32 * eps32 * distance;
    const innerRadius = Math.max(0, 0.22 - margin), outerRadius = 0.22 + margin;
    invariant(outerRadius < distance, "invalid geometry");
    const innerQ = innerRadius ** 2 / (distance ** 2 - innerRadius ** 2);
    const outerQ = outerRadius ** 2 / (distance ** 2 - outerRadius ** 2);
    const halfW = 36 / (2 * focal), halfH = 24 / (2 * focal);
    const indexPad = 32 * eps64 * width, budget = Math.floor(width * height / 510);
    function pixelRange(lower, upper) {
      const lo = nextFloat(width * (lower / halfW + 1) / 2 - 0.5, -1);
      const hi = nextFloat(width * (upper / halfW + 1) / 2 - 0.5, 1);
      const first = Math.max(0, Math.ceil(lo - indexPad));
      const last = Math.min(width - 1, Math.floor(hi + indexPad));
      return first <= last ? [first, last] : null;
    }
    const pixels = new Set();
    let count = 0, overlapRemoved = 0, firstExceeded = null;
    for (let y = 0; y < height; y++) {
      const py = (1 - 2 * (y + 0.5) / height) * halfH;
      const y2 = py * py, slopePad = 32 * eps64 * Math.max(outerQ, y2);
      const outerX2 = outerQ - y2;
      if (outerX2 < -slopePad) continue;
      const outerX = Math.sqrt(Math.max(0, outerX2 + slopePad));
      const innerX = Math.sqrt(Math.max(0, innerQ - y2 - slopePad));
      const negative = pixelRange(-outerX, -innerX), positive = pixelRange(innerX, outerX);
      let row = 0;
      for (const range of [negative, positive]) {
        if (!range) continue;
        row += range[1] - range[0] + 1;
        for (let x = range[0]; x <= range[1]; x++) pixels.add(y * width + x);
      }
      if (negative && positive) {
        const overlap = Math.max(0, Math.min(negative[1], positive[1]) - Math.max(negative[0], positive[0]) + 1);
        row -= overlap;
        overlapRemoved += overlap;
      }
      invariant(row >= 0, "row union must be nonnegative");
      count += row;
      invariant(count === pixels.size, "interval arithmetic differs from explicit integer union");
      if (firstExceeded === null && count > budget) firstExceeded = y;
    }
    invariant((firstExceeded === null) === (count <= budget), "early exit mismatch");
    return { count, pixels, overlapRemoved, firstExceeded };
  }
  // Independent full enumeration. A ray is (sensorX, sensorY,-focal).
  // Its distance from the centered sphere is D*|sensorXY|/|ray|.
  // Compare squared closest approach against exact rational shell radii.
  // No projected-circle formula, inverse pixel mapping, row interval, or
  // tolerance is used for this reference.
  function fullPixels(width, distance, focal) {
    const height = width * 2 / 3;
    const D = rational(distance), F = rational(focal), R = rational(0.22);
    const M = fraction(D.n, D.d * 262144n);
    const inner = fraction(R.n * M.d - M.n * R.d, R.d * M.d);
    const outer = fraction(R.n * M.d + M.n * R.d, R.d * M.d);
    invariant(inner.n > 0n, "inner shell outside assigned domain");
    const d2n = D.n * D.n, d2d = D.d * D.d;
    const innerL = d2n * inner.d * inner.d, innerR = d2d * inner.n * inner.n;
    const outerL = d2n * outer.d * outer.d, outerR = d2d * outer.n * outer.n;
    // Both axes have sensor pixel pitch 36/width == 24/height.
    const sFactor = 324n * F.d * F.d;
    const fFactor = BigInt(width) ** 2n * F.n * F.n;
    const exact = [], binary64 = [];
    const inner64 = 0.22 - 32 * eps32 * distance, outer64 = 0.22 + 32 * eps32 * distance;
    for (let y = 0; y < height; y++) {
      const iy = height - 2 * y - 1;
      const py = (1 - 2 * (y + 0.5) / height) * (24 / (2 * focal));
      for (let x = 0; x < width; x++) {
        const ix = 2 * x + 1 - width;
        const s = sFactor * BigInt(ix * ix + iy * iy), norm = s + fFactor;
        if (innerL * s >= innerR * norm && outerL * s <= outerR * norm) exact.push(y * width + x);
        // Additional, independent binary64 normalized-ray check, using the
        // renderer's pixel-center expressions but no projected annulus.
        const px = (2 * (x + 0.5) / width - 1) * (36 / (2 * focal));
        const miss = distance * Math.hypot(px, py) / Math.hypot(px, py, 1);
        if (miss >= inner64 && miss <= outer64) binary64.push(y * width + x);
      }
    }
    return { exact, binary64 };
  }
  const cases = [];
  function add(name, width, distance, focal) {
    invariant(width >= 24 && width <= 192 && width % 3 === 0, "width contract");
    invariant(distance > 0.27 && distance <= 20 && focal >= 14 && focal <= 200, "parameter contract");
    cases.push({ name, width, height: width * 2 / 3, distance, focal });
  }
  const widths = Array.from({ length: 57 }, (_, i) => 24 + 3 * i);
  const domains = [[nextFloat(0.27, 1), 14], [nextFloat(0.27, 1), 200], [3, 50], [20, 14], [20, 200]];
  for (const width of widths) {
    for (let k = 0; k < domains.length; k++) add("domain-" + k, width, ...domains[k]);
    const height = width * 2 / 3, distance = 3;
    const points = [{ label: "edge", x: Math.floor(width / 2) + Math.floor(width / 8), y: Math.floor(height / 2) }];
    if (width % 2) points.push({ label: "tangent", x: (width - 1) / 2, y: 0 });
    for (const p of points) {
      for (const side of [-1, 1]) {
        const radius = 0.22 + side * 32 * eps32 * distance;
        const sx = (2 * p.x + 1 - width) * 18 / width;
        const sy = (height - 2 * p.y - 1) * 12 / height;
        const focal = Math.hypot(sx, sy) * Math.sqrt(distance * distance - radius * radius) / radius;
        for (const delta of [-1, 0, 1]) {
          const f = delta ? nextFloat(focal, delta) : focal;
          add(p.label + (side < 0 ? "-inner-" : "-outer-") + delta, width, distance, f);
        }
      }
    }
  }
  add("consumer-width24", 24, 3, 161.27198111190464);
  for (const width of [27, 48, 96, 192]) add("consumer-width" + width, width, 3, 161.27198111190464);
  add("odd-center-width51", 51, 3, 158.39589488231985);
  add("prior-endpoint-width27", 27, 1.1314814252261085, 50);
  invariant(cases.length === 802, "unexpected coverage size");
  const budgetRows = widths.map(width => {
    const n = width * (width * 2 / 3), b = Math.floor(n / (2 * 255));
    invariant(b * 510 <= n && (b + 1) * 510 > n, "floor budget mismatch");
    invariant(255 * b * 2 <= n, "half-mean budget exceeded");
    invariant(b * 400 < n, "half-outlier budget must be strict");
    return { width, height: width * 2 / 3, pixels: n, budget: b, worstMean: 255 * b / n, worstOutlierFraction: b / n };
  });
  const rows = [], failures = [];
  let visited = 0, rawTotal = 0, doubleTotal = 0, countedTotal = 0, overlaps = 0, extras = 0, exactMismatchCases = 0, earlyRejects = 0;
  for (const c of cases) {
    const counted = intervalModel(c.width, c.distance, c.focal), raw = fullPixels(c.width, c.distance, c.focal);
    visited += c.width * c.height;
    const missing = raw.exact.filter(p => !counted.pixels.has(p));
    const doubleMissing = raw.binary64.filter(p => !counted.pixels.has(p));
    const budget = Math.floor(c.width * c.height / 510);
    const row = { ...c, pixelBudget: budget, rawExact: raw.exact.length, rawBinary64: raw.binary64.length,
      intervalCount: counted.count, shellGatePasses: counted.count <= budget, overlapRemoved: counted.overlapRemoved,
      firstExceededRow: counted.firstExceeded, exactMissing: missing, binary64Missing: doubleMissing };
    if (c.name.startsWith("consumer-") || c.name.startsWith("odd-center-") || c.name.startsWith("prior-endpoint-")) {
      row.rawExactPixels = raw.exact.map(p => [p % c.width, Math.floor(p / c.width)]);
      row.rawBinary64Pixels = raw.binary64.map(p => [p % c.width, Math.floor(p / c.width)]);
      row.intervalPixels = Array.from(counted.pixels).sort((a,b)=>a-b).map(p => [p % c.width, Math.floor(p / c.width)]);
    }
    if (missing.length || doubleMissing.length) failures.push(row);
    if (counted.count !== raw.exact.length) exactMismatchCases++;
    if (counted.firstExceeded !== null) earlyRejects++;
    countedTotal += counted.count; rawTotal += raw.exact.length; doubleTotal += raw.binary64.length;
    extras += counted.count - raw.exact.length; overlaps += counted.overlapRemoved;
    rows.push(row);
  }
  const named = rows.filter(r => r.rawExactPixels);
  const summary = {
    inputSHA, frozenSourceBlob: sourceBlob, runtime: "functions.exec V8 JavaScript; exact rational reference uses BigInt",
    configurations: cases.length, widths: widths.length, oddWidths: widths.filter(w => w % 2).length,
    fullPixelsEnumerated: visited, undercountCases: failures.length, rawExactTotal: rawTotal, rawBinary64Total: doubleTotal,
    intervalTotal: countedTotal, conservativeExtraPixels: extras, conservativeExtraCases: exactMismatchCases,
    duplicateCenterContributionsRemoved: overlaps, earlyRejectedConfigurations: earlyRejects,
    budgetWidthsChecked: budgetRows.length,
    worstBudgetMean: Math.max(...budgetRows.map(r=>r.worstMean)),
    worstBudgetOutlierFraction: Math.max(...budgetRows.map(r=>r.worstOutlierFraction)),
    shellMarginAt3Meters: 32 * eps32 * 3,
    named
  };
  return { summary, failures, budgets: budgetRows, cases: rows };
}

if (typeof module !== "undefined" && module.exports) module.exports = { runReview };
if (typeof require !== "undefined" && require.main === module) console.log(JSON.stringify(runReview(), null, 2));
