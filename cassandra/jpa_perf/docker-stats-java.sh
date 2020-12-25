#!/usr/bin/env bash

FILE="./results/stats-java.tsv"
while true; do docker stats --no-stream  jpa_perf_java_1 --format "\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}" | ts >> $FILE; done
