#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2019 Petr Vorel <pvorel@suse.cz>

TESTS="
kgr_tc_3.sh|Patch under pressure
kgr_tc_5.sh|Test live kernel patching in quick succession
kgr_tc_6.sh|Patch while CPUs are busy
kgr_tc_7.sh|Patch in low memory condition
kgr_tc_8.sh|Patch with replace-all
"

bats=$(which bats 2>/dev/null)
script=$(mktemp)

if [ "$bats" ]; then
    echo "#!$bats" > $script
else
    cat > $script <<EOF
#!/bin/sh
ret=0
EOF
fi

IFS="
"
for i in $TESTS; do
    file=$(echo $i | cut -d'|' -f1)
    desc=$(echo $i | cut -d'|' -f2)

    if [ "$bats" ]; then
        cat >> $script <<EOF
@test "$desc" {
    ./$file
}
EOF
    else
        cat >> $script <<EOF
echo "== $desc =="
./$file || ret=1
echo
EOF
    fi
done

[ ! "$bats" ] && echo 'exit $ret' >> $script

chmod 755 $script

$script
exit $?
