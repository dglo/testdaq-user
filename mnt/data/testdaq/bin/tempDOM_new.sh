#!/bin/bash

echo 'send "$0a00 $90081090 ! 50000 usleep $0000 $90081090 ! 500 usleep $90081094 @ $3ffc and . drop\r" expect "^>"' | se $1 | tr '\r' '\n' | grep '^[0-9]'
