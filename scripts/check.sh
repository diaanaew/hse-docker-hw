#!/usr/bin/env bash
set -euo pipefail

PROJECT="hw3-check-$$-$RANDOM"
PORT=18080
BASE="http://127.0.0.1:$PORT"
STEP="startup"

dc() {
    APP_PORT="$PORT" docker compose -p "$PROJECT" "$@"
}

cleanup() {
    code=$?
    trap - EXIT
    dc down -v >/dev/null 2>&1 || true
    if [ "$code" -ne 0 ]; then
        echo "FAIL: $STEP" >&2
    fi
    exit "$code"
}

trap cleanup EXIT

wait_ready() {
    for ((i=0; i<30; i++)); do
        if curl -fsS --connect-timeout 2 --max-time 3 "$BASE/readyz" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

check_count() {
    result=$(curl -fsS --max-time 5 "$BASE/")
    echo "$result"
    [[ "$result" == *"\"count\": $1,"* ]]
}

check_status() {
    status=$(curl -sS --max-time 5 -o /dev/null -w '%{http_code}' -X "$1" "$BASE$2")
    echo "$1 $2: $status"
    [ "$status" = "$3" ]
}

STEP="startup"
dc up -d
wait_ready

STEP="initial count"
check_count 0

STEP="increment"
N=3
for ((i=0; i<N; i++)); do
    check_status POST /increment 200
done
check_count "$N"

STEP="recreate app"
dc up -d --force-recreate --no-deps app
wait_ready
check_count "$N"

STEP="stop redis"
dc stop redis
check_status GET /healthz 200
check_status GET /readyz 503
check_status POST /increment 503

STEP="start redis"
dc start redis
wait_ready
check_count "$N"
check_status POST /increment 200
check_count "$((N+1))"

STEP="backup"
dc stop app redis
dc run --rm --no-deps -T redis tar -czf - -C /data . > redis-backup.tar.gz
test -s redis-backup.tar.gz

STEP="cleanup"
dc down -v

echo "OK"
