---
name: cc-bridle preflight
description: Run preflight safety check. Reads CLAUDE.md and Plans.md to list permissions and flag dangerous commands.
triggers:
  - /cc-bridle preflight
  - user asks for preflight check
---

Run `node scripts/preflight.js` from the project root and display the results.
