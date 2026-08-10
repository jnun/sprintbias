Interactively set the everyday options in docs/sprintbias/config — no AI is
invoked, this is pure config (keep family).

Usage:
  ./sprint.sh config           # walk through provider + default model
  ./sprint.sh config --help    # this help

What it asks:
  Provider      — Claude Code or Grok Build. Writes both CLI and the provider
                  tier (PROVIDER), the same pair setup.sh's two doors set.
                    [c] Claude Code   → CLI=claude, PROVIDER=claude-code
                    [g] Grok Build    → CLI=grok,   PROVIDER=grok-build
                  A bare Enter keeps your current provider.

  Default model — the model every command uses unless a per-role pin or a
                  per-run --model flag overrides it. The menu lists that
                  provider's common ids plus a `custom id…` entry for anything
                  not shown. When the provider is unchanged you can [k] keep the
                  current model; after switching providers you must pick one
                  (a kept model from the other provider would be a foreign pin).

What it writes:
  CLI, PROVIDER, and MODEL_DEFAULT in docs/sprintbias/config, via the same
  writer `model set` uses — no other key is touched. Choices are semi-permanent:
  they persist across updates until you change them.

Related commands:
  ./sprint.sh model show                 # effective model per role + its source
  ./sprint.sh model list                 # models the current provider offers
  ./sprint.sh model set <role> <model>   # pin one command (e.g. work, gate)

Precedence (highest first):
  1. env  SPRINTBIAS_MODEL_<ROLE> / SPRINTBIAS_CLI …   this-shell override
  2. per-run flag   --model <id>, or -c / -g            one invocation
  3. docs/sprintbias/config.local                       personal, never shipped
  4. docs/sprintbias/config                             what `config` writes
  5. tier default                                       opus / grok-4.5

Notes:
  - Interactive: needs a terminal. In a script or pipe, edit
    docs/sprintbias/config directly or use `./sprint.sh model set`.
  - For a personal override that never ships or gets committed, put the same
    keys in docs/sprintbias/config.local — it wins over config per key.
  - This sets the default model. For different models per command, use
    `./sprint.sh model set <role> <model>` after running config.
