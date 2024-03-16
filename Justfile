set quiet := true

[private]
help:
    just --list --unsorted

fmt:
    just --fmt

lint:
    rubocop

fix:
    rubocop -A
