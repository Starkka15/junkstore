import { ServerAPI, sleep } from "decky-frontend-lib";
import { ContentResult, ContentType, ExecuteGetGameDetailsArgs, ExecuteInstallArgs, GameDetails, GameImages, LaunchOptions, ProgressUpdate } from "../Types/Types";
import { executeAction } from "./executeAction";
import Logger from "./logger";

export interface QueueItem {
    shortname: string;
    title: string;
    initActionSet: string;
    status: "queued" | "downloading" | "installing" | "done" | "error";
    progress: number;
    description: string;
}

export interface QueueState {
    items: QueueItem[];
    isProcessing: boolean;
    currentIndex: number;
}

type QueueListener = (state: QueueState) => void;

const logger = new Logger("InstallQueue");

class InstallQueue {
    private state: QueueState = {
        items: [],
        isProcessing: false,
        currentIndex: -1,
    };
    private listeners: Set<QueueListener> = new Set();
    private serverAPI: ServerAPI | null = null;
    private cancelled = false;

    setServerAPI(api: ServerAPI) {
        this.serverAPI = api;
    }

    subscribe(listener: QueueListener) {
        this.listeners.add(listener);
        listener(this.state);
        return () => this.listeners.delete(listener);
    }

    private notify() {
        const snapshot = { ...this.state, items: [...this.state.items] };
        this.listeners.forEach(l => l(snapshot));
    }

    add(shortname: string, title: string, initActionSet: string) {
        if (this.state.items.some(i => i.shortname === shortname)) return;
        this.state.items.push({
            shortname,
            title,
            initActionSet,
            status: "queued",
            progress: 0,
            description: "Queued",
        });
        this.notify();
    }

    remove(shortname: string) {
        this.state.items = this.state.items.filter(i => i.shortname !== shortname);
        this.notify();
    }

    clear() {
        if (this.state.isProcessing) {
            this.cancelled = true;
        }
        this.state.items = [];
        this.state.isProcessing = false;
        this.state.currentIndex = -1;
        this.notify();
    }

    getState(): QueueState {
        return { ...this.state, items: [...this.state.items] };
    }

    get queuedCount(): number {
        return this.state.items.filter(i => i.status === "queued").length;
    }

    get isProcessing(): boolean {
        return this.state.isProcessing;
    }

    async start() {
        if (!this.serverAPI || this.state.isProcessing) return;
        this.cancelled = false;
        this.state.isProcessing = true;
        this.notify();

        for (let i = 0; i < this.state.items.length; i++) {
            if (this.cancelled) break;

            const item = this.state.items[i];
            if (item.status !== "queued") continue;

            this.state.currentIndex = i;
            await this.processItem(item);
        }

        this.state.isProcessing = false;
        this.state.currentIndex = -1;
        this.notify();
    }

    private async processItem(item: QueueItem) {
        const api = this.serverAPI!;

        // Step 1: Start download
        item.status = "downloading";
        item.description = "Starting download...";
        this.notify();

        try {
            const downloadResult = await executeAction<ExecuteGetGameDetailsArgs, ContentType>(
                api, item.initActionSet, "Download", { shortname: item.shortname }
            );

            if (!downloadResult || downloadResult.Type !== "Progress") {
                item.status = "error";
                item.description = "Failed to start download";
                this.notify();
                return;
            }

            // Step 2: Poll progress
            while (!this.cancelled) {
                await sleep(1500);
                if (this.cancelled) break;

                const progressResult = await executeAction<ExecuteGetGameDetailsArgs, ProgressUpdate>(
                    api, item.initActionSet, "GetProgress", { shortname: item.shortname }
                );

                if (!progressResult) continue;

                const progress = progressResult.Content;
                if (progress.Error) {
                    item.status = "error";
                    item.description = progress.Error;
                    this.notify();
                    return;
                }

                item.progress = progress.Percentage;
                item.description = progress.Description;
                this.notify();

                if (progress.Percentage >= 100) break;
            }

            if (this.cancelled) {
                await executeAction<ExecuteGetGameDetailsArgs, ContentType>(
                    api, item.initActionSet, "CancelInstall", { shortname: item.shortname }
                );
                item.status = "queued";
                item.description = "Cancelled";
                this.notify();
                return;
            }

            // Step 3: Create Steam shortcut and install
            item.status = "installing";
            item.description = "Setting up Steam shortcut...";
            this.notify();

            // Get game details for the name
            const detailsResult = await executeAction<ExecuteGetGameDetailsArgs, GameDetails>(
                api, item.initActionSet, "GetDetails", { shortname: item.shortname }
            );

            if (!detailsResult) {
                item.status = "error";
                item.description = "Failed to get game details";
                this.notify();
                return;
            }

            const gameName = detailsResult.Content.Name;
            const existingId = detailsResult.Content.SteamClientID;

            // Get or create Steam shortcut
            let steamId: number;
            if (existingId && existingId !== "") {
                steamId = parseInt(existingId);
                // @ts-ignore
                const apps = appStore.allApps.filter(app => app.appid === steamId);
                if (apps.length === 0) {
                    steamId = await SteamClient.Apps.AddShortcut("Name", "/bin/bash", "", "");
                }
            } else {
                steamId = await SteamClient.Apps.AddShortcut("Name", "/bin/bash", "", "");
            }

            // @ts-ignore
            await appDetailsCache.FetchDataForApp(steamId);
            await appDetailsStore.RequestAppDetails(steamId);
            SteamClient.Apps.SetShortcutName(steamId, gameName);

            // Call Install action to get launch options
            const installResult = await executeAction<ExecuteInstallArgs, ContentType>(
                api, item.initActionSet, "Install",
                { shortname: item.shortname, steamClientID: steamId.toString() }
            );

            if (installResult && installResult.Type === "LaunchOptions") {
                const launchOptions = installResult.Content as LaunchOptions;
                // @ts-ignore
                await appDetailsCache.FetchDataForApp(steamId);
                await appDetailsStore.RequestAppDetails(steamId);
                SteamClient.Apps.SetAppLaunchOptions(steamId, launchOptions.Options);
                SteamClient.Apps.SetShortcutName(steamId, gameName);
                SteamClient.Apps.SetShortcutExe(steamId, launchOptions.Exe);
                SteamClient.Apps.SetShortcutStartDir(steamId, launchOptions.WorkingDir);

                if (launchOptions.Compatibility) {
                    // @ts-ignore
                    const defaultProton = settingsStore.settings.strCompatTool;
                    if (defaultProton) {
                        SteamClient.Apps.SpecifyCompatTool(steamId, defaultProton);
                    } else {
                        try {
                            // @ts-ignore
                            const compatTools = await SteamClient.Apps.GetAvailableCompatTools(1);
                            const firstAvailable = compatTools.filter((tool: any) =>
                                tool.strToolName.startsWith('proton') &&
                                tool.strToolName.indexOf('experimental') === -1
                            );
                            if (firstAvailable.length > 0) {
                                SteamClient.Apps.SpecifyCompatTool(steamId, firstAvailable[0].CompatToolName);
                            }
                        } catch (e) {
                            logger.error("Error getting compat tools", e);
                        }
                    }
                }
            }

            // Step 4: Set images
            item.description = "Setting up artwork...";
            this.notify();

            const imageResult = await executeAction<ExecuteGetGameDetailsArgs, GameImages>(
                api, item.initActionSet, "GetJsonImages", { shortname: item.shortname }
            );

            if (imageResult) {
                const images = imageResult.Content;
                if (images.Grid) await SteamClient.Apps.SetCustomArtworkForApp(steamId, images.Grid, 'png', 0);
                if (images.Hero) await SteamClient.Apps.SetCustomArtworkForApp(steamId, images.Hero, 'png', 1);
                if (images.Logo) await SteamClient.Apps.SetCustomArtworkForApp(steamId, images.Logo, 'png', 2);
                if (images.GridH) await SteamClient.Apps.SetCustomArtworkForApp(steamId, images.GridH, 'png', 3);
            }

            item.status = "done";
            item.progress = 100;
            item.description = "Installed";
            this.notify();

        } catch (e) {
            logger.error("Error processing queue item", e);
            item.status = "error";
            item.description = `Error: ${e}`;
            this.notify();
        }
    }
}

// Singleton instance
export const installQueue = new InstallQueue();
