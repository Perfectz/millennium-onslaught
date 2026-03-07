#!/usr/bin/env python3
"""Validate docs/events/event_catalog.md against autoloads/event_bus.gd."""

from __future__ import annotations

import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
EVENT_BUS_PATH = REPO_ROOT / "autoloads" / "event_bus.gd"
EVENT_CATALOG_PATH = REPO_ROOT / "docs" / "events" / "event_catalog.md"

SIGNAL_RE = re.compile(r"^\s*signal\s+([a-zA-Z0-9_]+)\((.*)\)\s*$")
ROW_RE = re.compile(r"^\|\s*`([^`]+)`\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|$")


def parse_event_bus() -> dict[str, str]:
    signals: dict[str, str] = {}
    for line in EVENT_BUS_PATH.read_text(encoding="utf-8").splitlines():
        match = SIGNAL_RE.match(line)
        if not match:
            continue
        name = match.group(1).strip()
        payload = match.group(2).strip()
        signals[name] = payload if payload else "*none*"
    return signals


def parse_catalog() -> dict[str, str]:
    rows: dict[str, str] = {}
    for line in EVENT_CATALOG_PATH.read_text(encoding="utf-8").splitlines():
        match = ROW_RE.match(line)
        if not match:
            continue
        name = match.group(1).strip()
        payload = normalize_payload(match.group(2))
        rows[name] = payload
    return rows


def normalize_payload(payload: str) -> str:
    normalized = payload.strip()
    if normalized.startswith("`") and normalized.endswith("`"):
        normalized = normalized[1:-1].strip()
    return normalized


def main() -> int:
    event_bus_signals = parse_event_bus()
    catalog_rows = parse_catalog()

    errors: list[str] = []

    missing_in_catalog = sorted(set(event_bus_signals) - set(catalog_rows))
    if missing_in_catalog:
        errors.append(
            "Missing signals in docs/events/event_catalog.md: "
            + ", ".join(missing_in_catalog)
        )

    extra_in_catalog = sorted(set(catalog_rows) - set(event_bus_signals))
    if extra_in_catalog:
        errors.append(
            "Signals documented but not present in autoloads/event_bus.gd: "
            + ", ".join(extra_in_catalog)
        )

    for signal_name in sorted(set(event_bus_signals) & set(catalog_rows)):
        documented_payload = catalog_rows[signal_name]
        actual_payload = event_bus_signals[signal_name]
        if documented_payload != actual_payload:
            errors.append(
                f"Payload mismatch for '{signal_name}': "
                f"catalog='{documented_payload}' event_bus='{actual_payload}'"
            )

    if errors:
        print("Event catalog validation failed:", file=sys.stderr)
        for error in errors:
            print(f" - {error}", file=sys.stderr)
        return 1

    print(
        f"Event catalog validation passed: {len(event_bus_signals)} signals match "
        f"{EVENT_CATALOG_PATH.relative_to(REPO_ROOT)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
