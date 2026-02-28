import datetime
import re
import json
import os
import sqlite3
import sys
import subprocess
import time
import urllib.request

import GamesDb
from datetime import datetime, timedelta


class CmdException(Exception):
    pass


class GOG(GamesDb.GamesDb):
    def __init__(self, db_file, storeName, setNameConfig=None):
        super().__init__(db_file, storeName=storeName, setNameConfig=setNameConfig)
        self.storeURL = "https://www.gog.com/"

    lgogdl_cmd = os.environ.get('LGOGDL', '/bin/flatpak run com.github.sude_.lgogdownloader')
    gogdl_cmd = os.environ.get('GOGDL', '/bin/flatpak run com.github.heroic_games_launcher.heroic-gogdl')
    auth_tokens = os.environ.get('AUTH_TOKENS', os.path.expanduser('~/homebrew/data/Junk-Store/gog_auth.json'))

    def execute_shell(self, cmd):
        result = subprocess.Popen(cmd, stdout=subprocess.PIPE, stdin=subprocess.PIPE,
                                  stderr=subprocess.PIPE,
                                  shell=True).communicate()[0].decode()

        if result.strip() == "":
            raise CmdException(f"Command produced no output (try installing dependencies from the About menu): {cmd}")
        return result

    def execute_shell_json(self, cmd):
        result = self.execute_shell(cmd)
        return json.loads(result)

    def get_list(self, offline=False):
        # Use lgogdownloader for library listing (like the official extension)
        games_list = self.execute_shell_json(
            f"{self.lgogdl_cmd} --list=j --info-threads=40")
        id_list = []
        game_dict = {}
        for game in games_list:
            # lgogdownloader format: product_id and gamename
            game_id = str(game.get('product_id', game.get('id', '')))
            id_list.append(game_id)
            game_dict[game_id] = game.get('gamename', '')

        left_overs = self.insert_data(id_list)
        print(f"left_overs: {left_overs}", file=sys.stderr)
        for game_id in left_overs:
            gamename = game_dict.get(game_id, '')
            self.proccess_leftovers_simple(game_id, gamename)

    def proccess_leftovers_simple(self, game_id, gamename):
        """Process games from lgogdownloader --list=j format (product_id + gamename)."""
        print(f"Processing leftover GOG game: {gamename} ({game_id})", file=sys.stderr)
        conn = self.get_connection()
        c = conn.cursor()

        try:
            shortname = str(game_id)
            c.execute("SELECT id FROM Game WHERE ShortName=?", (shortname,))
            result = c.fetchone()
            if result is None:
                vals = [
                    gamename, "", "", "", "", "", "GOG",
                    game_id, "", "", "", "",
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
            print(f"Error inserting GOG game: {gamename} {e}", file=sys.stderr)

        conn.close()

    def process_info_file(self, file_path):
        """Parse goggame-{id}.info to extract exe path, args, working dir and store in DB."""
        print(f"Processing info file: {file_path}", file=sys.stderr)
        conn = self.get_connection()
        c = conn.cursor()
        file_path = os.path.realpath(os.path.join(os.environ['INSTALL_DIR'], file_path))
        print(f"File path: {file_path}", file=sys.stderr)
        with open(file_path, 'r') as f:
            data = json.load(f)
            exe_file = ""
            args = ""
            working_dir = ""
            for task in data['playTasks']:
                if ('category' in task and task['category'] == 'game') or ('isPrimary' in task and task['isPrimary']):
                    exe_file = task['path']
                    if task.get('arguments'):
                        args = task['arguments']
                    if task.get('workingDir'):
                        working_dir = task['workingDir']
                    break
            print(f"Exe file: {exe_file}", file=sys.stderr)
            root_dir = os.path.abspath(os.path.dirname(file_path))
            print(f"Root dir: {root_dir}", file=sys.stderr)
            game_id = data['gameId']

            print(f"Game id: {game_id}", file=sys.stderr)
            c.execute("update Game set ApplicationPath = ?, RootFolder = ?, Arguments =?, WorkingDir =? where DatabaseID = ?", (exe_file, root_dir, args, working_dir, game_id))
            conn.commit()

        conn.close()

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
            install_dir = os.environ.get('INSTALL_DIR', os.path.expanduser('~/Games/gog/'))
            print(os.path.join(install_dir, game_id))

    def get_login_status(self, flush_cache=False):
        cache_key = "gog-login"
        if flush_cache:
            self.clear_cache(cache_key)

        cache = self.get_cache(cache_key)
        print(f"cache: {cache}", file=sys.stderr)
        if cache is not None:
            return cache
        print(f"cache miss!", file=sys.stderr)

        # Check if auth tokens file exists and has valid tokens
        if os.path.exists(self.auth_tokens):
            try:
                with open(self.auth_tokens, 'r') as f:
                    auth_data = json.load(f)
                # Auth tokens format: {client_id: {access_token, refresh_token, ...}}
                has_tokens = False
                access_token = None
                if isinstance(auth_data, dict):
                    for key, val in auth_data.items():
                        if isinstance(val, dict) and (val.get('access_token') or val.get('refresh_token')):
                            has_tokens = True
                            access_token = val.get('access_token')
                            break
                if has_tokens:
                    username = 'GOG User'
                    if access_token:
                        try:
                            req = urllib.request.Request(
                                'https://embed.gog.com/userData.json',
                                headers={'Authorization': f'Bearer {access_token}'})
                            resp = urllib.request.urlopen(req, timeout=5)
                            user_data = json.loads(resp.read())
                            username = user_data.get('username', username)
                        except Exception:
                            pass
                    value = json.dumps({'Type': 'LoginStatus', 'Content': {'Username': username, 'LoggedIn': True}})
                else:
                    value = json.dumps({'Type': 'LoginStatus', 'Content': {'Username': '', 'LoggedIn': False}})
            except Exception:
                value = json.dumps({'Type': 'LoginStatus', 'Content': {'Username': '', 'LoggedIn': False}})
        else:
            value = json.dumps({'Type': 'LoginStatus', 'Content': {'Username': '', 'LoggedIn': False}})

        timeout = datetime.now() + timedelta(hours=1)
        try:
            self.add_cache(cache_key, value, timeout)
        except Exception as e:
            print(f"Error adding cache: {e}", file=sys.stderr)
        return value

    def get_galaxy_tokens(self, path):
        """Convert lgogdownloader galaxy tokens to gogdl auth format."""
        with open(path, 'r') as f:
            data = json.load(f)
            tokens = {}

            tokens["access_token"] = data['access_token']
            tokens["expires_in"] = data['expires_in']
            tokens["token_type"] = data['token_type']
            tokens["scope"] = data['scope']
            tokens["session_id"] = data['session_id']
            tokens["refresh_token"] = data['refresh_token']
            tokens["user_id"] = data['user_id']
            tokens["loginTime"] = data['expires_at'] - data['expires_in']
            client_id = 46899977096215655
            if 'client_id' in data:
                client_id = data['client_id']

            return json.dumps({client_id: tokens})

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
            try:
                result = self.execute_shell_json(
                    f"{self.gogdl_cmd} --auth-config-path {self.auth_tokens} info {game_id} --os windows")
                disk_size = result.get('disk_size', result.get('size', 0))
                download_size = result.get('download_size', 0)
                if disk_size:
                    disk_size_str = f"Install Size: {self.convert_bytes(int(disk_size))}"
                    download_size_str = f"Download Size: {self.convert_bytes(int(download_size))}" if download_size else ""
                    size = disk_size_str + (f" ({download_size_str})" if download_size_str else "")
                else:
                    size = ""
            except Exception:
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
            install_dir = os.environ.get('INSTALL_DIR', os.path.expanduser('~/Games/gog/'))
            game_exe = ""
            working_dir = os.path.join(install_dir, game_id) if install_dir else ""

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
        conn = self.get_connection()
        c = conn.cursor()
        c.execute("SELECT * FROM Game WHERE ShortName=?", (game_id,))
        result = c.fetchone()
        if result is not None:
            try:
                info = self.execute_shell_json(
                    f"{self.gogdl_cmd} --auth-config-path {self.auth_tokens} info {game_id} --os windows")
                title = info.get('title', '')
                disk_size = info.get('disk_size', info.get('size', 0))
                install_path = info.get('install_path', info.get('folder_name', ''))
                size = self.convert_bytes(int(disk_size)) if disk_size else None
                if title:
                    c.execute(
                        "UPDATE Game SET Title=?, Size=?, InstallPath=? WHERE ShortName=?",
                        (title, size, install_path, game_id))
                conn.commit()
            except Exception as e:
                print(f"Error updating GOG game details: {e}", file=sys.stderr)
        conn.close()

    def get_client_id(self, game_id):
        """Get the Galaxy clientId for a game from the GOG builds API manifest.

        This is the same approach gogdl uses internally (saves.py get_auth_ids).
        """
        try:
            builds_url = f"https://content-system.gog.com/products/{game_id}/os/windows/builds?generation=2"
            req = urllib.request.Request(builds_url, headers={'User-Agent': 'Mozilla/5.0'})
            response = urllib.request.urlopen(req, timeout=10)
            builds = json.loads(response.read())

            meta_url = builds['items'][0]['link']
            req = urllib.request.Request(meta_url, headers={'User-Agent': 'Mozilla/5.0'})
            response = urllib.request.urlopen(req, timeout=10)
            import zlib
            data = zlib.decompress(response.read())
            meta = json.loads(data)
            return meta.get('clientId')
        except Exception as e:
            print(f"Error getting clientId from builds API: {e}", file=sys.stderr)
            return None

    def get_save_paths(self, game_id):
        """Query GOG remote config API for cloud save locations, resolve against Steam prefix."""
        conn = self.get_connection()
        c = conn.cursor()
        c.execute("SELECT SteamClientID, RootFolder FROM Game WHERE ShortName=?", (game_id,))
        result = c.fetchone()
        conn.close()

        if not result or not result[0]:
            return []

        steam_client_id = result[0]
        root_folder = result[1] or ''
        prefix = os.path.expanduser(
            f"~/.local/share/Steam/steamapps/compatdata/{steam_client_id}/pfx")

        # Try goggame-{id}.info first (fast, local), then builds API (network)
        client_id = None
        info_file = os.path.join(root_folder, f'goggame-{game_id}.info')
        if os.path.exists(info_file):
            try:
                with open(info_file) as f:
                    info = json.load(f)
                    client_id = info.get('clientId')
            except Exception as e:
                print(f"Error reading info file: {e}", file=sys.stderr)

        if not client_id:
            client_id = self.get_client_id(game_id)

        if not client_id:
            print(f"Could not determine clientId for game {game_id}", file=sys.stderr)
            return []

        # Query GOG remote config for save locations
        try:
            url = f"https://remote-config.gog.com/components/galaxy_client/clients/{client_id}?component_version=2.0.45"
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            response = urllib.request.urlopen(req, timeout=10)
            config = json.loads(response.read())
        except Exception as e:
            print(f"Error querying GOG remote config: {e}", file=sys.stderr)
            return []

        # API returns 'Windows' (capital W)
        saves_info = config.get('content', {}).get('Windows', {}).get('cloudStorage', {})
        locations = saves_info.get('locations', [])

        if not locations:
            print(f"No cloud save locations for game {game_id}", file=sys.stderr)
            return []

        # Map GOG folder variables to paths inside the Steam prefix
        folder_map = {
            'INSTALL': root_folder,
            'APPLICATION_DATA_LOCAL': os.path.join(prefix, 'drive_c/users/steamuser/AppData/Local'),
            'APPLICATION_DATA_LOCAL_LOW': os.path.join(prefix, 'drive_c/users/steamuser/AppData/LocalLow'),
            'APPLICATION_DATA_ROAMING': os.path.join(prefix, 'drive_c/users/steamuser/AppData/Roaming'),
            'SAVED_GAMES': os.path.join(prefix, 'drive_c/users/steamuser/Saved Games'),
            'DOCUMENTS': os.path.join(prefix, 'drive_c/users/steamuser/Documents'),
        }

        resolved = []
        for loc in locations:
            # API uses 'location' field with <?VAR?> syntax
            path_template = loc.get('location', loc.get('path', ''))
            name = loc.get('name', '__default')

            # Replace <?VAR_NAME?> folder variable placeholders
            resolved_path = path_template
            for var_name, var_path in folder_map.items():
                placeholder = f'<?{var_name}?>'
                if placeholder in resolved_path:
                    resolved_path = resolved_path.replace(placeholder, var_path)
                    break
                # Also handle bare variable prefix (no <? ?> wrapper)
                if resolved_path.startswith(var_name):
                    resolved_path = resolved_path.replace(var_name, var_path, 1)
                    break

            # Convert backslashes to forward slashes
            resolved_path = resolved_path.replace('\\', '/')
            resolved.append({'name': name, 'path': resolved_path})

        return resolved

    def sync_saves(self, game_id, skip_upload=False, skip_download=False):
        """Orchestrate gogdl save-sync for each save location."""
        locations = self.get_save_paths(game_id)
        if not locations:
            print(f"No save locations found for game {game_id}", file=sys.stderr)
            return

        for loc in locations:
            cmd = (f'{self.gogdl_cmd} --auth-config-path "{self.auth_tokens}" save-sync '
                   f'"{loc["path"]}" {game_id} --os windows --ts 0 --name {loc["name"]}')
            if skip_upload:
                cmd += ' --skip-upload'
            if skip_download:
                cmd += ' --skip-download'
            print(f"Running save sync: {cmd}", file=sys.stderr)
            subprocess.run(cmd, shell=True)

    # Actual gogdl progress format (multiline):
    # = Progress: 45.67 500/1200, Running for: 00:15:30, ETA: 00:20:00
    # [PROGRESS] INFO: = Downloaded: 450.50 MiB, Written: 450.50 MiB
    # + Download - 45.50 MiB/s (raw: ...)

    def get_last_progress_update(self, file_path):
        progress_re = re.compile(
            r"= Progress: (\d+\.\d+) (\d+)/(\d+), Running for: (\d+:\d+:\d+), ETA: (\d+:\d+:\d+)\n\[PROGRESS\] INFO: = Downloaded: (\d+\.\d+) MiB, Written: (\d+\.\d+) MiB")
        speed_re = re.compile(r"\+ Download.*- (\d+\.\d+) (.*/s) \(raw")
        last_progress_update = None

        try:
            with open(file_path, "r") as f:
                lines = f.readlines()

                for i in range(len(lines) - 5):
                    if match := progress_re.search(''.join(lines[i: i + 6])):
                        downloaded = round(float(match.group(2)), 2)
                        total_dl_size = round(float(match.group(3)), 2)
                        speed = "0.0"
                        if match2 := speed_re.search(''.join(lines[i: i + 6])):
                            speed = f"{round(float(match2.group(1)), 2)} {match2.group(2)}"

                        percent = round(float(match.group(1)), 0)
                        if percent == 100:
                            percent = 99
                        if match.group(2) == match.group(3):
                            percent = 100
                        last_progress_update = {
                            "Percentage": percent,
                            "Description": f"Downloaded {self.convert_bytes(downloaded)}/{self.convert_bytes(total_dl_size)} ({percent}%)\nSpeed: {speed}"
                        }

                if lines:
                    if lines[-1].strip().startswith("[PROGRESS] INFO: Finished installation process"):
                        last_progress_update = {
                            "Percentage": 100,
                            "Description": "Finished installation process"
                        }
                    if lines[-1].strip().endswith("INFO: Nothing to do"):
                        last_progress_update = {
                            "Percentage": 100,
                            "Description": "Nothing to do. Exiting..."
                        }
                    if any(line.strip().endswith("INFO: All files look good") for line in lines[-2:]):
                        last_progress_update = {
                            "Percentage": 100,
                            "Description": "Verification finished successfully."
                        }
                    if any(line.strip().endswith("Unable to proceed. Not enough disk space") for line in lines[-2:]):
                        try:
                            with open(file_path.replace(".progress", ".output"), "r") as f:
                                content = f.readlines()
                            content = '<br />'.join(content)
                        except Exception:
                            content = "Installation Failed. Reason unknown, check logs for details."
                        last_progress_update = {
                            "Percentage": 0,
                            "Description": "Installation Failed.",
                            "Error": content
                        }

                    if last_progress_update is None:
                        last_progress_update = {
                            "Percentage": 0,
                            "Description": lines[-1].strip()
                        }
        except Exception as e:
            print("Waiting for progress update", e, file=sys.stderr)
            time.sleep(1)

        return json.dumps({'Type': 'ProgressUpdate', 'Content': last_progress_update})
