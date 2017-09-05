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

# Test Case 6: Patch while CPUs are busy
# Unlike in TC 3 we are not invoking the patched function

set -e
. $(dirname $0)/kgr_tc_functions.sh
. $(dirname $0)/kgr_tc_workload.sh

kgr_tc_init "Test Case 6: Patch under cpu pressure"

kgr_tc_milestone "Compiling kGraft patch"
SOURCE_DIR="$(dirname $0)"
PATCH_DIR="/tmp/kgraft-patch/6"
mkdir -p "$PATCH_DIR"
sed "s/@@SEQ_N@@/_6/g" "$SOURCE_DIR"/kgr_tc_Makefile.tpl > "$PATCH_DIR"/Makefile
sed "s/@@SEQ_N@@/_6/g" "$SOURCE_DIR"/kgr_tc-kgraft_patch_getpid.c.tpl \
	> "$PATCH_DIR"/kgraft_patch_getpid_6.c
KERN_VERSION=$(uname -r | sed 's/-[^-]*$//')
KERN_FLAVOR=$(uname -r | sed 's/^.*-//')
KERN_ARCH=$(uname -m)
make -C /usr/src/linux-$KERN_VERSION-obj/$KERN_ARCH/$KERN_FLAVOR M="$PATCH_DIR" O="$PATCH_DIR"

add_workload cpu
kgr_tc_milestone "Staring workload"
start_workload

kgr_tc_milestone "Inserting getpid patch"
insmod "$PATCH_DIR"/kgraft_patch_getpid_6.ko
if [ ! -e /sys/kernel/kgraft/qa_getpid_patcher_6 ]; then
   kgr_tc_abort "don't see qa_getpid_patcher_6 in kGraft sys directory"
fi

kgr_tc_milestone "Wait for completion"
if ! kgr_wait_complete 61; then
    kgr_dump_blocking_processes
    kgr_tc_abort "patching didn't finish in time"
fi

# test passed if execution reached this line
# failures beyond this point are not test case failures
trap - EXIT
kgr_tc_milestone "Call hooks before exit"
call_recovery_hooks
kgr_tc_milestone "TEST PASSED, reboot to remove the kGraft patch"
