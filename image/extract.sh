#!/bin/sh

export PYTHONPATH=$PYTHONPATH:/galaxy-central/lib/

exec  wps_extract "$@"
