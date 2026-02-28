#!/usr/bin/env python
import gog
import json
import argparse

import GameSet


class GOGArgs(GameSet.GenericArgs):
    def __init__(self, storeName, setNameConfig):
        super().__init__()
        self.addArguments()
        self.setNameConfig = setNameConfig
        self.storeName = storeName

    def addArguments(self):
        super().addArguments()
        self.parser.add_argument(
            '--list', help='Get list of GOG games', action='store_true')
        self.parser.add_argument(
            '--get-game-dir', help='Get install directory for game')
        self.parser.add_argument(
            '--getprogress', help='Get installation progress for game')
        self.parser.add_argument(
            '--get-args', help='Get game arguments')
        self.parser.add_argument(
            '--launchoptions', nargs=3, help='Get launch options')
        self.parser.add_argument(
            '--getloginstatus', help='Get login status', action='store_true')
        self.parser.add_argument(
            '--get-base64-images', help='Get base64 images for short name'
        )
        self.parser.add_argument(
            '--offline', help='Offline mode', action='store_true')
        self.parser.add_argument(
            '--update-game-details', help='Update game details')
        self.parser.add_argument(
            '--get-game-size', nargs=2, help='Get game size')
        self.parser.add_argument(
            '--flush-cache', help='Flush cache', action='store_true')
        self.parser.add_argument(
            '--get-galaxy-tokens', help='Convert galaxy tokens to gogdl auth format')
        self.parser.add_argument(
            '--process-info-file', help='Process goggame info file to extract exe path')
        self.parser.add_argument(
            '--sync-saves', help='Sync cloud saves for game')
        self.parser.add_argument(
            '--skip-upload', help='Skip uploading saves', action='store_true')
        self.parser.add_argument(
            '--skip-download', help='Skip downloading saves', action='store_true')

    def parseArgs(self):
        super().parseArgs()
        self.gameSet = gog.GOG(self.args.dbfile, self.storeName, self.setNameConfig)
        self.gameSet.create_tables()

    def processArgs(self):
        try:
            super().processArgs()

            if self.args.list:
                print(self.gameSet.get_list(self.args.offline))
            if self.args.get_game_dir:
                self.gameSet.get_game_dir(
                    self.args.get_game_dir)
            if self.args.getprogress:
                print(self.gameSet.get_last_progress_update(
                    self.args.getprogress))
            if self.args.get_args:
                # GOG games don't have separate CLI args like legendary
                # Return empty args or stored args from database
                conn = self.gameSet.get_connection()
                c = conn.cursor()
                c.execute("SELECT Arguments FROM Game WHERE ShortName=?", (self.args.get_args,))
                result = c.fetchone()
                conn.close()
                print(result[0] if result and result[0] else "")
            if self.args.launchoptions:
                print(self.gameSet.get_lauch_options(
                    self.args.launchoptions[0], self.args.launchoptions[1], self.args.launchoptions[2], self.args.offline))

            if self.args.getloginstatus:
                print(self.gameSet.get_login_status(self.args.flush_cache))

            if self.args.get_base64_images:
                print(self.gameSet.get_base64_images(
                    self.args.get_base64_images))
            if self.args.update_game_details:
                self.gameSet.update_game_details(
                    self.args.update_game_details)
            if self.args.get_galaxy_tokens:
                print(self.gameSet.get_galaxy_tokens(
                    self.args.get_galaxy_tokens))
            if self.args.process_info_file:
                self.gameSet.process_info_file(self.args.process_info_file)
            if self.args.get_game_size:
                print(self.gameSet.get_game_size(
                    self.args.get_game_size[0], self.args.get_game_size[1]))
            if self.args.sync_saves:
                self.gameSet.sync_saves(
                    self.args.sync_saves,
                    skip_upload=self.args.skip_upload,
                    skip_download=self.args.skip_download)
            if not any(vars(self.args).values()):
                self.parser.print_help()
        except gog.CmdException as e:
            print(json.dumps(
                {'Type': 'Error', 'Content': {'Message': e.args[0]}}))


def main():
    gogArgs = GOGArgs("GOG", "Proton")
    gogArgs.parseArgs()
    gogArgs.processArgs()


if __name__ == '__main__':
    main()
