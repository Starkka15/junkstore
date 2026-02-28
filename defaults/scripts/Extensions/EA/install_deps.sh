#!/usr/bin/env bash

MAXIMA_BIN="${HOME}/.local/bin/maxima-cli"
MAXIMA_REPO="https://github.com/Starkka15/Maxima"

function uninstall() {
    echo "Uninstalling EA Play dependencies"
    rm -f "${MAXIMA_BIN}" 2>/dev/null
    echo "Removed maxima-cli"
}

function install() {
    echo "Installing EA Play dependencies (maxima-cli)"

    mkdir -p "${HOME}/.local/bin"

    # Check if already installed
    if [[ -f "${MAXIMA_BIN}" ]]; then
        echo "maxima-cli already installed at ${MAXIMA_BIN}"
        return
    fi

    # Try to download pre-built binary from GitHub releases
    RELEASE_URL="${MAXIMA_REPO}/releases/latest/download/maxima-cli-linux-x86_64"
    echo "Trying to download pre-built binary..."
    if curl -sL -o "${MAXIMA_BIN}" "${RELEASE_URL}" 2>/dev/null && [[ -s "${MAXIMA_BIN}" ]]; then
        # Verify it's actually a binary (not an HTML error page)
        if file "${MAXIMA_BIN}" | grep -q "ELF"; then
            chmod +x "${MAXIMA_BIN}"
            echo "maxima-cli installed from pre-built binary"
            return
        fi
        rm -f "${MAXIMA_BIN}"
    fi

    # Fallback: try downloading CI artifact
    echo "No pre-built release found."

    # Fallback: build from source
    if command -v cargo &>/dev/null; then
        echo "Building maxima-cli from source (this may take a while)..."
        TMPDIR=$(mktemp -d)
        git clone "${MAXIMA_REPO}.git" "${TMPDIR}/maxima" 2>/dev/null

        if [[ -d "${TMPDIR}/maxima" ]]; then
            cd "${TMPDIR}/maxima"

            # Need nightly Rust
            if command -v rustup &>/dev/null; then
                rustup toolchain install nightly 2>/dev/null
            fi

            cargo +nightly build --release --bin maxima-cli 2>&1 | tail -5

            if [[ -f "target/release/maxima-cli" ]]; then
                cp "target/release/maxima-cli" "${MAXIMA_BIN}"
                chmod +x "${MAXIMA_BIN}"
                echo "maxima-cli built and installed successfully"
            else
                echo "Build failed. See output above."
            fi

            cd -
            rm -rf "${TMPDIR}"
        else
            echo "Failed to clone repository"
        fi
    else
        echo ""
        echo "Cannot install maxima-cli automatically."
        echo "Please install manually:"
        echo "  1. Install Rust nightly: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        echo "  2. rustup toolchain install nightly"
        echo "  3. git clone ${MAXIMA_REPO}.git"
        echo "  4. cd Maxima && cargo +nightly build --release --bin maxima-cli"
        echo "  5. cp target/release/maxima-cli ~/.local/bin/"
    fi

    # Verify
    if [[ -f "${MAXIMA_BIN}" ]]; then
        echo "maxima-cli: OK"
    else
        echo "maxima-cli: NOT FOUND (EA Play will not work)"
    fi
}

if [ "$1" == "uninstall" ]; then
    echo "Uninstalling dependencies: EA Play extension"
    uninstall
else
    echo "Installing dependencies: EA Play extension"
    install
fi
