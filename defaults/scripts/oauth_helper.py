#!/usr/bin/env python3
"""OAuth helper for Amazon login flow.

Uses nile's --non-interactive mode to get the login URL,
opens a real browser (not Steam overlay) for login,
then uses kdialog/zenity to capture the redirect URL.
"""
import json
import os
import subprocess
import sys


def find_browser():
    """Find a real browser (not Steam overlay). Returns command list or None."""
    # Try Firefox flatpak first (most common on SteamOS)
    try:
        result = subprocess.run(
            ['flatpak', 'list', '--app', '--columns=application'],
            capture_output=True, text=True
        )
        if 'org.mozilla.firefox' in result.stdout:
            return ['flatpak', 'run', 'org.mozilla.firefox']
    except FileNotFoundError:
        pass

    # Try system Firefox
    for browser in ['firefox', 'chromium', 'chromium-browser', 'google-chrome']:
        try:
            subprocess.run(['which', browser], capture_output=True, check=True)
            return [browser]
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue

    return None


def open_url(url):
    """Open URL in a real browser, falling back to xdg-open."""
    browser = find_browser()
    if browser:
        print(f"Opening URL in {browser[0]}...")
        subprocess.Popen(browser + [url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        print("Opening URL with xdg-open...")
        subprocess.Popen(['xdg-open', url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def show_dialog(title, message):
    """Show a dialog to get user input. Tries kdialog, then zenity, then terminal."""
    # Try kdialog (KDE/SteamOS)
    try:
        result = subprocess.run(
            ['kdialog', '--title', title, '--inputbox', message],
            capture_output=True, text=True, timeout=300
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    # Try zenity (GNOME)
    try:
        result = subprocess.run(
            ['zenity', '--entry', '--title', title, '--text', message,
             '--width', '500'],
            capture_output=True, text=True, timeout=300
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    # Fallback: terminal input
    try:
        return input(message + "\n> ").strip()
    except EOFError:
        return None


def extract_code_from_url(url, param_name):
    """Extract a query parameter from a URL."""
    from urllib.parse import urlparse, parse_qs
    try:
        parsed = urlparse(url)
        params = parse_qs(parsed.query)
        codes = params.get(param_name, [])
        return codes[0] if codes else None
    except Exception:
        return None


def amazon_login(nile_bin):
    """Handle Amazon two-step device registration login flow."""
    # Step 1: Get login data from nile
    print("Getting Amazon login data...")
    result = subprocess.run(
        [nile_bin, 'auth', '--login', '--non-interactive'],
        capture_output=True, text=True
    )

    login_data = None
    for output in [result.stdout, result.stderr]:
        try:
            login_data = json.loads(output.strip())
            if login_data.get('url'):
                break
        except (json.JSONDecodeError, ValueError):
            continue

    if not login_data or not login_data.get('url'):
        print(f"Failed to get login data from nile", file=sys.stderr)
        print(f"stdout: {result.stdout}", file=sys.stderr)
        print(f"stderr: {result.stderr}", file=sys.stderr)
        return False

    login_url = login_data['url']
    code_verifier = login_data.get('code_verifier', '')
    serial = login_data.get('serial', '')
    client_id = login_data.get('client_id', '')

    # Open in a real browser (Firefox) instead of Steam overlay
    open_url(login_url)

    user_input = show_dialog(
        "Amazon Games Login",
        "1. Log in to Amazon in the browser window\n"
        "2. Complete any 2FA/verification steps\n"
        "3. After redirect, copy the URL from the address bar\n"
        "   (tap the address bar, Select All, Copy)\n"
        "4. Paste it here and click OK"
    )

    if not user_input:
        print("No input received", file=sys.stderr)
        return False

    # Extract the authorization code from the URL
    code = extract_code_from_url(user_input, 'openid.oa2.authorization_code')
    if not code:
        # Maybe they pasted just the code
        code = user_input.strip()

    if not code:
        print("Could not extract authorization code", file=sys.stderr)
        return False

    print("Got authorization code, completing registration...")
    cmd = [
        nile_bin, 'register',
        '--code', code,
        '--code-verifier', code_verifier,
        '--serial', serial,
        '--client-id', client_id
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    return True


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} amazon <nile_binary_path>")
        sys.exit(1)

    store = sys.argv[1]
    binary = sys.argv[2]

    if store == 'amazon':
        success = amazon_login(binary)
    else:
        print(f"Unknown store: {store}", file=sys.stderr)
        sys.exit(1)

    sys.exit(0 if success else 1)
