# Custom Dockerfile with python and Yandex SSL certificate

For use flink in session mode you can pass your jobs into image and use something like that as entrypoint:
```
#!/bin/sh

/docker-entrypoint.sh "$@" &

FLINK_PID=$!

URL="http://localhost:8081/config"

INTERVAL=2

check_server() {
  STATUS=$(curl -s -o /dev/null -w '%{http_code}' $URL)
  echo "HTTP Status: $STATUS"
  if [ "$STATUS" -eq 200 ]; then
    return 0
  else
    return 1
  fi
}

while ! check_server; do
  sleep $INTERVAL
done

flink run examples/streaming/WordCount.jar           &
flink run examples/streaming/WindowJoin.jar          &
flink run examples/streaming/TopSpeedWindowing.jar   &
flink run examples/streaming/SessionWindowing.jar    &
flink run examples/streaming/Iteration.jar           &
flink run examples/streaming/StateMachineExample.jar &


wait $FLINK_PID
```
Don't forget to override the command to run in helm chart
