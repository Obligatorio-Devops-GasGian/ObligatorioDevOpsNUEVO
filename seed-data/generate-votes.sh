VOTE_URL=${VOTE_URL:-http://44.222.184.226/}

ab -n 1000 -c 50 -p posta -T "application/x-www-form-urlencoded" \
   -H "Host: 44.222.184.226"  "$VOTE_URL"
ab -n 1000 -c 50 -p postb -T "application/x-www-form-urlencoded" \
   -H "Host: 44.222.184.226"  "$VOTE_URL"
ab -n 1000 -c 50 -p posta -T "application/x-www-form-urlencoded" \
   -H "Host: 44.222.184.226"  "$VOTE_URL"
