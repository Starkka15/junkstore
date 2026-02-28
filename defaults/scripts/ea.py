import datetime
import re
import json
import os
import sqlite3
import sys
import subprocess
import time

import GamesDb
from datetime import datetime, timedelta


class CmdException(Exception):
    pass


class EA(GamesDb.GamesDb):
    def __init__(self, db_file, storeName, setNameConfig=None):
        super().__init__(db_file, storeName=storeName, setNameConfig=setNameConfig)
        self.storeURL = "https://www.ea.com/ea-play"

    maxima_cmd = os.environ.get('MAXIMA_CMD', os.path.expanduser('~/.local/bin/maxima-cli'))
    _ansi_re = re.compile(r'\x1b\[[0-9;]*m')

    def _strip_ansi(self, text):
        return self._ansi_re.sub('', text)

    def execute_shell(self, cmd):
        env = os.environ.copy()
        env['NO_COLOR'] = '1'
        result = subprocess.Popen(cmd, stdout=subprocess.PIPE, stdin=subprocess.PIPE,
                                  stderr=subprocess.PIPE,
                                  shell=True, env=env).communicate()
        stdout = result[0].decode()
        stderr = result[1].decode()
        # maxima-cli outputs most things via log crate to stderr
        combined = self._strip_ansi(stdout + stderr)
        if combined.strip() == "":
            raise CmdException(f"Command produced no output: {cmd}")
        return combined

    def execute_shell_stdout(self, cmd):
        env = os.environ.copy()
        env['NO_COLOR'] = '1'
        result = subprocess.Popen(cmd, stdout=subprocess.PIPE, stdin=subprocess.PIPE,
                                  stderr=subprocess.PIPE,
                                  shell=True, env=env).communicate()
        return self._strip_ansi(result[0].decode())

    def _parse_list_games_output(self, output):
        """Parse maxima-cli list-games output into a list of game dicts.
        Format: <slug> - <name> - <offer_id> - Installed: true/false
        Lines may have a log prefix like [INFO  maxima_cli]
        """
        games = []
        # Match lines with the game listing pattern
        pattern = re.compile(
            r'(\S+)\s+- (.+?)\s+- ([\w.:\-]+)\s+- Installed: (true|false)',
            re.IGNORECASE
        )
        for line in output.split('\n'):
            match = pattern.search(line)
            if match:
                slug = match.group(1).strip()
                name = match.group(2).strip()
                offer_id = match.group(3).strip()
                installed = match.group(4).lower() == 'true'
                # Skip extra offer lines (indented, no Installed field - already filtered)
                if slug and name and offer_id:
                    games.append({
                        'slug': slug,
                        'name': name,
                        'offer_id': offer_id,
                        'installed': installed
                    })
        return games

    def get_list(self, offline=False):
        """Fetch owned games from EA via maxima-cli and populate database."""
        try:
            output = self.execute_shell(f"{self.maxima_cmd} list-games")
        except CmdException:
            raise CmdException("Failed to list EA games. Is maxima-cli installed and are you logged in?")

        games = self._parse_list_games_output(output)
        print(f"Found {len(games)} EA games", file=sys.stderr)

        # Use slugs as game IDs for GamesDb lookup
        id_list = [g['offer_id'] for g in games]
        game_dict = {g['offer_id']: g for g in games}

        left_overs = self.insert_data(id_list)
        print(f"left_overs: {left_overs}", file=sys.stderr)

        for offer_id in left_overs:
            if offer_id in game_dict:
                self.proccess_leftovers(game_dict[offer_id])

    def proccess_leftovers(self, game_data):
        """Insert game from maxima-cli data that wasn't found in GamesDb."""
        title = game_data.get('name', 'Unknown')
        print(f"Processing leftover EA game: {title}", file=sys.stderr)
        conn = self.get_connection()
        c = conn.cursor()

        try:
            slug = game_data.get('slug', '')
            offer_id = game_data.get('offer_id', '')
            shortname = slug  # Use slug as ShortName for EA games

            c.execute("SELECT * FROM Game WHERE ShortName=?", (shortname,))
            result = c.fetchone()
            if result is None:
                vals = [
                    title, "", "", "", "", "", "EA",
                    offer_id, "", "", "", "",
                    "", "", "", "", shortname,
                ]
                cols_with_pk = [
                    "Title", "Notes", "ApplicationPath", "ManualPath",
                    "Publisher", "RootFolder", "Source", "DatabaseID",
                    "Genre", "ConfigurationPath", "Developer", "ReleaseDate",
                    "Size", "InstallPath", "UmuId", "SteamClientID", "ShortName"
                ]
                placeholders = ', '.join(['?' for _ in range(len(cols_with_pk))])
                tmp = f"INSERT INTO Game ({', '.join(cols_with_pk)}) VALUES ({placeholders})"
                c.execute(tmp, vals)
                conn.commit()
        except Exception as e:
            print(f"Error parsing metadata for EA game: {title} {e}", file=sys.stderr)

        conn.close()

    def download_game(self, slug, install_dir):
        """Download a game via maxima-cli install command."""
        print(f"Downloading EA game: {slug}", file=sys.stderr)

        game_path = os.path.join(install_dir, slug)
        os.makedirs(game_path, exist_ok=True)

        # maxima-cli install <slug> --path <dir>
        # Progress goes to stderr, we redirect it
        cmd = f"{self.maxima_cmd} install {slug} --path \"{game_path}\""
        process = subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            shell=True
        )
        stdout, stderr = process.communicate()

        output = stderr.decode() + stdout.decode()
        print(output, file=sys.stderr)

        if process.returncode != 0:
            raise CmdException(f"Failed to install EA game {slug}")

        # Update database with install path
        conn = self.get_connection()
        c = conn.cursor()
        c.execute("UPDATE Game SET RootFolder=?, InstallPath=? WHERE ShortName=?",
                  (game_path, game_path, slug))
        conn.commit()
        conn.close()

    def download_game_async(self, slug, install_dir):
        """Start downloading a game in the background, writing progress to stderr."""
        game_path = os.path.join(install_dir, slug)
        os.makedirs(game_path, exist_ok=True)

        cmd = f"{self.maxima_cmd} install {slug} --path \"{game_path}\""

        # Update database with install path now so get_game_dir works
        conn = self.get_connection()
        c = conn.cursor()
        c.execute("UPDATE Game SET RootFolder=?, InstallPath=? WHERE ShortName=?",
                  (game_path, game_path, slug))
        conn.commit()
        conn.close()

        # Execute and let caller redirect stderr to progress file
        os.execvp("sh", ["sh", "-c", cmd])

    def get_game_dir(self, game_id):
        conn = self.get_connection()
        c = conn.cursor()
        c.execute("SELECT RootFolder, InstallPath FROM Game WHERE ShortName=?", (game_id,))
        result = c.fetchone()
        conn.close()
        if result and result[0]:
            print(result[0])
        elif result and result[1]:
            print(result[1])
        else:
            install_dir = os.environ.get('INSTALL_DIR', os.path.expanduser('~/Games/ea/'))
            print(os.path.join(install_dir, game_id))

    def get_login_status(self, flush_cache=False):
        cache_key = "ea-login"
        if flush_cache:
            self.clear_cache(cache_key)

        cache = self.get_cache(cache_key)
        print(f"cache: {cache}", file=sys.stderr)
        if cache is not None:
            return cache
        print(f"cache miss!", file=sys.stderr)

        # Check if maxima auth.toml exists
        auth_file = os.path.expanduser('~/.local/share/maxima/auth.toml')
        if os.path.exists(auth_file):
            try:
                # Try to get account info
                output = self.execute_shell(f"{self.maxima_cmd} account-info")
                # Parse username from output
                username = "EA User"
                for line in output.split('\n'):
                    if 'Username:' in line:
                        username = line.split('Username:')[-1].strip()
                        break
                    elif 'Logged in as' in line:
                        match = re.search(r'Logged in as (.+?)!', line)
                        if match:
                            username = match.group(1)
                        break
                value = json.dumps({'Type': 'LoginStatus', 'Content': {'Username': username, 'LoggedIn': True}})
            except Exception as e:
                print(f"Account info failed: {e}", file=sys.stderr)
                value = json.dumps({'Type': 'LoginStatus', 'Content': {'Username': '', 'LoggedIn': False}})
        else:
            value = json.dumps({'Type': 'LoginStatus', 'Content': {'Username': '', 'LoggedIn': False}})

        timeout = datetime.now() + timedelta(hours=1)
        try:
            self.add_cache(cache_key, value, timeout)
        except Exception as e:
            print(f"Error adding cache: {e}", file=sys.stderr)
        return value

    def get_game_size(self, game_id, installed):
        if installed == 'true':
            conn = self.get_connection()
            c = conn.cursor()
            c.row_factory = sqlite3.Row
            c.execute("SELECT Size FROM Game WHERE ShortName=?", (game_id,))
            result = c.fetchone()
            conn.close()
            if result and bool(result['Size']):
                disk_size = result['Size']
                size = f"Size on Disk: {disk_size}"
            else:
                size = ""
        else:
            size = ""
        return json.dumps({'Type': 'GameSize', 'Content': {'Size': size}})

    def get_lauch_options(self, game_id, steam_command, name, offline=False):
        launcher = os.environ['LAUNCHER']
        script_path = os.path.expanduser(launcher)

        conn = self.get_connection()
        c = conn.cursor()
        c.row_factory = sqlite3.Row
        c.execute("SELECT ApplicationPath, RootFolder, WorkingDir FROM Game WHERE ShortName=?", (game_id,))
        game = c.fetchone()
        conn.close()

        if game and game['RootFolder'] and game['ApplicationPath']:
            root_dir = game['RootFolder']
            working_dir = os.path.join(root_dir, game['WorkingDir']).replace("\\", "/") if game['WorkingDir'] else root_dir
            game_exe = os.path.join(root_dir, game['ApplicationPath']).replace("\\", "/")
        else:
            install_dir = os.environ.get('INSTALL_DIR', os.path.expanduser('~/Games/ea/'))
            game_exe = ""
            working_dir = os.path.join(install_dir, game_id) if install_dir else ""

        # EA games are always Windows (Proton)
        return json.dumps(
            {
                'Type': 'LaunchOptions',
                'Content':
                {
                    'Exe': f"\"{game_exe}\"" if game_exe else "\"\"",
                    'Options': f"{script_path} {game_id}%command%",
                    'WorkingDir': f"\"{working_dir}\"" if working_dir else "",
                    'Compatibility': True,
                    'Name': name
                }
            })

    def update_game_details(self, game_id):
        """Update game details from maxima-cli."""
        # maxima-cli doesn't have a detailed info command yet
        # game-info gives us basic info
        try:
            output = self.execute_shell_stdout(f"{self.maxima_cmd} game-info {game_id}")
            if output.strip():
                data = json.loads(output.strip())
                conn = self.get_connection()
                c = conn.cursor()
                c.execute("UPDATE Game SET Title=? WHERE ShortName=?",
                          (data.get('name', ''), game_id))
                conn.commit()
                conn.close()
        except Exception as e:
            print(f"Error updating EA game details: {e}", file=sys.stderr)

    def get_last_progress_update(self, file_path):
        """Parse maxima-cli install progress output.
        Format (via log crate):
        Progress: XX.XX
        Downloaded: XX.XX MiB
        Total: XX.XX MiB
        Download Complete
        """
        progress_re = re.compile(r"Progress: (\d+\.?\d*)")
        downloaded_re = re.compile(r"Downloaded: (\S+) MiB")
        total_re = re.compile(r"Total: (\S+) MiB")
        last_progress_update = None

        try:
            with open(file_path, "r") as f:
                lines = f.readlines()

                percent = None
                downloaded = ""
                total = ""

                for line in reversed(lines):
                    if percent is None:
                        if match := progress_re.search(line):
                            percent = float(match.group(1))
                    if not downloaded:
                        if match := downloaded_re.search(line):
                            downloaded = match.group(1)
                    if not total:
                        if match := total_re.search(line):
                            total = match.group(1)
                    if percent is not None and downloaded and total:
                        break

                # Check recent lines for completion/error messages
                is_complete = False
                is_error = False
                error_line = ""
                if lines:
                    for line in lines[-5:]:
                        ll = line.strip().lower()
                        if "download complete" in ll or "install finished" in ll or "finished" in ll:
                            is_complete = True
                            break
                        if "error" in ll or "failed" in ll or "bail" in ll:
                            is_error = True
                            error_line = line.strip()

                if is_complete:
                    last_progress_update = {
                        "Percentage": 100,
                        "Description": "Installation complete"
                    }
                elif percent is not None:
                    if percent >= 100:
                        percent = 99
                    desc = f"Downloaded {downloaded} / {total} MiB ({percent:.1f}%)"
                    last_progress_update = {
                        "Percentage": percent,
                        "Description": desc
                    }
                elif is_error:
                    last_progress_update = {
                        "Percentage": 0,
                        "Description": "Installation Failed.",
                        "Error": error_line
                    }
                elif lines:
                    last_progress_update = {
                        "Percentage": 0,
                        "Description": lines[-1].strip()
                    }
        except Exception as e:
            print("Waiting for progress update", e, file=sys.stderr)
            time.sleep(1)

        return json.dumps({'Type': 'ProgressUpdate', 'Content': last_progress_update})
