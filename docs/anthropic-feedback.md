# Teks laporan fitur untuk Anthropic (Claude Code)

Untuk dikirim pengguna lewat `/feedback` di Claude Code. Bahasa Inggris agar mudah dibaca tim produk.

**Title:** Expose the outcome of a PreToolUse "ask" permission prompt to the model and to PostToolUse hooks

**Problem**
A PreToolUse hook can return `permissionDecision: "ask"`. The reason is shown only to the user. After the user approves, the tool runs and the model only sees a successful tool result. It cannot tell that the user explicitly approved the action, so it sometimes reports the action as having run "without a prompt" or without approval, and it cannot reason correctly about gates built with "ask".

**What we looked for**
- Docs state `permissionDecisionReason` for "ask" is shown to the user; for "deny" it is shown to Claude.
- PostToolUse input has `tool_use_id`, `tool_response`, `permission_mode`, but no field for the earlier permission outcome (asked and approved / auto-allowed / allowed by rule).
- No hook event reports the user's answer to an "ask" prompt.

**Requested**
One of: (a) add a `permission_outcome` field (e.g. `approved_by_user`, `allowed_by_rule`, `auto_approved`) to PostToolUse input and optionally to the tool result the model sees; or (b) document and guarantee that `additionalContext` returned together with `permissionDecision: "ask"` reaches the model once the user approves.

**Why it matters**
Frameworks that gate risky actions behind user confirmation need the agent to report honestly what happened. Today the only workaround is a PreToolUse marker plus a PostToolUse hook, which is inference and can mislabel auto-approved calls.
