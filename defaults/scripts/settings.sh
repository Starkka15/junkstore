#!/usr/bin/env bash

if [[ -z "${DECKY_PLUGIN_DIR}" ]]; then
    export DECKY_PLUGIN_DIR="${HOME}/homebrew/plugins/GameVault"
fi
if [[ -z "${DECKY_PLUGIN_RUNTIME_DIR}" ]]; then
    export DECKY_PLUGIN_RUNTIME_DIR="${HOME}/homebrew/data/GameVault"
fi
if [[ -z "${DECKY_PLUGIN_LOG_DIR}" ]]; then
    export DECKY_PLUGIN_LOG_DIR="${HOME}/homebrew/logs/GameVault"
fi

Extensions="Extensions"







