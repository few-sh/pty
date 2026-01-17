#!/bin/bash
# Long running script that can be killed
for i in {1..100}; do
  echo "iteration $i"
  sleep 0.1
done
