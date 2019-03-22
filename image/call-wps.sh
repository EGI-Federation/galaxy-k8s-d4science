#!/bin/sh

export PYTHONPATH=$PYTHONPATH:/galaxy-central/lib/

exec call_wps "$@"
