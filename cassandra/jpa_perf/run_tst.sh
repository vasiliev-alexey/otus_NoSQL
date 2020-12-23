#!/usr/bin/env bash


./docker-stats-java.sh   
bg
./docker-stats-cassandra.sh
bg


docker-compose up -d 

bg
