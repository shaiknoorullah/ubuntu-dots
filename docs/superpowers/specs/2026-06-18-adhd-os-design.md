# Context-Driven ADHD OS on i3 — Design

> Status: **DRAFT for review** · Date: 2026-06-18 · Owner: shaiknoorullah
> Repo: `ubuntu-dots` · Branch: `rice/adhd-os-design`

A desktop + workflow system for Ubuntu 24.04 / X11 / i3, whose primary goal is
**ADHD support**: protect attention, make work observable, and minimize the
number of decisions required to start and sustain focused work. Aesthetic and
"ricing" are in service of that goal, not the goal itself.

---

## 1. Why (research findings)

Gathered from this machine, both GitHub accounts, the Obsidian vault, and the
Aether repo (2026-06-17/18).

- **The operator profile.** DevOps-heavy engineer + manager at ProficientNow by
  day (`snoorullah`: pnow-ats-v2, ArgoCD/SigNoz/Entra admin, two k8s prod
  clusters, a 99-worktree monorepo); AI-agent-tooling builder by night
  (`shaiknoorullah`: opsbench, agenthive, Aether — 100 repos). Runs **~20 tmux
  sessions and ~49 Claude project dirs simultaneously.** GitHub stars cluster on
  ADHD/focus tooling — this system shares the thesis of his own projects.
- **Five systemic problems** (mapped to the operator's stated pains A–E + 1–6):
  1. Context sprawl with no boundaries — one undifferentiated browser profile
     holds work + Microsoft admin + personal + AI. (D, #1, #6)
  2. Zero surfacing — nothing shows what is live, what is next, or where time
     went. `taskwarrior` + `timewarrior` are installed but **unconfigured**;
     polybar shows only workspaces + a clock. (A, B, C, #2, #3)
  3. No capture path — ideas die for lack of a friction-free dump. (A)
  4. Recurring-work overload — ArgoCD checks, monitoring, PR reviews, incidents,
     notes — all manual, re-decided daily. (#4, #5)
  5. **The Life-OS paradox** — the `powerhouse` vault is exquisitely
     over-architected (1,184 notes, 7-layer meta-system, 25 agent specs,
     pre-registered research hypotheses) and **barely used as a daily tool**
     (3 daily notes ever, last 2026-03-22; runtime "blocked on a companion
     codebase that does not exist"). Designing the system has become a
     procrastination object. **This system must not feed that beast.**
- **Decided by research:**
  - The browser wants (fuzzy tab search, fuzzy profile/container switch,
    minimalism) need **no browser fork**: Zen + Tridactyl + Multi-Account
    Containers + a rofi profile launcher. Aether's grand features (Spectator,
    resident agents, per-project history) are correctly cut as YAGNI;
    ActivityWatch covers behavioral tracking if ever wanted.
  - Capture hook already exists: **Obsidian `local-rest-api` is live on
    `https://127.0.0.1:27124` with an API key** — an i3 keybind can POST a
    thought into the vault with zero context switch.

## 2. Goals / Non-goals

**Goals**
- Make starting and resuming work cheap (initiation + context-switch cost).
- Make the day observable: active task, live timer, live sessions, infra health,
  recurring rituals, time-spent — all glanceable.
- Frictionless capture so no idea or task is lost.
- Long-term time/activity data for later workflow optimization.
- One source of truth for theme (Dracula); one action to switch context.

**Non-goals (YAGNI)**
- No Wayland / Hyprland migration (stay i3/X11). Quickshell is therefore out.
- No browser fork; no Aether Spectator / resident agents / durable workflows.
- No extension of the vault meta-system. We integrate with it via the simplest
  stable surface (REST API + daily notes) and leave seams for later.
- No bespoke runtime for the vault's agent architecture.

## 3. The Context model (backbone)

A **Context** is the unit everything hangs off. Switching context is *one action*
that reconfigures the machine. Four contexts, each with a Dracula accent:

| Context | Accent | Browser | tmux sessions | taskwarrior project | Dirs / accounts |
|---|---|---|---|---|---|
| `work` | purple `#BD93F9` | Zen profile/container: ProficientNow (Google + Entra/M365) | pnow-*, pn-infra, pnats-*, fleet-*, ovh-*, rule-engine, automation-service, manageengine | `work.*` | `~/work`, snoorullah GH, clusters: ovh + prod-ap-south-2a |
| `lab` | pink `#FF79C6` | Zen profile/container: personal GitHub/OSS | dots, opsbench, nanoclaw, powerhouse, rofi, polybar | `lab.*` | `~/development`, shaiknoorullah GH |
| `agents` | cyan `#8BE9FD` | container: Claude/AI logins | pi, remote-cli-session, agent panes (pi-fleet) | `agents.*` | `~/.claude/projects`, pi-fleet |
| `personal` | green `#50FA7B` | profile: personal life (separate logins) | powerhouse (life), media | `personal.*` | `~/powerhouse`, finance/learning |

Two **cross-cutting pillars** (functions, not silos) surfaced on the dashboard
regardless of context: **Time/Task tracking** and **Learning tracking**
(spaced-repetition due, current courses from `~/powerhouse/learning/`).

> The context→(browser, tmux, task, accent) mapping above is the single most
> important artifact; it is the seed config every layer reads.

## 4. Architecture (layers)

```
CONTEXT  work · lab · agents · personal   — one keybind reconfigures all of:
         browser profile/containers · tmux group · taskwarrior project · accent · dashboard filter

L1 CAPTURE      $mod+key → 2s input → Obsidian REST (:27124) inbox  [+ optional task add]
L2 TIME+TASK    taskwarrior (ctx-namespaced) + timewarrior (auto-start on task start) +
                Pomodoro/break daemon + "start ritual" (pick task → timer → open context)
L3 SURFACING    eww BAR (context · task+timer · #live sessions/agents · argocd/signoz glyph ·
                PR count · next event) + eww DASHBOARD (Today / Live work / Infra / Rituals /
                Learning) + eww SWITCHER (fuzzy jump across tmux sessions + Claude projects)
L4 BROWSER      Zen (vertical tabs + compact + workspaces) · Tridactyl rc · Multi-Account
                Containers · rofi profile launcher · wifi/bt/system menus
L5 LOOK+HYGIENE Dracula token system → i3/rofi/polybar/kitty/picom · themed lock/login/wallpaper ·
                fix repo drift · secrets hygiene
```

**Design principles**
- Each layer is independently usable and testable; layers talk through small,
  documented interfaces (a file, a CLI, an HTTP endpoint), not shared internals.
- One palette source of truth (`themes/dracula.*`) feeds every component by
  generation/import — never hand-copied hex.
- The system decides; the operator executes. Defaults everywhere.

## 5. Aesthetic

**Dracula**, everywhere. The eww notification center is already Dracula and is
the reference. Everything else (i3, rofi, polybar→eww, kitty, picom tints) is
re-themed *to* Dracula. Per-context accent colors (§3) ride on top of the base
palette. Font stays JetBrainsMono Nerd Font.

## 6. Vault integration (capture-now, integrate-later)

- **Now:** desktop writes captures and daily-note entries through
  `local-rest-api` (`:27124`, API key in `~/.secrets`). Target a single inbox
  surface — `journal/daily/DD-MM-YYYY.md` under an `## Inbox` heading (created
  from a Templater daily template if missing).
- **Seams for later:** captures carry a `context` tag and ISO timestamp so the
  eventual vault runtime can route them into the 7-layer model without rework.
- We do **not** touch `blueprint/`, `agents/`, or the meta-system spec.

## 7. Roadmap

| Phase | Delivers | Pains | Effort | Deps |
|---|---|---|---|---|
| **0 Foundation** | secrets hygiene · fix repo drift · Dracula token system + retheme i3/rofi/polybar/kitty · deploy script + README | "fix & finish" | ½–1d | — |
| **1 ADHD core** | taskwarrior+timewarrior configured · capture keybind→vault · Pomodoro/break daemon · start-ritual | A,B,C,#2,#3 | 1–2d | 0 |
| **2 Surfacing** | eww bar · control-center dashboard · session/agent switcher | #1,#4,D + pillars | 2–3d | 1 |
| **3 Browser** | Zen+Tridactyl+Containers · rofi profile launcher · wifi/system menus | #6,E | 1d | 0 |
| **4 Polish** | themed lock/login · wallpaper-per-context · animations | finish | ½d | 0–3 |

Each phase gets its own implementation plan and review gate.

---

## 8. Phase 0 spec — Foundation & hygiene

**Goal:** a clean, secure, single-theme base that every later phase inherits.

### 0.1 Secrets hygiene
- Rotate the OpenAI key currently plaintext in `~/.zshrc` (`CZ_OPENAI_API_KEY`)
  and the LiteLLM key. (Operator action — Claude cannot rotate provider keys.)
- Create `~/.secrets` (chmod 600, gitignored), move both keys there, `source` it
  from `~/.zshrc`. Add the Obsidian REST API key here too (for Phase 1).
- Acceptance: `git grep` over dotfiles finds no `sk-` / API tokens; new shell
  still has the env vars.

### 0.2 Fix repo drift (the "fix & finish" scope item)
- **Missing scripts** referenced by `i3/config` but absent: `rofilaunch.sh`,
  `rofi-style-selector.sh`, `rofi-websearch-v2.sh`, `zen-tab-popup.sh`,
  `zen-workspaces.sh`. For each: either commit the real script (if it exists on
  disk in `~/.config/rofi/scripts/`) or repoint the binding to the existing
  equivalent (e.g. `rofi-websearch.sh`) and update README + tests.
- **Failing tests:** reconcile `i3/config` ↔ `rofi/README.md` ↔
  `rofi/tests/test_i3_keybindings.bats` to one keybinding scheme; get the suite
  to **146/146**.
- **picom path bug:** `picom/launch.sh` loads `~/.config/picom.conf` but the file
  deploys to `~/.config/picom/picom.conf`; fix the path. Sync README's picom
  numbers (blur strength, opacity) to the actual config, or add the missing
  `class_g = 'Rofi'` opacity rule the blur trick documents.
- Acceptance: `cd rofi/tests && bats test_*.bats` → 0 failures; every script a
  binding references exists in-repo; picom launches from the deployed path.

### 0.3 Dracula token system
- Create `themes/dracula.yaml` (or `.sh`) as the **single palette source**:
  base `#282A36`, bg-dark `#141313`, fg `#F8F8F2`, comment `#6272A4`,
  purple `#BD93F9`, pink `#FF79C6`, cyan `#8BE9FD`, green `#50FA7B`,
  orange `#FFB86C`, red `#FF5555`, yellow `#F1FA8C`, plus the four context accents.
- Generate/derive per-app theme files from it: i3 colors, rofi
  `themes/shared/dracula.rasi` (replacing catppuccin-mocha), polybar `[colors]`,
  kitty `current-theme.conf`, picom tint. A small `scripts/gen-theme.sh` renders
  all targets from the token file so future palette edits are one-touch.
- Acceptance: changing one hex in the token file + running `gen-theme.sh` updates
  every component; no component contains a hand-typed Dracula hex.

### 0.4 Deploy mechanism + README
- Add `install.sh` (GNU Stow or explicit symlinks) mapping repo dirs →
  `~/.config/*`, plus a top-level `README.md` (install, layout, theme, phases).
- Acceptance: a fresh `install.sh` run symlinks all configs correctly; documented.

## 9. Phase 1 spec — ADHD core

**Goal:** capture nothing-is-lost + a task/time engine that makes starting cheap
and the day observable.

### 1.1 taskwarrior
- `~/.taskrc` with context-namespaced projects (`work.*`, `lab.*`, `agents.*`,
  `personal.*`), urgency tuned for ADHD (small, near-term, "next" tag), and
  `task context` definitions matching the four contexts.
- Acceptance: `task add project:work.ats "x"`, `task work next` filters correctly.

### 1.2 timewarrior + hook
- Initialize timewarrior; install the `on-modify` taskwarrior hook so starting a
  task (`task start`) auto-starts a timew interval tagged with the project +
  context; stopping/done stops it.
- Acceptance: `task start <id>` produces a running `timew` interval with the
  right tags; `timew summary` shows per-context time.

### 1.3 Capture keybind
- `scripts/capture.sh`: pop a minimal rofi (or eww) single-line input; on submit,
  POST to Obsidian REST `:27124` appending to today's `## Inbox`; if the text
  starts with `t:` / `task:`, also `task add` it into the current context.
- Bind in i3 (e.g. `$mod+Shift+space`). Current context read from a state file
  `~/.cache/ctx` (written by the context switcher; defaults to `personal`).
- Acceptance: keybind → type → entry lands in today's daily note within ~1s;
  `t: …` also creates a task; works with no Obsidian window focused.

### 1.4 Pomodoro / break daemon
- `scripts/focus.sh` (+ a tiny state file) driving work/break intervals with
  dunst notifications at boundaries; optional soft-lock or screen-dim on break;
  integrates with timew (a focus block = a timew tag).
- Acceptance: start a 25/5 cycle; notifications fire at boundaries; time recorded.

### 1.5 Start ritual
- `scripts/start.sh`: rofi-pick a `next` task → `task start` (→ timer) → switch to
  its context (browser profile group + tmux session) → begin. One command from
  "I should work" to "working."
- Acceptance: one invocation selects a task, starts the timer, and lands the
  operator in the right tmux session + browser context.

---

## 10. Open questions for review

1. **Context list final?** Four contexts (work/lab/agents/personal) with the
   tmux/dir mapping in §3 — correct, or split/merge any?
2. **Capture target:** daily-note `## Inbox` (chosen) vs a dedicated
   `journal/inbox.md` rolling file — preference?
3. **Break enforcement strength:** soft (notification only) vs hard (dim/lock)
   on Pomodoro breaks?
4. **Phase 0.2 scope:** if the five "missing" scripts genuinely don't exist on
   disk, are you OK with me repointing those bindings to existing equivalents
   rather than writing new menu scripts now (deferring new menus to later)?
5. **Stow vs symlink** for `install.sh` — any preference?
```
