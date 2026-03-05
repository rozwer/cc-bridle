---
name: cc-bridle stats
description: Show usage statistics from stats.jsonl — tool/skill usage counts, top 5, and optimization suggestions.
triggers:
  - /cc-bridle stats
  - user mentions statistics, stats, 使用状況, usage
---

## What this skill does

1. Read `~/.claude/cc-bridle/stats.jsonl`
2. Aggregate by tool name and skill name
3. Display top 5 most-used tools and any unused skills
4. Show failed operations (success:false) by command
5. Suggest: "同じ操作を繰り返している場合はスキルにまとめることを推奨"

## Usage

Run the following inline Node.js to display statistics:

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

## Output format

- Top 5 most-used tools with usage counts
- Skill usage breakdown (if any skills have been invoked via Agent tool)
- Failed operations grouped by tool
- Optimization suggestions for frequently repeated operations
