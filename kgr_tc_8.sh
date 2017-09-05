#!/bin/bash

# Copyright (C) 2017 SUSE
# Authors: Lance Wang, Libor Pechacek
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

# Test Case 8: Patch with replace-all

set -e
. $(dirname $0)/kgr_tc_functions.sh

kgr_tc_init "Test Case 8: Patch with replace-all"

N_PATCHES=4
kgr_tc_milestone "Compiling kGraft patch"
SOURCE_DIR="$(dirname $0)"
PATCH_DIR="/tmp/kgraft-patch/replace-all"
KERN_VERSION=$(uname -r | sed 's/-[^-]*$//')
KERN_FLAVOR=$(uname -r | sed 's/^.*-//')
KERN_ARCH=$(uname -m)
for N in $(seq $N_PATCHES) final; do
    PATCH_SUBDIR="$PATCH_DIR/patch_replace-all_$N"
    mkdir -p "$PATCH_SUBDIR"
    sed "s/@@SEQ_N@@/-replace-all_$N/g" "$SOURCE_DIR"/kgr_tc_Makefile.tpl > "$PATCH_SUBDIR"/Makefile
    sed "s/@@SEQ_N@@/_replace_all_$N/g" "$SOURCE_DIR"/kgr_tc-kgraft_patch_getpid-replace-all.c.tpl \
        > "$PATCH_SUBDIR"/kgraft_patch_getpid-replace-all_$N.c
    make -C /usr/src/linux-$KERN_VERSION-obj/$KERN_ARCH/$KERN_FLAVOR M="$PATCH_SUBDIR" O="$PATCH_SUBDIR"
done

for N in $(seq 1 $N_PATCHES) final; do
    PATCH_SUBDIR="$PATCH_DIR/patch_replace-all_$N"
    kgr_tc_milestone "Inserting getpid patch $N"
    insmod "$PATCH_SUBDIR"/kgraft_patch_getpid-replace-all_$N.ko

    kgr_tc_milestone "Wait for completion (patch $N)"
    if ! kgr_wait_complete 61; then
        kgr_dump_blocking_processes
        kgr_tc_abort "patching didn't finish in time (patch $N)"
    fi
done

for N in $(seq 1 $N_PATCHES); do
    PATCH_SUBDIR="$PATCH_DIR/patch_8_$N"
    kgr_tc_milestone "Removing getpid patch $N"
    rmmod kgraft_patch_getpid-replace-all_$N
    if test $? -ne 0;then
        kgr_tc_abort "FAILED to remove the kernel module kgraft_patch_getpid_8_$N"
    fi
done

kgr_tc_milestone "Try to remove getpid patch final"

if rmmod kgraft_patch_getpid-replace-all_final; then
    kgr_tc_abort "It should not be possible to remove the kernel module kgraft_patch_getpid_8_final"
fi


# test passed if execution reached this line
# failures beyond this point are not test case failures
trap - EXIT
kgr_tc_milestone "Call hooks before exit"
call_recovery_hooks
kgr_tc_milestone "TEST PASSED, reboot to remove the kGraft patch"
