#!/bin/bash
# Replace upstream 0004-pci-Enable-overrides-for-missing-ACS-capabilities-4..patch
# with the self-hosted variant that drops the "device already has ACS" guard,
# so pcie_acs_override applies to every PCIe device.
#
# This script must be run from the root of the cloned pve-kernel repository.

set -euo pipefail

PATCH_NAME='0004-pci-Enable-overrides-for-missing-ACS-capabilities-4..patch'
SELF_PATCH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/patches/kernel/${PATCH_NAME}"
TARGET="patches/kernel/${PATCH_NAME}"

if [ ! -f "$SELF_PATCH" ]; then
    echo "ERROR: self-hosted patch not found: $SELF_PATCH" >&2
    exit 1
fi

if [ ! -f "$TARGET" ]; then
    echo "ERROR: upstream patch not found: $TARGET" >&2
    echo "       (are you running this from the pve-kernel repo root?)" >&2
    exit 1
fi

cp "$SELF_PATCH" "$TARGET"

# Sanity checks: the new patch must (a) drop the ACS-cap guard line and
# (b) keep the unconditional pci_is_pcie check.
if grep -q 'pci_find_ext_capability(dev, PCI_EXT_CAP_ID_ACS)' "$TARGET"; then
    echo "ERROR: patch still contains the ACS-capability guard" >&2
    exit 1
fi
if ! grep -q 'if (!pci_is_pcie(dev))' "$TARGET"; then
    echo "ERROR: patch is missing the unconditional pci_is_pcie check" >&2
    exit 1
fi

echo "ACS override patch installed: $TARGET"
