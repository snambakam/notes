#!/usr/bin/env bash
# Build an openvpn3-linux RPM locally using mock, from a (forked) packaging repo.
#
# Requires: mock, git, rpmbuild, spectool (dnf install mock rpmdevtools).
# Your user must be in the 'mock' group (sudo usermod -aG mock "$USER", then
# log out/in) to run mock without sudo.
#
# Usage:
#   ./build-openvpn3-copr.sh [options]
#
# Options:
#   --clone-url URL    Git URL of the packaging repo (containing the spec)
#                       (default: https://gitlab.com/dazo/copr-openvpn3.git)
#   --commit REF       Branch/tag/commit to build (default: master)
#   --spec PATH         Spec file path within the repo (default: openvpn3.spec)
#   --chroot CHROOT     Mock chroot to build for; repeatable
#                       (default: fedora-44-x86_64)
#   --extra-repo URLTMPL Extra repo baseurl added to the mock build, with
#                       '{chroot}' substituted per chroot (default: the
#                       dsommers/openvpn3 Copr repo, which ships gdbuspp-devel
#                       -- not yet packaged in Fedora's own repos)
#   --out-dir DIR        Where to copy the resulting RPMs (default: ./mock-out)
#   -h, --help          Show this help

set -euo pipefail

CLONE_URL="https://gitlab.com/dazo/copr-openvpn3.git"
COMMIT="master"
SPEC="openvpn3.spec"
OUT_DIR="./mock-out"
EXTRA_REPO="https://download.copr.fedorainfracloud.org/results/dsommers/openvpn3/{chroot}/"
CHROOTS=()

usage() {
    sed -n '2,24p' "$0"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clone-url) CLONE_URL="$2"; shift 2 ;;
        --commit) COMMIT="$2"; shift 2 ;;
        --spec) SPEC="$2"; shift 2 ;;
        --chroot) CHROOTS+=("$2"); shift 2 ;;
        --extra-repo) EXTRA_REPO="$2"; shift 2 ;;
        --out-dir) OUT_DIR="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

if [[ ${#CHROOTS[@]} -eq 0 ]]; then
    CHROOTS=("fedora-44-x86_64")
fi

for tool in mock git rpmbuild spectool; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: $tool not found. Install it with: sudo dnf install mock git rpmbuild rpmdevtools" >&2
        exit 1
    fi
done

# Work in a scratch directory so the repo checkout and downloaded
# sources/patches don't clutter the caller's working tree.
WORKDIR=$(mktemp -d /tmp/openvpn3-mock.XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

echo ">>> Cloning $CLONE_URL @ $COMMIT into $WORKDIR"
git clone --quiet --depth 1 --branch "$COMMIT" "$CLONE_URL" "$WORKDIR/src"

SPEC_PATH="$WORKDIR/src/$SPEC"
if [[ ! -f "$SPEC_PATH" ]]; then
    echo "Error: spec file not found at $SPEC_PATH" >&2
    echo "Pass --spec <path> pointing at the spec inside your fork." >&2
    exit 1
fi

echo ">>> Extracting spec + sources/patches referenced by $SPEC into $WORKDIR/sources"
mkdir -p "$WORKDIR/sources"
cp "$SPEC_PATH" "$WORKDIR/sources/"
# Pull in any local files (patches, gpg keys, etc.) already checked into the repo.
find "$WORKDIR/src" -maxdepth 1 -type f ! -name '*.spec' -exec cp {} "$WORKDIR/sources/" \;
spectool -g -R --define "_sourcedir $WORKDIR/sources" "$WORKDIR/sources/$(basename "$SPEC_PATH")"

echo ">>> Building SRPM"
SRPM_OUT_DIR="$WORKDIR/srpm"
mkdir -p "$SRPM_OUT_DIR"
rpmbuild -bs \
    --define "_sourcedir $WORKDIR/sources" \
    --define "_srcrpmdir $SRPM_OUT_DIR" \
    "$WORKDIR/sources/$(basename "$SPEC_PATH")"
SRPM=$(find "$SRPM_OUT_DIR" -name '*.src.rpm' | head -1)
if [[ -z "$SRPM" ]]; then
    echo "Error: SRPM build did not produce a .src.rpm" >&2
    exit 1
fi
echo ">>> Built $SRPM"

mkdir -p "$OUT_DIR"
for chroot in "${CHROOTS[@]}"; do
    echo ">>> Building with mock (chroot: $chroot)"
    RESULT_DIR="$WORKDIR/result/$chroot"
    mkdir -p "$RESULT_DIR"
    ADDREPO_ARGS=()
    if [[ -n "$EXTRA_REPO" ]]; then
        ADDREPO_ARGS=(--addrepo="${EXTRA_REPO//\{chroot\}/$chroot}")
    fi
    mock -r "$chroot" "${ADDREPO_ARGS[@]}" --resultdir "$RESULT_DIR" --rebuild "$SRPM"
    mkdir -p "$OUT_DIR/$chroot"
    cp "$RESULT_DIR"/*.rpm "$OUT_DIR/$chroot/" 2>/dev/null || true
    echo ">>> Copied RPMs for $chroot to $OUT_DIR/$chroot/"
done

echo ">>> Done. Built RPMs:"
find "$OUT_DIR" -name '*.rpm'
