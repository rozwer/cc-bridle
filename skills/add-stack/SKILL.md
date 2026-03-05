---
name: cc-bridle add-stack
description: Add a custom stack detection rule to detect-rules-extra.json for this project or globally.
triggers:
  - /cc-bridle add-stack <stack-id>
  - user asks to detect a new stack or project type
---

## Usage

When the user invokes this skill, interactively ask:
1. Stack ID (e.g. "my-framework")
2. Files that must ALL exist (files_all), comma-separated
3. Files where at least ONE must exist (files_any), comma-separated (optional)
4. Files that must NOT exist (files_none), comma-separated (optional)
5. Scope: global (detect-rules.json) or project-specific (detect-rules-extra.json)

Then append the new rule to the appropriate file and confirm.
