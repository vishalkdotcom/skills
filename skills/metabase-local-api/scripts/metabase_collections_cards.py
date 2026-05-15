#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""List Metabase collections and cards from WSL when Metabase runs on Windows.

Reads MB_LOCAL_API_KEY from the environment only (shell profile, direnv, CI secrets).
Discovers a working base URL by probing localhost then Windows host IPs (default gateway /
resolv.conf).

Shipped with the metabase-local-api skill. Example:

  uv run ~/.agents/skills/metabase-local-api/scripts/metabase_collections_cards.py

Optional overrides:
  MB_METABASE_BASE_URL   e.g. http://172.28.80.1:7000
  MB_METABASE_HOST       host only (port from MB_METABASE_PORT)
  MB_METABASE_PORT       default 7000
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def windows_host_candidates() -> list[str]:
    hosts: list[str] = []
    env_host = os.environ.get("MB_METABASE_HOST") or os.environ.get("METABASE_HOST")
    if env_host:
        hosts.append(env_host.strip())
    hosts.extend(["127.0.0.1", "localhost"])
    try:
        out = subprocess.check_output(
            ["ip", "route", "show", "default"],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=5,
        )
        m = re.search(r"default via (\d+\.\d+\.\d+\.\d+)", out)
        if m:
            hosts.append(m.group(1))
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        pass
    try:
        rc = Path("/etc/resolv.conf").read_text()
        m = re.search(r"nameserver\s+(\d+\.\d+\.\d+\.\d+)", rc)
        if m:
            hosts.append(m.group(1))
    except OSError:
        pass
    seen: set[str] = set()
    uniq: list[str] = []
    for h in hosts:
        if h and h not in seen:
            seen.add(h)
            uniq.append(h)
    return uniq


def metabase_json(base: str, api_key: str, path: str, timeout: float = 30) -> object:
    url = f"{base.rstrip('/')}{path}"
    req = Request(
        url,
        headers={
            "X-API-Key": api_key,
            "Accept": "application/json",
        },
    )
    with urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode())


def probe_base(port: int, api_key: str) -> str | None:
    fixed = os.environ.get("MB_METABASE_BASE_URL")
    if fixed:
        fixed = fixed.rstrip("/")
        try:
            metabase_json(fixed, api_key, "/api/user/current")
            return fixed
        except (HTTPError, URLError, OSError, TimeoutError, ValueError):
            return None
    for host in windows_host_candidates():
        base = f"http://{host}:{port}"
        try:
            metabase_json(base, api_key, "/api/user/current")
            return base
        except (HTTPError, URLError, OSError, TimeoutError, ValueError):
            continue
    return None


def collection_items(base: str, api_key: str, collection_id: str | int) -> list[dict]:
    cid = "root" if collection_id == "root" else str(collection_id)
    raw = metabase_json(base, api_key, f"/api/collection/{cid}/items")
    if isinstance(raw, dict) and "data" in raw and isinstance(raw["data"], list):
        return raw["data"]
    if isinstance(raw, list):
        return raw
    return []


def gather_collections(base: str, api_key: str) -> list[dict]:
    """Breadth-first walk of collection tree; returns unique collections by id."""
    found: dict[int | str, dict] = {}
    queue: list[str | int] = ["root"]
    seen_queue: set[str | int] = set()

    while queue:
        cid = queue.pop(0)
        if cid in seen_queue:
            continue
        seen_queue.add(cid)

        if cid != "root":
            found[cid] = {"id": cid, "name": _collection_name(base, api_key, cid)}

        for item in collection_items(base, api_key, cid):
            if not isinstance(item, dict):
                continue
            if item.get("model") != "collection":
                continue
            sub_id = item.get("id")
            if sub_id is None:
                continue
            name = item.get("name") or ""
            found[sub_id] = {"id": sub_id, "name": name}
            queue.append(sub_id)

    try:
        root_meta = metabase_json(base, api_key, "/api/collection/root")
    except (HTTPError, URLError, OSError, TimeoutError, ValueError):
        root_meta = None
    if isinstance(root_meta, dict):
        rid = root_meta.get("id", "root")
        found[rid] = {"id": rid, "name": root_meta.get("name") or "Our analytics"}
    elif "root" not in found:
        found["root"] = {"id": "root", "name": "Our analytics"}

    rows = list(found.values())

    def sort_key(r: dict) -> tuple:
        rid = r["id"]
        if rid == "root":
            return (0, "")
        return (1, str(r.get("name") or ""))

    rows.sort(key=sort_key)
    return rows


def _collection_name(base: str, api_key: str, cid: str | int) -> str:
    try:
        raw = metabase_json(base, api_key, f"/api/collection/{cid}")
        if isinstance(raw, dict) and "name" in raw:
            return str(raw["name"])
    except (HTTPError, URLError, OSError, TimeoutError, ValueError):
        pass
    return ""


def gather_cards(base: str, api_key: str) -> list[dict]:
    raw = metabase_json(base, api_key, "/api/card")
    if not isinstance(raw, list):
        return []
    rows = []
    for c in raw:
        if not isinstance(c, dict):
            continue
        cid = c.get("id")
        name = c.get("name")
        if cid is None:
            continue
        rows.append(
            {
                "id": cid,
                "name": name or "",
                "collection_id": c.get("collection_id"),
                "archived": bool(c.get("archived")),
            }
        )
    rows.sort(key=lambda r: (str(r["name"]), r["id"]))
    return rows


def main() -> int:
    api_key = os.environ.get("MB_LOCAL_API_KEY")
    if not api_key:
        print(
            "Missing MB_LOCAL_API_KEY (export it or set -gx in fish).",
            file=sys.stderr,
        )
        return 1

    port = int(os.environ.get("MB_METABASE_PORT", "7000"))
    base = probe_base(port, api_key)
    if not base:
        tried = windows_host_candidates()
        print(
            f"Could not reach Metabase on port {port}. Probes tried hosts: {', '.join(tried)}.\n"
            "From WSL, Metabase on Windows is often reachable via the Windows host IP:\n"
            "  WIN_IP=$(ip route | awk '/^default/ {print $3; exit}')\n"
            "  export MB_METABASE_BASE_URL=\"http://${WIN_IP}:7000\"\n"
            "Or enable WSL mirrored networking so localhost is shared.",
            file=sys.stderr,
        )
        return 2

    print(f"Metabase base URL: {base}\n")

    try:
        collections = gather_collections(base, api_key)
        cards = gather_cards(base, api_key)
    except HTTPError as e:
        print(f"HTTP error from Metabase: {e.code} {e.reason}", file=sys.stderr)
        return 3

    active_cards = [c for c in cards if not c["archived"]]
    archived_cards = [c for c in cards if c["archived"]]

    print("=== Collections ===")
    for row in collections:
        print(f"  id={row['id']!r}\tname={row['name']!r}")
    print(f"Total collections: {len(collections)}\n")

    print("=== Cards (not archived) ===")
    for row in active_cards:
        coll = row["collection_id"]
        print(f"  id={row['id']}\tcollection_id={coll!r}\tname={row['name']!r}")
    print(f"Total active cards: {len(active_cards)}\n")

    if archived_cards:
        print("=== Cards (archived) ===")
        for row in archived_cards:
            coll = row["collection_id"]
            print(f"  id={row['id']}\tcollection_id={coll!r}\tname={row['name']!r}")
        print(f"Total archived cards: {len(archived_cards)}\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
