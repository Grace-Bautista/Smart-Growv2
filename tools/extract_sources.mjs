import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const [, , pdfPath, outPath] = process.argv;

if (!pdfPath || !outPath) {
  console.error("Usage: node extract_sources.mjs <pdfPath> <outPath>");
  process.exit(1);
}

const pdfjsPath =
  "C:/Users/M2A2FAM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/pdfjs-dist/legacy/build/pdf.mjs";
const pdfjs = await import(pathToFileURL(pdfjsPath).href);

const data = new Uint8Array(await fs.readFile(pdfPath));
const doc = await pdfjs.getDocument({ data, disableWorker: true }).promise;
const pages = [];

for (let pageNo = 1; pageNo <= doc.numPages; pageNo += 1) {
  const page = await doc.getPage(pageNo);
  const content = await page.getTextContent();
  const strings = content.items.map((item) => item.str).filter(Boolean);
  pages.push({ page: pageNo, text: strings.join(" ") });
}

await fs.mkdir(path.dirname(outPath), { recursive: true });
await fs.writeFile(outPath, JSON.stringify({ pageCount: doc.numPages, pages }, null, 2));
