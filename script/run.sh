#!/usr/bin/env bash
ulimit -n 2048
elixir --no-halt -S mix
