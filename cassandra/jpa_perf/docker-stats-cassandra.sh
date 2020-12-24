#!/usr/bin/env bash
FILE="./results/stats-cassandra.tsv"
while true; do docker stats --no-stream jpa_perf_cassandra_1 --format "\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}" | ts >> $FILE; done