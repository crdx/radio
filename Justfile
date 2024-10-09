set quiet := true

[private]
help:
    just --list --unsorted

fmt:
    just --fmt
    find . -name '*.just' -print0 | xargs -0 -I{} just --fmt -f {}

lint:
    rubocop

fix:
    rubocop -A
