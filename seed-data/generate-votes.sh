VOTE_URL=${VOTE_URL:-http://44.211.55.160/}

ab -n 1000 -c 50 -p posta -T "application/x-www-form-urlencoded" \
   -H "Host: 44.211.55.160"  "$VOTE_URL"
ab -n 1000 -c 50 -p postb -T "application/x-www-form-urlencoded" \
   -H "Host: 44.211.55.160"  "$VOTE_URL"
ab -n 1000 -c 50 -p posta -T "application/x-www-form-urlencoded" \
   -H "Host: 44.211.55.160"  "$VOTE_URL"
