#!/usr/bin/env python3
import os
import json
import sqlite3
import shutil
import sys

# Store name -> DB filename mapping
STORES = {
    "GOG": "gog.db",
    "Epic": "epic.db",
    "Amazon": "amazon.db",
    "itch.io": "itchio.db",
}

# Default install directories per store
DEFAULT_INSTALL_DIRS = {
    "GOG": "Games/gog/",
    "Epic": "Games/epic/",
    "Amazon": "Games/amazon/",
    "itch.io": "Games/itchio/",
}


def parse_size_to_bytes(size_str):
    """Parse formatted size string back to bytes (e.g., '45.20 GB' -> 48536870912)."""
    if not size_str or not isinstance(size_str, str):
        return 0
    size_str = size_str.strip()
    try:
        parts = size_str.split()
        if len(parts) != 2:
            return 0
        value = float(parts[0])
        unit = parts[1].upper()
        if unit == "GB":
            return int(value * 1024**3)
        elif unit == "MB":
            return int(value * 1024**2)
        elif unit == "KB":
            return int(value * 1024)
        elif unit == "BYTES":
            return int(value)
        return 0
    except (ValueError, IndexError):
        return 0


def convert_bytes(size):
    """Convert bytes to human-readable string."""
    try:
        if size >= 1024**3:
            return f"{size / 1024**3:.2f} GB"
        elif size >= 1024**2:
            return f"{size / 1024**2:.2f} MB"
        elif size >= 1024:
            return f"{size / 1024:.2f} KB"
        else:
            return f"{size} bytes"
    except Exception:
        return "0 bytes"


def get_storage_stats(runtime_dir):
    """Query all store databases and return storage statistics."""
    home = os.path.expanduser("~")
    stores = []
    all_games = []

    for store_name, db_filename in STORES.items():
        db_path = os.path.join(runtime_dir, db_filename)
        if not os.path.exists(db_path):
            continue

        try:
            conn = sqlite3.connect(db_path)
            conn.execute("PRAGMA journal_mode=WAL;")
            c = conn.cursor()
            c.row_factory = sqlite3.Row

            # Get installed games (SteamClientID set)
            c.execute(
                "SELECT ShortName, Title, Size, InstallPath FROM Game "
                "WHERE SteamClientID IS NOT NULL AND SteamClientID <> ''"
            )
            games = c.fetchall()
            conn.close()

            store_total_bytes = 0
            for game in games:
                size_bytes = parse_size_to_bytes(game["Size"])
                store_total_bytes += size_bytes
                all_games.append({
                    "shortname": game["ShortName"],
                    "store": store_name,
                    "title": game["Title"] or game["ShortName"],
                    "size": game["Size"] or "Unknown",
                    "size_bytes": size_bytes,
                })

            stores.append({
                "name": store_name,
                "size": convert_bytes(store_total_bytes),
                "size_bytes": store_total_bytes,
                "count": len(games),
            })
        except Exception as e:
            print(f"Error reading {store_name} DB: {e}", file=sys.stderr)

    # Sort games by size (largest first)
    all_games.sort(key=lambda g: g["size_bytes"], reverse=True)

    # Sort stores by size (largest first)
    stores.sort(key=lambda s: s["size_bytes"], reverse=True)

    total_used = sum(s["size_bytes"] for s in stores)

    # Check free space on common install locations
    disk_spaces = []

    # SSD (home directory)
    try:
        usage = shutil.disk_usage(home)
        disk_spaces.append({
            "location": "Internal Storage",
            "path": home,
            "free": convert_bytes(usage.free),
            "free_bytes": usage.free,
            "total": convert_bytes(usage.total),
            "total_bytes": usage.total,
            "used_percent": round((usage.used / usage.total) * 100, 1),
        })
    except Exception:
        pass

    # MicroSD card
    sd_paths = ["/run/media/mmcblk0p1"]
    # Also check for symlinked SD cards
    try:
        for entry in os.scandir("/run/media"):
            if entry.is_symlink() or entry.is_dir():
                sd_paths.append(entry.path)
    except Exception:
        pass

    seen_devices = set()
    for sd_path in sd_paths:
        if os.path.exists(sd_path) and os.path.ismount(sd_path):
            try:
                usage = shutil.disk_usage(sd_path)
                # Deduplicate by device (total size as proxy)
                device_key = usage.total
                if device_key in seen_devices:
                    continue
                seen_devices.add(device_key)
                disk_spaces.append({
                    "location": "MicroSD Card",
                    "path": sd_path,
                    "free": convert_bytes(usage.free),
                    "free_bytes": usage.free,
                    "total": convert_bytes(usage.total),
                    "total_bytes": usage.total,
                    "used_percent": round((usage.used / usage.total) * 100, 1),
                })
            except Exception:
                pass

    return {
        "Type": "StorageStats",
        "Content": {
            "total_used": convert_bytes(total_used),
            "total_used_bytes": total_used,
            "total_games": sum(s["count"] for s in stores),
            "stores": stores,
            "games": all_games,
            "disk_spaces": disk_spaces,
        }
    }


if __name__ == "__main__":
    runtime_dir = os.environ.get("DECKY_PLUGIN_RUNTIME_DIR", "")
    if not runtime_dir:
        print(json.dumps({
            "Type": "Error",
            "Content": {"Message": "DECKY_PLUGIN_RUNTIME_DIR not set"}
        }))
        sys.exit(1)

    result = get_storage_stats(runtime_dir)
    print(json.dumps(result))
