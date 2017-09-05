#!/usr/bin/env bats

@test "Patch under pressure" {
    ./kgr_tc_3.sh
}

@test "Test live kernel patching in quick succession" {
    ./kgr_tc_5.sh
}

@test "Patch while CPUs are busy" {
    ./kgr_tc_6.sh
}

@test "Patch in low memory condition" {
    ./kgr_tc_7.sh
}

@test "Patch with replace-all" {
    ./kgr_tc_8.sh
}

