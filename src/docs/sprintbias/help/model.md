See, list, and set the AI model each command uses — no AI is invoked, this is
pure config over docs/sprintbias/config (keep family).

Usage:
  ./sprint.sh model                # same as: model show
  ./sprint.sh model show           # effective model per role
  ./sprint.sh model list           # models the current provider offers
  ./sprint.sh model set KEY VALUE  # KEY = default | <role>

What it does:
  show  — Prints the active CLI, provider tier, and mode, then the effective
          model for every role (work, chat, gate, feature, idea, split, sprint,
          profile, code_audit, excellence, polish, audit, deps, triage,
          plan_think, drift) with WHERE that model comes from:
            env <VAR>          a this-shell SPRINTBIAS_MODEL_<ROLE> override
            config MODEL_<ROLE> a per-role pin in docs/sprintbias/config
            config MODEL_DEFAULT the global pin
            tier default        opus (claude-code) / grok-4.5 (grok-build),
                                applied when nothing above is set
            CLI default         the CLI picks its own (non-orchestration tiers)

  list  — On grok-build, runs `grok models` for the live list when the CLI is
          on PATH; otherwise shows known aliases and a pointer. On claude-code,
          shows the opus/sonnet/haiku aliases plus the model-docs URL (there is
          no cheap Claude list API to scrape). Other providers get an honest
          "see your CLI's docs" pointer.

  set   — Writes MODEL_DEFAULT (KEY = default) or MODEL_<ROLE> into
          docs/sprintbias/config, leaving every other key untouched. An empty
          VALUE clears the pin so the role falls back to the next layer.

Model layering (highest precedence first):
  1. env  SPRINTBIAS_MODEL_<ROLE>   this-shell override, never written to disk
  2. --model <id> flag            per-run lever (exports SPRINTBIAS_MODEL_DEFAULT
                                  for that one invocation) — the spine commands
                                  work, chat, gate, and polish accept it
  3. config.local MODEL_<ROLE> / MODEL_DEFAULT   personal overlay: wins over
                                  config per key, gitignored, never shipped
  4. config MODEL_<ROLE>          per-role pin
  5. config MODEL_DEFAULT         global pin
  6. tier default                 opus / grok-4.5 on orchestration tiers
  7. CLI default                  the CLI picks its own (non-orchestration tiers)

Per-run override (no config edit): pass --model <id> to a spine command to
pin the model for that single invocation, e.g.
  ./sprint.sh work --model opus
  ./sprint.sh chat 42 --model sonnet
It wins over config pins but yields to an explicit per-role
SPRINTBIAS_MODEL_<ROLE> already exported in your shell.

Examples:
  ./sprint.sh model show
  ./sprint.sh model list
  ./sprint.sh model set default grok-4.5    # global default for every role
  ./sprint.sh model set work opus           # pin just `work`
  ./sprint.sh model set work ""             # clear the pin

Notes:
  - Works on both claude-code and grok-build installs without the other CLI on
    PATH — only `model list` on grok-build reaches for the CLI, and it degrades
    to known aliases when it is absent.
  - Provider-foreign pins are auto-remapped at resolve time (e.g. a leftover
    MODEL_GATE=opus after switching to Grok resolves to grok-4.5), so `show`
    reflects what the CLI actually receives.
  - The provider picker (setup.sh, or ./sprint.sh -c / -g) chooses the provider;
    `model` chooses the model within it.
