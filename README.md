# Kaiju Battle Arena - Roblox Game

A thrilling kaiju-themed battle game where players can choose to be giant monsters or city defenders!

(Existing documentation preserved; below are developer onboarding additions to help with MCP, linting, and hooks.)

## Developer Onboarding (Additions)

### Local tooling
- Install dependencies:
  - mise (package manager used by the project)
  - Selene (Luau linter): https://github.com/Kampfar/selene
  - A Luau formatter (luau-format, luauformat, or luafmt)
  - Rojo (for syncing with Roblox Studio)

Example (macOS / Linux / Windows WSL):
```bash
mise install
# install Selene (example)
cargo install selene
```

### MCP (Roblox Studio integration)
This repository is configured with an MCP entry for local Roblox Studio automation: see [`.kilocode/mcp.json`](.kilocode/mcp.json:1). The MCP server binary used on Windows is referenced there.

- To run MainModule inspection via MCP:
  1. Start Roblox Studio and open your place file (e.g. `KaijuBattleRoblox.rbxlx`).
  2. Start the MCP server/client specified in [` .kilocode/mcp.json`](.kilocode/mcp.json:1) (on Windows this is the provided rbx-studio-mcp executable).
  3. Use the MCP run_code tool to send the contents of [`src/server_code/DirectLogMainModule.luau`](src/server_code/DirectLogMainModule.luau:1) or call `src/server_code/RunMainModuleViaMCP.luau` with your MCP client.

### Pre-commit hooks
To enable the repository's pre-commit behavior (format/lint/strict header checks):

- Option A (recommended):
  git config core.hooksPath .githooks

- Option B (Windows fallback):
  pwsh tools/install-githooks.ps1

The pre-commit hook will run:
- [`./scripts/format_and_lint.sh`](scripts/format_and_lint.sh:1) or the PowerShell equivalent
- [`./scripts/ensure_strict.sh`](scripts/ensure_strict.sh:1)

If these tools modify files, the commit will be blocked and you'll be asked to review & stage the changes.

### CI
The repository CI job runs:
- Formatting & linting
- Strict header enforcement (failing the build if it adds headers)
- Tests (see `.github/workflows/tests.yml`)

### Common commands
- Format and lint locally:
  - Unix: `./scripts/format_and_lint.sh`
  - Windows PowerShell: `./scripts/format_and_lint.ps1`
- Ensure strict headers:
  - `./scripts/ensure_strict.sh`
- Run tests locally (if Luau CLI available):
  - `luau test_runner.luau --verbose`

(End of additions. Original README content retained above.)
