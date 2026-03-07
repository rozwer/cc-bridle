'use strict';

function parseHookInput(raw) {
  if (!raw || !raw.trim()) {
    return { toolName: '', toolInput: {}, cwd: process.cwd() };
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (_) {
    return { toolName: '', toolInput: {}, cwd: process.cwd() };
  }

  const toolName =
    typeof parsed.tool_name === 'string' ? parsed.tool_name :
    typeof parsed.tool === 'string' ? parsed.tool :
    '';

  const toolInput =
    parsed.tool_input && typeof parsed.tool_input === 'object' ? parsed.tool_input :
    parsed.input && typeof parsed.input === 'object' ? parsed.input :
    {};

  const cwd = typeof parsed.cwd === 'string' && parsed.cwd ? parsed.cwd : process.cwd();

  return { toolName, toolInput, cwd, raw: parsed };
}

function emitPreToolDecision(permissionDecision, reason, legacyDecision) {
  const payload = {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision,
      permissionDecisionReason: reason,
    },
  };

  if (legacyDecision) {
    payload.decision = legacyDecision;
    payload.reason = reason;
  }

  process.stdout.write(JSON.stringify(payload) + '\n');
}

module.exports = {
  emitPreToolDecision,
  parseHookInput,
};
