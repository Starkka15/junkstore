import json
import sys
import urllib.request
import urllib.parse


class SteamGridDB:
    BASE_URL = "https://www.steamgriddb.com/api/v2"
    PLATFORM_MAP = {"gog": "gog", "epic": "egs", "itchio": "itch"}

    # Maps SGDB endpoint → Images table Type
    IMAGE_ENDPOINTS = {
        "grids": {"params": "dimensions=600x900&types=static", "type": "vertical_cover"},
        "heroes": {"params": "types=static", "type": "horizontal_artwork"},
        "logos": {"params": "types=static", "type": "logo"},
        "icons": {"params": "types=static", "type": "square_icon"},
    }

    def __init__(self, api_key):
        self.api_key = api_key

    def _request(self, endpoint):
        url = f"{self.BASE_URL}/{endpoint}"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "User-Agent": "GameVault/1.0",
        }
        req = urllib.request.Request(url, headers=headers)
        try:
            response = urllib.request.urlopen(req, timeout=15)
            data = json.loads(response.read())
            if data.get("success"):
                return data.get("data", [])
        except Exception as e:
            print(f"SteamGridDB API error ({endpoint}): {e}", file=sys.stderr)
        return None

    def find_game(self, store_name, game_id, game_name):
        """Find a game on SGDB. Tries platform ID first, falls back to name search."""
        platform = self.PLATFORM_MAP.get(store_name)
        if platform and game_id:
            encoded_id = urllib.parse.quote(str(game_id), safe="")
            data = self._request(f"games/by-platform-id?platform={platform}&id={encoded_id}")
            if data and len(data) > 0:
                sgdb_id = data[0].get("id")
                if sgdb_id:
                    print(f"SteamGridDB: found game by platform {platform}/{game_id} → {sgdb_id}", file=sys.stderr)
                    return sgdb_id

        # Fallback: search by name
        if game_name:
            encoded_name = urllib.parse.quote(game_name, safe="")
            data = self._request(f"search/autocomplete/{encoded_name}")
            if data and len(data) > 0:
                sgdb_id = data[0].get("id")
                if sgdb_id:
                    print(f"SteamGridDB: found game by name '{game_name}' → {sgdb_id}", file=sys.stderr)
                    return sgdb_id

        print(f"SteamGridDB: no match for {store_name}/{game_id} '{game_name}'", file=sys.stderr)
        return None

    def get_images(self, sgdb_game_id):
        """Fetch image URLs for all slots. Returns {type: url} dict."""
        result = {}
        for endpoint, info in self.IMAGE_ENDPOINTS.items():
            data = self._request(f"{endpoint}/game/{sgdb_game_id}?{info['params']}")
            if data and len(data) > 0:
                url = data[0].get("url")
                if url:
                    result[info["type"]] = url
        return result
