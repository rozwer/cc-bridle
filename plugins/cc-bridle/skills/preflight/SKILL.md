---
name: preflight
description: Run preflight safety check. Reads CLAUDE.md and Plans.md to list permissions and flag dangerous commands.
triggers:
  - preflight
  - user asks for preflight check
---

Run `node ${CLAUDE_PLUGIN_ROOT}/scripts/preflight.js` from the project root and display the results.
