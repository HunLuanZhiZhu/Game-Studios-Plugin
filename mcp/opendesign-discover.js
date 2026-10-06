// opendesign-discover.js — find a live Open Design sidecar pipe that fronts
// the daemon. Printed to stdout: the winning endpoint (full \\.\pipe\ path).
// Run with the Open Design Electron binary in node mode:
//   ELECTRON_RUN_AS_NODE=1 "Open Design.exe" opendesign-discover.js
//
// Protocol (reverse-engineered from @open-design/sidecar): newline-delimited
// JSON over the named pipe; {"type":"sidecar:status"} →
// {"ok":true,"result":{...,"url":"http://127.0.0.1:<dynamic port>"}}.
// The daemon's HTTP port is allocated at runtime, so the pipe handshake — not
// a hardcoded port — is the only reliable way to find it.

const fs = require("fs");
const net = require("net");

const PIPE_ROOT = "\\\\.\\pipe\\";
const PREFIX = "open-design-sidecar-";

function probe(pipe) {
  return new Promise((resolve) => {
    const s = net.connect(pipe);
    let buf = "";
    let settled = false;
    const done = (r) => {
      if (settled) return;
      settled = true;
      try { s.destroy(); } catch (_) {}
      resolve(r);
    };
    s.setTimeout(1500, () => done(null));
    s.on("error", () => done(null));
    s.on("connect", () => s.write(JSON.stringify({ type: "sidecar:status" }) + "\n"));
    s.on("data", (d) => {
      if (settled) return;
      buf += d.toString("utf8");
      const nl = buf.indexOf("\n");
      if (nl === -1) return;
      try {
        const j = JSON.parse(buf.slice(0, nl).trim());
        const url = j && j.ok && j.result && j.result.url;
        done(typeof url === "string" && url.startsWith("http://") ? pipe : null);
      } catch (_) {
        done(null); // first line was not JSON — not a sidecar front
      }
    });
  });
}

(async () => {
  let pipes;
  try {
    pipes = fs.readdirSync(PIPE_ROOT).filter((f) => f.startsWith(PREFIX) && !f.includes("lifecycle"));
  } catch (_) {
    process.exit(1);
  }
  for (const p of pipes) {
    const hit = await probe(PIPE_ROOT + p);
    if (hit) { console.log(hit); return; }
  }
  process.exit(1);
})();
