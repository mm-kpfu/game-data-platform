echo "FROM ENTRYPOINT" && \
/docker-entrypoint.sh && \
echo "AFTER DOCKER-ENTRYPOINT" && \
flink run examples/streaming/WordCount.jar & \
flink run examples/streaming/WindowJoin.jar & \
flink run examples/streaming/TopSpeedWindowing.jar & \
flink run examples/streaming/SessionWindowing.jar & \
flink run examples/streaming/Iteration.jar & \
flink run examples/streaming/StateMachineExample.jar &&
echo "AFTER ALL"
