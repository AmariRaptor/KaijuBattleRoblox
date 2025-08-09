# Roblox Development Rules

Always use the 'Roblox Studio' MCP server's run_code tool to execute and inspect the project's MainModule during development. When debugging initialization or systems-loading issues prefer the run_code approach to get live, in-engine diagnostics.

## 1. Strictly-Typed Luau
- Use the `.luau` extension for all source files.
- Enforce `--!strict` at the top of all scripts. Use the helper script: [`scripts/ensure_strict.sh`](scripts/ensure_strict.sh:1).
- Add explicit type annotations for variables, parameters and return types wherever possible.

## 2. Auto-Fix Linting
- Use Selene for linting. The configuration is in [`selene.toml`](selene.toml:1).
- To format and lint locally, run:

```bash
./scripts/format_and_lint.sh
# on Windows (PowerShell)
./scripts/format_and_lint.ps1
```

- CI runs formatting and linting as part of the test workflow: see [`.github/workflows/tests.yml`](.github/workflows/tests.yml:1).

## 3. Asset Management
- Use the MCP `insert_model` tool for placeholder assets during development; prefer Marketplace assets for final content.
- Document any marketplace substitutions in the asset manifest (create one when replacing placeholders).

## 4. Test-Driven Development
- Add unit tests for new modules using the project's test framework. See examples in [`src/tests/MainModule.spec.luau`](src/tests/MainModule.spec.luau:1) and [`src/TestEZ/TestRunner.luau`](src/TestEZ/TestRunner.luau:1).
- Tests may use global helpers provided by the test framework (describe/it/expect).
- Run tests locally using the same command CI uses:

```bash
luau test_runner.luau --verbose
```

## 5. Roblox Studio Integration (MCP)
- Always prefer the 'Roblox Studio' MCP server's `run_code` function to inspect the live environment. The MCP entry configured for this repo is [` .kilocode/mcp.json`](.kilocode/mcp.json:1).
- Quick inspection helpers:
  - [`src/server_code/DirectLogMainModule.luau`](src/server_code/DirectLogMainModule.luau:1) — paste or send this script to `run_code` to inspect `MainModule` source, require it, and attempt to initialize it. This is the recommended first step when debugging startup issues.
  - [`src/server_code/RunMainModuleViaMCP.luau`](src/server_code/RunMainModuleViaMCP.luau:1) — helper module that uses [`src/server_code/MCPHelpers.luau`](src/server_code/MCPHelpers.luau:1) to run and initialize `MainModule` via an MCP run_code client (supports retries/timeouts).
- Example workflow (manual):
  1. Open Roblox Studio with the target place loaded.
  2. Start your MCP client that talks to Studio (e.g. the binary configured in [` .kilocode/mcp.json`](.kilocode/mcp.json:1)).
  3. Send the contents of [`src/server_code/DirectLogMainModule.luau`](src/server_code/DirectLogMainModule.luau:1) to the MCP `run_code` tool.
  4. Inspect the output for errors and warnings, then iterate.

## 6. Performance & Robustness
- Use timeouts and retry logic for MCP requests. See [`src/server_code/MCPHelpers.luau`](src/server_code/MCPHelpers.luau:1), which provides `run_code_with_retry`.
- Avoid long-running synchronous operations during init; prefer spawned tasks and time-bounded operations.

## 7. CI & Pre-commit Hooks
- CI workflow enforces formatting, linting, strict headers, and test execution. See [`.github/workflows/tests.yml`](.github/workflows/tests.yml:1).
- To install pre-commit hooks locally:

```bash
git config core.hooksPath .githooks
# or with PowerShell (Windows):
pwsh .\tools\install-githooks.ps1
```

- The repository includes a pre-commit hook at [`.githooks/pre-commit`](.githooks/pre-commit:1) that runs format/lint and `ensure_strict`.

## Quick reference (summary)
- Format & lint: [`./scripts/format_and_lint.sh`](scripts/format_and_lint.sh:1) / [`./scripts/format_and_lint.ps1`](scripts/format_and_lint.ps1:1)
- Ensure strict: [`./scripts/ensure_strict.sh`](scripts/ensure_strict.sh:1)
- Inspect MainModule in Studio: [`src/server_code/DirectLogMainModule.luau`](src/server_code/DirectLogMainModule.luau:1) via MCP `run_code`
- MCP helpers: [`src/server_code/MCPHelpers.luau`](src/server_code/MCPHelpers.luau:1)

## Notes
- Tests are excluded from auto-format where necessary to preserve spec structure (`.spec.luau` files are excluded in [` .luau-format`](.luau-format:1)).
- If CI fails due to missing `--!strict` headers, run [`./scripts/ensure_strict.sh`](scripts/ensure_strict.sh:1) and commit the changes.

---
This document is enforced by repository scripts and CI. If you need help setting up the MCP client or running the tooling, open an issue or mention the repo maintainers.