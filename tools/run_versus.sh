#!/bin/sh
# Chạy test đấu qua mạng (tools/versus_test.gd): các tiến trình Godot headless, một chủ phòng + các máy vào phòng.
#
#   sh tools/run_versus.sh                                    # 1 VS 1: Kuuga đấu Kuuga
#   RIDERS="faiz agito" sh tools/run_versus.sh                # Rider của chủ phòng, Rider của máy vào phòng
#   RIDERS="kuuga ryuki faiz double" sh tools/run_versus.sh   # 3–4 Rider = phòng ALL COMBAT (hỗn chiến)
#   VERBOSE=--verbose ...                                     # in vị trí / trạng thái mỗi 2 giây
cd "$(dirname "$0")/.." || exit 1
set -- ${RIDERS:-kuuga kuuga}
COUNT=$#
MODE=duel
[ "$COUNT" -gt 2 ] && MODE=all
LOGDIR=${LOGDIR:-$(mktemp -d)}
godot --headless --path . res://tools/versus_test.tscn -- --host --rider="$1" --mode=$MODE --expect=$COUNT \
	--name=Bot1 $VERBOSE > "$LOGDIR/p1.log" 2>&1 &
PIDS=$!
shift
i=2
for r in "$@"; do
	sleep 1
	godot --headless --path . res://tools/versus_test.tscn -- --join --rider="$r" --name=Bot$i $VERBOSE \
		> "$LOGDIR/p$i.log" 2>&1 &
	PIDS="$PIDS $!"
	i=$((i + 1))
done
bad=0
for p in $PIDS; do
	wait $p || bad=$((bad + 1))
done
grep -a "^\[versus\|SCRIPT ERROR\|ERROR" "$LOGDIR"/p*.log | sed "s|$LOGDIR/||"
echo "[run_versus] $MODE · $COUNT người · $( [ $bad -eq 0 ] && echo 'TẤT CẢ OK' || echo "$bad máy có vấn đề" ) · log: $LOGDIR"
[ $bad -eq 0 ]
