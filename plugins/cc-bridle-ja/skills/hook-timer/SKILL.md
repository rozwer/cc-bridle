---
name: hook-timer
description: hook-timer.jsonl からフック実行タイミングを表示します。500ms 超のフックを「要最適化」として強調します。
triggers:
  - hook-timer
  - ユーザーが遅いフック、フックのパフォーマンスについて言及した場合
---

## このスキルの機能

`~/.claude/cc-bridle/hook-timer.jsonl` を読み込んで以下を表示します:
- hook_name ごとの平均・最大・最小実行時間
- 500ms を超えるフックを「要最適化」としてマーク

## 使い方

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

## 設定

警告の閾値は `~/.claude/cc-bridle/config.json` でカスタマイズできます:

```json
{
  "hook_timer_threshold_ms": 500
}
```

この閾値を超えるフックは実行中に stderr へ警告を出力し、このレポートでは「要最適化」として強調されます。
