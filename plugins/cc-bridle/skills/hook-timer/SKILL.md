---
name: hook-timer
description: Show hook execution timing from hook-timer.jsonl. Highlights slow hooks over 500ms.
triggers:
  - hook-timer
  - user mentions slow hooks, hook performance, パフォーマンス
---

## What this skill does

Read `~/.claude/cc-bridle/hook-timer.jsonl` and display:
- Average, max, min duration per hook_name
- Hooks exceeding 500ms marked as "要最適化"

## Usage

```bash
node -e "
const fs = require('fs');
const os = require('os');
const path = require('path');

const timerFile = path.join(os.homedir(), '.claude', 'cc-bridle', 'hook-timer.jsonl');
if (!fs.existsSync(timerFile)) {
  console.log('No hook timing data recorded yet.');
  process.exit(0);
}

const lines = fs.readFileSync(timerFile, 'utf8').trim().split('\n').filter(Boolean);
const records = lines.map(l => { try { return JSON.parse(l); } catch(_) { return null; } }).filter(Boolean);

// Aggregate by hook_name
const byHook = {};
for (const r of records) {
  const key = r.hook_name || 'unknown';
  if (!byHook[key]) byHook[key] = [];
  byHook[key].push(r.duration_ms);
}

const THRESHOLD = 500;
console.log('=== Hook Execution Timing ===');
console.log('hook_name       | avg (ms) | max (ms) | min (ms) | status');
console.log('----------------|----------|----------|----------|--------');

for (const [hookName, durations] of Object.entries(byHook)) {
  const avg = Math.round(durations.reduce((a, b) => a + b, 0) / durations.length);
  const max = Math.max(...durations);
  const min = Math.min(...durations);
  const status = max > THRESHOLD ? '要最適化' : 'OK';
  console.log(\`\${hookName.padEnd(16)}| \${String(avg).padEnd(9)}| \${String(max).padEnd(9)}| \${String(min).padEnd(9)}| \${status}\`);
}

const slowHooks = Object.entries(byHook).filter(([, durations]) => Math.max(...durations) > THRESHOLD);
if (slowHooks.length > 0) {
  console.log('\n=== Slow Hooks (要最適化) ===');
  slowHooks.forEach(([hookName, durations]) => {
    const max = Math.max(...durations);
    console.log(\`  \${hookName}: 最大 \${max}ms（閾値: \${THRESHOLD}ms）\`);
  });
  console.log('\n遅い hook は処理を分割するか、非同期化することを検討してください。');
}
"
```

## Configuration

The warning threshold can be customized in `~/.claude/cc-bridle/config.json`:

```json
{
  "hook_timer_threshold_ms": 500
}
```

Hooks exceeding this threshold will emit a warning to stderr during execution and will be highlighted as "要最適化" in this report.
