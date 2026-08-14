#!/usr/bin/env bash
set -euo pipefail

EIMZO_VERSION="6.4.7"
EIMZO_URL="https://dls.soliq.uz/v${EIMZO_VERSION}/E-IMZO-v${EIMZO_VERSION}.tar.gz"

EIMZO_DIR="$HOME/Applications/e-imzo"
EIMZO_JAR="$EIMZO_DIR/E-IMZO.jar"
EIMZO_CERT="$EIMZO_DIR/E-IMZO.pem"

DSKEYS_DIR="$HOME/DSKEYS"
MEDIA_DIR="/media/$USER"
DSKEYS_LINK="$MEDIA_DIR/DSKEYS"

LOCAL_BIN="$HOME/.local/bin"
APPLICATIONS_DIR="$HOME/.local/share/applications"
AUTOSTART_DIR="$HOME/.config/autostart"

LAUNCHER="$LOCAL_BIN/e-imzo"
DESKTOP_FILE="$APPLICATIONS_DIR/e-imzo.desktop"
AUTOSTART_FILE="$AUTOSTART_DIR/e-imzo.desktop"

SYSTEM_CERT="/etc/ca-certificates/trust-source/anchors/E-IMZO.pem"

echo "========================================"
echo " E-IMZO ${EIMZO_VERSION} setup"
echo "========================================"

#
# Dependencies
#

echo
echo "==> Installing dependencies"

sudo pacman -S --needed --noconfirm \
    jre17-openjdk \
    wget \
    tar \
    nss

#
# Directories
#

echo
echo "==> Creating directories"

mkdir -p "$EIMZO_DIR"
mkdir -p "$DSKEYS_DIR"
mkdir -p "$LOCAL_BIN"
mkdir -p "$APPLICATIONS_DIR"
mkdir -p "$AUTOSTART_DIR"

#
# DSKEYS virtual USB
#

echo
echo "==> Configuring DSKEYS virtual USB path"

sudo mkdir -p "$MEDIA_DIR"

if [[ -L "$DSKEYS_LINK" ]]; then
    current_target="$(readlink -f "$DSKEYS_LINK")"

    if [[ "$current_target" == "$DSKEYS_DIR" ]]; then
        echo "==> DSKEYS symlink is already configured"
    else
        echo "ERROR: $DSKEYS_LINK points to:"
        echo "       $current_target"
        echo
        echo "Expected:"
        echo "       $DSKEYS_DIR"
        exit 1
    fi

elif [[ -e "$DSKEYS_LINK" ]]; then
    echo "ERROR: $DSKEYS_LINK already exists"
    echo "       and is not a symbolic link."
    exit 1

else
    sudo ln -s "$DSKEYS_DIR/" "$DSKEYS_LINK"

    echo "==> Created:"
    echo "    $DSKEYS_LINK -> $DSKEYS_DIR/"
fi

#
# Download
#

echo
echo "==> Downloading E-IMZO ${EIMZO_VERSION}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

wget \
    -O "$tmp_dir/e-imzo.tar.gz" \
    "$EIMZO_URL"

#
# Install
#

echo
echo "==> Installing E-IMZO"

rm -rf "$EIMZO_DIR"
mkdir -p "$EIMZO_DIR"

tar -xzf "$tmp_dir/e-imzo.tar.gz" \
    -C "$EIMZO_DIR" \
    --strip-components=1

#
# Verify files
#

echo
echo "==> Checking installation"

if [[ ! -f "$EIMZO_JAR" ]]; then
    echo "ERROR: E-IMZO.jar was not found."
    echo "Expected:"
    echo "    $EIMZO_JAR"
    exit 1
fi

if [[ ! -f "$EIMZO_CERT" ]]; then
    echo "ERROR: E-IMZO.pem was not found."
    echo "Expected:"
    echo "    $EIMZO_CERT"
    exit 1
fi

#
# System trusted certificate
#

echo
echo "==> Installing E-IMZO certificate into system trust store"

sudo install -Dm644 \
    "$EIMZO_CERT" \
    "$SYSTEM_CERT"

sudo update-ca-trust

echo "==> System trust store updated"

#
# Google Chrome NSS certificate
#

echo
echo "==> Installing E-IMZO certificate for Google Chrome"

if [[ -d "$HOME/.pki/nssdb" ]]; then
    CHROME_NSS_DB="$HOME/.pki/nssdb"
else
    CHROME_NSS_DB="$HOME/.local/share/pki/nssdb"
    mkdir -p "$CHROME_NSS_DB"
fi

if [[ ! -f "$CHROME_NSS_DB/cert9.db" ]]; then
    echo "==> Initializing Chrome NSS database"

    certutil \
        -N \
        -d "sql:$CHROME_NSS_DB" \
        --empty-password
fi

# Remove old E-IMZO certificate if it already exists
certutil \
    -D \
    -d "sql:$CHROME_NSS_DB" \
    -n "E-IMZO" \
    2>/dev/null || true

# Import current E-IMZO certificate
certutil \
    -A \
    -d "sql:$CHROME_NSS_DB" \
    -n "E-IMZO" \
    -t "C,," \
    -i "$EIMZO_CERT"

echo "==> E-IMZO certificate added to Chrome NSS database"
echo "    $CHROME_NSS_DB"

#
# Launcher
#

echo
echo "==> Creating launcher"

cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
exec java -jar "$EIMZO_JAR"
EOF

chmod +x "$LAUNCHER"

#
# Application menu
#

echo
echo "==> Creating application menu entry"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=E-IMZO
Comment=E-IMZO electronic digital signature
Exec=$LAUNCHER
Terminal=false
Categories=Utility;
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"

#
# Autostart
#

echo
echo "==> Enabling E-IMZO autostart"

cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=E-IMZO
Comment=E-IMZO electronic digital signature
Exec=$LAUNCHER
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

chmod +x "$AUTOSTART_FILE"

#
# Update desktop database
#

if command -v update-desktop-database &>/dev/null; then
    echo
    echo "==> Updating application database"
    update-desktop-database "$APPLICATIONS_DIR"
fi

#
# Information
#

echo
echo "==> Java version"
java -version

echo
echo "========================================"
echo " E-IMZO installation complete"
echo "========================================"
echo
echo "Application:"
echo "  $EIMZO_JAR"
echo
echo "Launcher:"
echo "  $LAUNCHER"
echo
echo "Desktop entry:"
echo "  $DESKTOP_FILE"
echo
echo "Autostart:"
echo "  $AUTOSTART_FILE"
echo
echo "System certificate:"
echo "  $SYSTEM_CERT"
echo
echo "Chrome NSS database:"
echo "  $CHROME_NSS_DB"
echo
echo "Keys directory:"
echo "  $DSKEYS_DIR"
echo
echo "Virtual USB path:"
echo "  $DSKEYS_LINK -> $DSKEYS_DIR/"
echo
echo "IMPORTANT:"
echo "  Fully close Google Chrome and start it again"
echo "  after running this script."
echo
echo "To start E-IMZO now:"
echo "  $LAUNCHER"
