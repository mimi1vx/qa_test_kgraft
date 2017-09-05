#!/bin/bash

# Copyright (C) 2017 SUSE
# Author: Libor Pechacek
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.

# Test Case 5: Test kGraft-patching in quick succession
# Apply one patch after another in quick succession

set -e
. $(dirname $0)/kgr_tc_functions.sh
kgr_tc_init "Test Case 5: Test kGraft-patching in quick succession"

N_PATCHES=15

kgr_tc_milestone "Compiling kGraft patches"
SOURCE_DIR="$(dirname $0)"
PATCH_DIR="/tmp/kgraft-patch/"
KERN_VERSION=$(uname -r | sed 's/-[^-]*$//')
KERN_FLAVOR=$(uname -r | sed 's/^.*-//')
KERN_ARCH=$(uname -m)
for N in $(seq 1 $N_PATCHES); do
    PATCH_SUBDIR="$PATCH_DIR/patch$N"
    mkdir -p "$PATCH_SUBDIR"
    sed "s/@@SEQ_N@@/$N/g" "$SOURCE_DIR"/kgr_tc_5-Makefile > "$PATCH_SUBDIR"/Makefile
    sed "s/@@SEQ_N@@/$N/g" "$SOURCE_DIR"/kgr_tc_5-kgraft_patch_getpid.c \
	> "$PATCH_SUBDIR"/kgraft_patch_getpid$N.c
    make -C /usr/src/linux-$KERN_VERSION-obj/$KERN_ARCH/$KERN_FLAVOR M="$PATCH_SUBDIR" O="$PATCH_SUBDIR"
done

for N in $(seq 1 $N_PATCHES); do
    PATCH_SUBDIR="$PATCH_DIR/patch$N"
    kgr_tc_milestone "Inserting getpid patch $N"
    insmod "$PATCH_SUBDIR"/kgraft_patch_getpid$N.ko

    kgr_tc_milestone "Wait for completion (patch $N)"
    if ! kgr_wait_complete 61; then
	kgr_dump_blocking_processes
	kgr_tc_abort "patching didn't finish in time (patch $N)"
    fi
done

# test passed if execution reached this line
# failures beyond this point are not test case failures
trap - EXIT
kgr_tc_milestone "TEST PASSED, reboot to remove the kGraft patches"
