#!/bin/sh

# Kernel is built without network support
rm -f ${TARGET_DIR}/etc/init.d/S40network

