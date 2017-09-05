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

# define useful variables


function kgr_in_progress() {
    [ "$(cat /sys/kernel/kgraft/in_progress)" -ne 0 ]
}

function kgr_wait_complete() {
    if [ $# -gt 0 ]; then
        TIMEOUT=$1
    else
        TIMEOUT=-1
    fi

    while kgr_in_progress && [ $TIMEOUT -ne 0 ]; do
        sleep 1
        (( TIMEOUT-- )) || true
    done

    ! kgr_in_progress
}

function kgr_dump_blocking_processes() {
    unset PIDS
    echo "global kGraft in_progress flag:" $(cat /sys/kernel/kgraft/in_progress)

    for PROC in /proc/[0-9]*; do
        if [ "$(cat $PROC/kgr_in_progress)" -ne 0 ]; then
	    DIR=${PROC%/kgr_in_progress}
	    PID=${DIR#/proc/}
	    COMM="$(cat $DIR/comm)"

	    echo "$COMM ($PID) still in progress:"
	    cat $DIR/stack
	    echo -e '=============\n'
	    PIDS="$PIDS $PID"
	fi
    done
    if [ -z "$PIDS" ]; then
        echo "no processes with kgr_in_progress set"
    fi
}

declare -a RECOVERY_HOOKS

function push_recovery_fn() {
    [ -z "$1" ] && echo "WARNING: no parameters passed to push_recovery_fn"
    RECOVERY_HOOKS[${#RECOVERY_HOOKS[*]}]="$1"
}

function pop_and_run_recovery_fn() {
    local fn=$1
    local num_hook=${#RECOVERY_HOOKS[*]}

    [ $num_hook -eq 0 ] && return 1
    (( num_hook--)) || true
    eval ${RECOVERY_HOOKS[$num_hook]} || true
    unset RECOVERY_HOOKS[$num_hook]
    return 0
}

function call_recovery_hooks() {
    for fn in "${RECOVERY_HOOKS[@]}"; do
        echo "calling \"$fn\""
        eval $fn || true
    done
}

function kgr_tc_write() {
    logger "$*"
    echo "$*"
}

function kgr_tc_init() {
    trap "[ \$? -ne 0 ] && echo TEST FAILED while executing \'\$BASH_COMMAND\', EXITING; call_recovery_hooks" EXIT
    kgr_tc_write "$1"
    if kgr_in_progress; then
        kgr_tc_write "ERROR kGraft patching in progress, cannot start test"
	exit 22 # means SKIPPED in CTCS2 terminology
    fi
}

function kgr_tc_milestone() {
    kgr_tc_write "***" "$*"
}

function kgr_tc_abort() {
    kgr_tc_write "TEST CASE ABORT" "$*"
    exit 1
}
