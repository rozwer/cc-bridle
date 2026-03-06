---
name: stats
description: stats.jsonl からの使用統計を表示します — ツール/スキル使用回数、トップ5、最適化提案。
triggers:
  - stats
  - ユーザーが統計、stats、使用状況、usage について言及した場合
---

## このスキルの機能

1. `~/.claude/cc-bridle/stats.jsonl` を読み込む
2. ツール名とスキル名で集計する
3. 最も多く使われたツールのトップ5と未使用スキルを表示する
4. コマンド別の失敗した操作（success:false）を表示する
5. 提案: 「同じ操作を繰り返している場合はスキルにまとめることを推奨」

## 使い方

以下のインライン Node.js を実行して統計を表示します:

```bash
node -e "
const fs = require('fs');
const os = require('os');
const path = require('path');

const statsFile = path.join(os.homedir(), '.claude', 'cc-bridle', 'stats.jsonl');
if (!fs.existsSync(statsFile)) {
  console.log('No stats recorded yet. Run some tools first.');
  process.exit(0);
}

const lines = fs.readFileSync(statsFile, 'utf8').trim().split('\n').filter(Boolean);
const records = lines.map(l => { try { return JSON.parse(l); } catch(_) { return null; } }).filter(Boolean);

// Aggregate by tool
const toolCounts = {};
const skillCounts = {};
const failures = [];

for (const r of records) {
  if (r.tool) toolCounts[r.tool] = (toolCounts[r.tool] || 0) + 1;
  if (r.skill) skillCounts[r.skill] = (skillCounts[r.skill] || 0) + 1;
  if (r.success === false) failures.push(r);
}

// Top 5 tools
const top5 = Object.entries(toolCounts).sort((a, b) => b[1] - a[1]).slice(0, 5);
console.log('=== Top 5 Most-Used Tools ===');
top5.forEach(([tool, count]) => console.log(\`  \${tool}: \${count} uses\`));

// Skills used
if (Object.keys(skillCounts).length > 0) {
  console.log('\n=== Skill Usage ===');
  Object.entries(skillCounts).sort((a, b) => b[1] - a[1]).forEach(([skill, count]) => {
    console.log(\`  \${skill}: \${count} uses\`);
  });
}

// Failures
if (failures.length > 0) {
  console.log(\`\n=== Failed Operations (\${failures.length} total) ===\`);
  const failByTool = {};
  failures.forEach(r => { failByTool[r.tool] = (failByTool[r.tool] || 0) + 1; });
  Object.entries(failByTool).sort((a, b) => b[1] - a[1]).forEach(([tool, count]) => {
    console.log(\`  \${tool}: \${count} failures\`);
  });
}

// Optimization suggestion
console.log('\n=== Optimization Suggestions ===');
const highFreqTools = top5.filter(([, count]) => count >= 5);
if (highFreqTools.length > 0) {
  console.log('同じ操作を繰り返している場合はスキルにまとめることを推奨');
  highFreqTools.forEach(([tool, count]) => {
    console.log(\`  - \${tool} が \${count} 回使用されています\`);
  });
} else {
  console.log('現時点では最適化の提案はありません。');
}
"
```

## 出力フォーマット

- 使用回数付きのトップ5最多使用ツール
- スキル使用の内訳（Agent ツール経由でスキルが呼び出された場合）
- ツール別にグループ化された失敗した操作
- 頻繁に繰り返される操作に対する最適化提案
