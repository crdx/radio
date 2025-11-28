set quiet := true
set shell := ["bash", "-cu", "-o", "pipefail"]

[private]
help:
    just --list --unsorted

fmt:
    echo 'Nothing to format'

lint:
    rubocop

fix:
    rubocop -A
