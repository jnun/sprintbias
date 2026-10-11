# Task 435: validate --commands --docs runs only the first check

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: none
**From plan**: 32
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

`./sprint.sh validate --commands --docs` runs only one of the two checks: each flag `exec`s its checker as soon as it is parsed, so the second flag never runs. A person (or an agent following CONTRIBUTING.md) who asks for both sees one pass and assumes both checks passed.

## Done when (automated)

- [ ] `./sprint.sh validate --commands --docs` runs both checks and exits non-zero when either fails (`bash docs/tests/test-validate-tasks.sh`)

## Signoff (human)

- [ ]

## Notes

Found while closing plan 32 (both checks pass when run one at a time).

## References

docs/sprintbias/scripts/validate-tasks.sh
