#!/bin/bash

echo 'send "$0200 $90081090 ! 50000 usleep $0000 $90081090 ! 500 usleep $90081094 @ $3fff and . drop\r" expect "^>"' | se $1 | tr '\r' '\n' | grep '^[0-9]'

