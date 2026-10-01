#!/bin/sh
# Chạy bot chiến dịch qua cả 27 thế giới, chia thành nhiều phần chạy song song (mỗi phần CHUNK thế giới).
#
#   sh tools/run_campaign.sh          # mọi thế giới, mỗi phần 3 thế giới
#   CHUNK=1 sh tools/run_campaign.sh  # mỗi thế giới một tiến trình
#
# In các dòng báo cáo từng màn của mọi phần, thoát với mã lỗi = số phần có vấn đề. Log đầy đủ ở $LOGDIR.
cd "$(dirname "$0")/.." || exit 1
CHUNK=${CHUNK:-3}
WORLDS=${WORLDS:-27}
LOGDIR=${LOGDIR:-$(mktemp -d)}
i=1
while [ $i -le "$WORLDS" ]; do
	j=$((i + CHUNK - 1))
	[ $j -gt "$WORLDS" ] && j=$WORLDS
	CAMP_FROM="$i-1" CAMP_TO="$j-B" godot --headless --path . --fixed-fps 60 --quit-after 400000 \
		res://tools/campaign_test.tscn > "$LOGDIR/part_$i.log" 2>&1 &
	i=$((j + 1))
done
wait
bad=0
for f in $(ls "$LOGDIR"/part_*.log | sort -t_ -k2 -n); do
	grep -a "^\[camp\] ■" "$f" | sed 's/^\[camp\] ■ /  /'
	grep -aq "\[camp\] TẤT CẢ OK" "$f" || { bad=$((bad + 1)); echo "  ⚠ $(basename "$f"): $(grep -a '\[camp\] .*vấn đề\|SCRIPT ERROR' "$f" | head -3)"; }
done
echo "[run_campaign] $( [ $bad -eq 0 ] && echo 'TẤT CẢ OK' || echo "$bad phần có vấn đề" ) · log: $LOGDIR"
exit $bad
