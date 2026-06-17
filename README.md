# ubuntu-dots

Personal Ubuntu 24.04 / X11 / i3 dotfiles — managed with **chezmoi**, themed
**Dracula**, evolving into a context-driven ADHD-support desktop.

> Full design: [`docs/superpowers/specs/2026-06-18-adhd-os-design.md`](docs/superpowers/specs/2026-06-18-adhd-os-design.md)
> Phase plans: [`docs/superpowers/plans/`](docs/superpowers/plans/) · Mockup: [`docs/superpowers/mockups/`](docs/superpowers/mockups/)

## Model

This repo **is** the chezmoi source directory. chezmoi renders/deploys it to `$HOME`.

- `dot_config/…`  → `~/.config/…`  (the deployed configs: i3, rofi, polybar, kitty, picom)
- `encrypted_private_dot_secrets.age` → `~/.secrets` (age-decrypted on apply)
- `.chezmoidata.yaml` — the **single Dracula palette** every themed config templates from
- `.chezmoiignore` — keeps non-deploy paths (`docs/`, `tests/`, `keyd/`) out of `$HOME`
- `*.tmpl` files are Go templates (colors pulled from `.chezmoidata.yaml`)

Not deployed (repo tooling): `docs/` (specs, plans, mockups), `tests/` (bats),
`keyd/` (system-level, lives at `/etc/keyd`).

## Install on a new machine

```bash
# prerequisites
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin   # chezmoi
sudo apt-get install -y age                                # age (encryption)

# restore your age key to ~/.config/chezmoi/key.txt (from your password manager), then:
chezmoi init https://github.com/shaiknoorullah/ubuntu-dots   # or your remote
chezmoi diff        # preview every change before it touches ~
chezmoi apply       # deploy
```

`~/.config/chezmoi/chezmoi.toml` sets `sourceDir`, `encryption = "age"`, and the
key path/recipient.

## Theme

**Dracula** (the operator's own variant — base `#1a1a2e`, fg `#f8f8f2`, purple
`#bd93f9`, green `#50fa7b`, red `#ff4d4d`, orange `#ff9e3b`, yellow `#f5d547`),
defined once in `.chezmoidata.yaml`. Change a hex there + `chezmoi apply` →
every templated config updates.

- **Templated to the palette:** i3 borders, kitty colors.
- **Already Dracula (left as-is):** polybar, the eww notification center.
- **Pending:** rofi (its live `style_N` themes will be **replaced by eww shell
  widgets**, not retro-themed).

## Secrets

API keys live in `~/.secrets` (sourced by `~/.zshrc`), managed **age-encrypted**
by chezmoi. The decrypt key is `~/.config/chezmoi/key.txt` — **never committed;
back it up to your password manager** (losing it = unrecoverable secrets).

## Status

- **Phase 0 (foundation): complete** — drift fixed, secrets encrypted, chezmoi
  adopted the real live config, i3 + kitty on Dracula.
- Phase 1+ (capture, time/task engine, 3-bar eww UI, browser, data plane): see the spec.

### Known

- The `tests/` bats suite was written for the **legacy** rofi scripts; live
  scripts have since evolved (Zen, `simple.rasi`). It will be retired alongside
  the rofi → eww-widget migration; not maintained against the legacy scripts.
