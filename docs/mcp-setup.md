# MCP (Roblox Studio) Setup & Runbook

This document explains how to run in-Studio diagnostics and automation using the repository's MCP configuration and helpers.

Important files
- MCP config: [`.kilocode/mcp.json`](.kilocode/mcp.json:1)
- Diagnostic script (send to run_code): [`src/server_code/DirectLogMainModule.luau`](src/server_code/DirectLogMainModule.luau:1)
- Programmatic runner: [`src/server_code/RunMainModuleViaMCP.luau`](src/server_code/RunMainModuleViaMCP.luau:1)
- MCP helper library (retries/timeouts): [`src/server_code/MCPHelpers.luau`](src/server_code/MCPHelpers.luau:1)
- Local wrappers:
  - Unix: [`scripts/run_main_via_mcp.sh`](scripts/run_main_via_mcp.sh:1)
  - Windows PowerShell: [`scripts/run_main_via_mcp.ps1`](scripts/run_main_via_mcp.ps1:1)
- Pre-commit hook: [`.githooks/pre-commit`](.githooks/pre-commit:1)
- Hook installer: [`tools/install-githooks.ps1`](tools/install-githooks.ps1:1)
- `--!strict` helper: [`scripts/ensure_strict.sh`](scripts/ensure_strict.sh:1)

Prerequisites
- Roblox Studio (open the place you want to debug).
- The MCP client/binary that communicates with Roblox Studio (the repo uses a local MCP binary on Windows; see [`.kilocode/mcp.json`](.kilocode/mcp.json:1)).
- A local shell (bash / PowerShell) and the repository cloned.

Configure MCP client
1. Inspect the repo MCP entry: [`.kilocode/mcp.json`](.kilocode/mcp.json:1).
2. Ensure the command path is correct for your platform. On Windows the repo config points at a local binary; on macOS/Linux you may use a different MCP client.
3. Start Roblox Studio and load your place file (for example, `KaijuBattleRoblox.rbxlx`).
4. Start the MCP client that can talk to the running Studio instance.

Quick: run an inspection (recommended)
- Send the diagnostic script to Studio via the wrapper (Unix):
  - MCP client available in PATH:
    - MCP_CMD=/path/to/rbx-studio-mcp ./scripts/run_main_via_mcp.sh
  - Or explicitly:
    - ./scripts/run_main_via_mcp.sh src/server_code/DirectLogMainModule.luau /path/to/rbx-studio-mcp
- Windows PowerShell:
  - .\scripts\run_main_via_mcp.ps1 -ScriptPath .\src\server_code\DirectLogMainModule.luau
  - It will attempt to auto-detect the MCP command from [`.kilocode/mcp.json`](.kilocode/mcp.json:1).

What the diagnostic does
- [`src/server_code/DirectLogMainModule.luau`](src/server_code/DirectLogMainModule.luau:1) inspects ServerScriptService for `MainModule`, logs its Source/length, tries to require it (pcall) and optionally calls its init method to report results. Use it as the first step when startup or system-loading issues occur.

Programmatic runner
- [`src/server_code/RunMainModuleViaMCP.luau`](src/server_code/RunMainModuleViaMCP.luau:1) uses [`src/server_code/MCPHelpers.luau`](src/server_code/MCPHelpers.luau:1) to run the same checks with retry and timeout behavior. This is useful when you need a more resilient automated invocation (CI or local scripts that call the MCP client).

Best practices
- Always open Studio before sending run_code payloads.
- Keep run_code payloads small and idempotent — avoid long blocking operations.
- Use retries/timeouts provided by [`src/server_code/MCPHelpers.luau`](src/server_code/MCPHelpers.luau:1) for automation.
- Document asset placeholders when you use the MCP `insert_model` feature during development.

Troubleshooting
- If the wrapper reports "MCP command not found":
  - Make sure the MCP binary is installed and in PATH or pass its absolute path to the wrapper.
  - On Windows, the repo includes the Windows MCP path in [`.kilocode/mcp.json`](.kilocode/mcp.json:1). Use that path or set environment variable MCP_CMD.
- If the script can't find `MainModule`:
  - Verify you're connected to the correct place in Studio.
  - Confirm `MainModule` exists under `ServerScriptService` (check the Output or Explorer in Studio).
- If `require` fails in Studio:
  - Inspect the trace and error printed by the diagnostic; fix syntax/type errors and re-run.

Automation & CI notes
- CI runs formatting, linting, and tests as part of the workflow [`.github/workflows/tests.yml`](.github/workflows/tests.yml:1). Studio-only checks that require a running Studio instance must be run manually or on infrastructure you provide (self-hosted runner with Studio + MCP).
- The repo provides wrappers to make local invocations easy. Extend them in CI if you supply self-hosted Studio runners.

Developer setup checklist
1. Install MCP client and ensure it can talk to running Studio.
2. Install Selene / Luau formatter as described in `README.md`.
3. Run:
   - Unix: `./scripts/format_and_lint.sh`
   - Windows PowerShell: `./scripts/format_and_lint.ps1`
4. Ensure `--!strict` headers: `./scripts/ensure_strict.sh`
5. Install git hooks (recommended):
   - `git config core.hooksPath .githooks`
   - Or on Windows: `pwsh .\tools\install-githooks.ps1`
6. Use the wrappers to send diagnostics:
   - `./scripts/run_main_via_mcp.sh` or `.\scripts\run_main_via_mcp.ps1`

Further reading
- See main dev rules: [`roblox-dev-rules.md`](roblox-dev-rules.md:1)
- CI workflow: [`.github/workflows/tests.yml`](.github/workflows/tests.yml:1)
- Pre-commit hook: [`.githooks/pre-commit`](.githooks/pre-commit:1)