#!/bin/bash

#****************READING TARGETS***********

declare -a idis=($apiIds)
declare -a names=($apiNames)

for key in "${!idis[@]}"; do echo ${idis[$key]}; echo ${names[$key]}; echo "\n"; done


