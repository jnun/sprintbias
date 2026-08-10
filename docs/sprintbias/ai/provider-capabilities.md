# AI provider capability matrix

SprintBias speaks one provider-neutral interface (`sprintbias_run` / the `cli/*.sh`
profiles) but providers are not equal. This table is the single source of
truth for what each tier can do, so scripts can exploit Claude Code and Grok
Build strengths and degrade honestly everywhere else instead of coding to a
lowest common denominator.

Priority order — the tiers we invest in, most-used first: **Claude Code**,
**Grok Build**, **Cursor**, **OpenAI**, then a **generic** catch-all for
everything else. Claude and Grok are first-class interactive + orchestration
peers; Cursor/OpenAI use the generic profile until verified.

Design maps: Claude as-built → `docs/guides/claude-provider-tier.md`;
Grok as-built → `docs/guides/grok-provider-tier.md`.

The active tier is chosen at `setup.sh` time and stored as `PROVIDER=` in
`docs/sprintbias/config`. Query it from any script with `sprintbias_ai_tier`
(defined in `lib.sh`); it falls back to inferring the tier from the `CLI=`
binary when `PROVIDER=` is unset. For a single invocation without rewriting
config, pass a leading flag on the launcher: `./sprint.sh -g …` (Grok Build) or
`./sprint.sh -c …` (Claude Code) — these export `SPRINTBIAS_CLI` /
`SPRINTBIAS_PROVIDER` for that process tree only.

## Matrix

| Capability            | claude-code | grok-build | cursor    | openai    | generic |
|-----------------------|-------------|------------|-----------|-----------|---------|
| Exec JSON output      | yes         | yes        | no¹       | no¹       | no      |
| Stream progress NDJSON| yes (`stream-json`) | yes (`stream-json`→`streaming-messages-json`) | no¹ | no¹ | no |
| Subagent / parallel   | yes         | yes        | no        | no        | no      |
| Tool restriction      | yes         | yes²       | no¹       | no¹       | no      |
| Budget caps           | yes         | no³        | no        | no        | no      |
| Model selection       | yes         | yes        | no¹       | no¹       | no      |
| Emit-mode detection   | yes         | yes        | yes       | no⁴       | no⁴     |
| Interactive chat      | yes         | yes        | no¹       | no¹       | no      |
| CLI binary            | `claude`    | `grok`     | `cursor-agent` | `codex` | (any) |
| Profile               | `cli/claude.sh` | `cli/grok.sh` | `cli/default.sh`⁵ | `cli/default.sh`⁵ | `cli/default.sh` |

¹ Not wired up. These CLIs may support some of these flags, but no verified
profile maps them yet, so the generic `default.sh` passthrough is used and
the flags are dropped (with a one-line warning naming what was dropped).
Add a `cli/<binary>.sh` profile once the flags are verified against a real
install — see the history note below.

² Grok `--tools` takes **internal** tool IDs (`read_file`, `search_replace`,
…). The profile maps known Claude-style names; unmapped names fail open
(allowlist omitted). Never maps to `--allowedTools` (that is a permission-rule
alias for `--allow` on Grok).

³ No verified USD/token budget flag on Grok. Budget is omitted at source: the
call sites (`work`, `polish`, `deps`) build `--budget` only when
`sprintbias_budget_capable` says the active tier can enforce a cap, so on Grok
nothing is sent and nothing is warned about. The profile still drops `--budget`
with a one-line warning as defense-in-depth for any caller that passes it.

⁴ Emit-mode auto-detection keys on agent-session env vars in
`lib.sh:sprintbias_ai_mode` (`CLAUDECODE`, `GROK_AGENT`, `CURSOR_TRACE_ID`, …).
Claude Code, Grok Build, and Cursor set these; OpenAI/generic CLIs are
detected only via the generic `AI_AGENT` / `SPRINTBIAS_IN_AGENT` fallbacks or
an explicit `MODE=emit`.

⁵ No dedicated profile ships today for Cursor/OpenAI/Gemini/Mistral.
`openai.sh`, `gemini.sh`, and `mistral.sh` stubs were created by task 178
and deliberately removed in commit db90170 because they were best-effort and
unverified — don't resurrect them without verifying flags against a real
install.

## What "tier" means for a script

```bash
if sprintbias_orchestration_capable; then
    # claude-code | grok-build: subagents, tool restriction, model selection.
    # Subagent wording: sprintbias_subagent_* helpers (Task tool vs spawn_subagent).
    :
else
    # cursor|openai|generic: single-shot prompts; sequential emit fallback.
    :
fi
```

`claude-code` and `grok-build` support the full product surface (interactive
chat, emit detection, parallel emit orchestration, model defaults, headless
flags via their profiles). Budget caps are gated the same way orchestration is:
`sprintbias_budget_capable` names the tiers whose CLI can enforce a USD cap —
today `claude-code` alone — and every other tier runs uncapped with no
`--budget` constructed. A provider that ships a real cap flag joins by adding
its tier to that one `case`. Every other tier routes through `cli/default.sh`,
which runs the bare prompt and drops richer flags with a one-line warning.
Provider-agnostic is a virtue only when it costs nothing; when an orchestration
path outperforms the generic one, gating it on
`sprintbias_orchestration_capable` is the rule.
