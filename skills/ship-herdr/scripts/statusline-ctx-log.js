"use strict";

/**
 * Prototype helper required from ~/.cursor/statusline.js.
 * When Cursor CLI invokes the statusline inside a Herdr pane, detached-push
 * ctx% onto pane metadata. JSONL is opt-in (CURSOR_CTX_JSONL=1).
 * Never throws. Never writes stdout (the statusline renderer owns that).
 */

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawn } = require("node:child_process");

const LOG_DIR = path.join(os.tmpdir(), "cursor-ctx-log");
const SOURCE = "cursor-statusline";
const TTL_MS = "300000";
const PUSH_DEBOUNCE_MS = 15_000;

function usedPct(p) {
  const raw = p?.context_window?.used_percentage;
  if (raw == null || !Number.isFinite(Number(raw))) return null;
  return Math.floor(Number(raw));
}

function hasWindow(p) {
  const size = Number(p?.context_window?.context_window_size);
  return Number.isFinite(size) && size > 0;
}

function logDir() {
  fs.mkdirSync(LOG_DIR, { recursive: true });
  return LOG_DIR;
}

function appendJsonl(record) {
  const session = record.session_id || "unknown";
  const file = path.join(logDir(), `${session}.jsonl`);
  fs.appendFileSync(file, `${JSON.stringify(record)}\n`);
}

function shouldPush(paneId, pct) {
  const stamp = path.join(logDir(), `${paneId.replace(/[^\w.-]/g, "_")}.stamp`);
  try {
    const prev = fs.readFileSync(stamp, "utf8");
    const [prevPct, prevAt] = prev.split("\t");
    if (prevPct === String(pct) && Date.now() - Number(prevAt) < PUSH_DEBOUNCE_MS) {
      return false;
    }
  } catch {
    /* first write */
  }
  fs.writeFileSync(stamp, `${pct}\t${Date.now()}`);
  return true;
}

function pushMetadata(paneId, pct) {
  if (!shouldPush(paneId, pct)) return;
  const herdr = process.env.HERDR_BIN_PATH || "herdr";
  const child = spawn(
    herdr,
    [
      "pane",
      "report-metadata",
      paneId,
      "--source",
      SOURCE,
      "--token",
      `ctx=${pct}`,
      "--ttl-ms",
      TTL_MS,
    ],
    { detached: true, stdio: "ignore", windowsHide: true },
  );
  child.unref();
}

function report(p) {
  if (!p || typeof p !== "object") return;
  if (!hasWindow(p)) return;
  const pct = usedPct(p);
  if (pct == null) return;

  const paneId = process.env.HERDR_PANE_ID || null;
  const record = {
    ts: Date.now(),
    session_id: p.session_id || null,
    pane_id: paneId,
    herdr_env: process.env.HERDR_ENV || null,
    pct,
    total_input_tokens: p.context_window?.total_input_tokens ?? null,
    context_window_size: p.context_window?.context_window_size ?? null,
  };
  if (process.env.CURSOR_CTX_JSONL === "1") {
    try {
      appendJsonl(record);
    } catch {
      /* log is diagnostic */
    }
  }
  if (process.env.HERDR_ENV === "1" && paneId) {
    try {
      pushMetadata(paneId, pct);
    } catch {
      /* scrape fallback still works */
    }
  }
}

module.exports = { report, LOG_DIR };
