# SpecKit Master Quickstart Guide

## Complete Workflow with All Steps

```text
┌─────────────────────────────────────────────────────────────┐
│                    SpecKit Full Workflow                     │
└─────────────────────────────────────────────────────────────┘

1. /speckit.specify     ← START: Create specification
   │
   ├─→ spec.md (user stories, requirements, success criteria)
   │
   ↓
2. /speckit.clarify     ← OPTIONAL: Resolve ambiguities
   │                      (Run BEFORE planning)
   ├─→ Updates spec.md with Q&A clarifications
   │
   ↓
3. /speckit.plan        ← Create implementation plan
   │
   ├─→ plan.md (architecture)
   ├─→ research.md (design decisions)
   ├─→ data-model.md (entities, flows)
   ├─→ contracts/ (API specs)
   └─→ quickstart.md (developer guide)
   │
   ↓
4. /speckit.tasks       ← Break down into tasks
   │
   ├─→ tasks.md (detailed task list by user story)
   │
   ↓
5. /speckit.analyze     ← OPTIONAL: Validate consistency
   │                      (Run AFTER tasks)
   ├─→ Analysis report (validation results)
   │
   ↓
6. /speckit.implement   ← OPTIONAL: Write the code
   │                      (Iterative, can repeat)
   ├─→ Code changes
   ├─→ Tests
   └─→ Commits
   │
   ↓
7. Merge & Ship! 🚀
```

## When to Use Each Step

| Step | Required? | When to Use | When to Skip |
|------|-----------|-------------|--------------|
| **specify** | ✅ ALWAYS | Starting any feature | Never |
| **clarify** | ⚠️ OPTIONAL | Spec has ambiguities, design decisions needed | Spec is crystal clear, retrospective docs |
| **plan** | ✅ ALWAYS | Need technical architecture | Never |
| **tasks** | ✅ ALWAYS | Need actionable breakdown | Never |
| **analyze** | ⚠️ OPTIONAL | Want quality validation | Confident in quality, time-constrained |
| **implement** | ⚠️ OPTIONAL | Ready to code | Manual implementation, docs-only |

## Common Workflows

### 🆕 New Feature (Full Flow)

```bash
/speckit.specify   # Define feature
/speckit.clarify   # Resolve ambiguities (while fresh!)
/speckit.plan      # Design architecture
/speckit.tasks     # Break into tasks
/speckit.analyze   # Validate (optional QA check)
/speckit.implement # Build it
```

### 📚 Retrospective Documentation

```bash
/speckit.specify   # Document what exists
/speckit.plan      # Capture architecture
/speckit.tasks     # List completed tasks
# Skip: clarify (already built), analyze (not needed), implement (done)
```

### ⚡ Quick Prototype/Spike

```bash
/speckit.specify   # Minimal spec
/speckit.plan      # Quick design
/speckit.implement # Code directly
# Skip: clarify (exploratory), tasks (too small), analyze (overkill)
```

### 🔍 Design Review Only

```bash
/speckit.specify   # Define proposal
/speckit.clarify   # Interactive design decisions
/speckit.plan      # Document architecture
/speckit.analyze   # Validate completeness
# Skip: tasks (not implementing yet), implement (design phase)
```

## Tips & Best Practices

### ✅ DO

- Run `/speckit.clarify` **before** `/speckit.plan` if you have design questions
- Run `/speckit.analyze` **after** `/speckit.tasks` for quality check
- Use full workflow for features that will ship to users
- Document design decisions in `/speckit.clarify` (captures rationale)

### ❌ DON'T

- Skip `/speckit.specify` (always start with spec!)
- Run `/speckit.clarify` after `/speckit.plan` (too late!)
- Run `/speckit.analyze` before `/speckit.tasks` (nothing to validate)
- Use `/speckit.implement` without `/speckit.tasks` (no roadmap)

## Step Details

### 1. /speckit.specify (MANDATORY)

**Purpose**: Create complete feature specification

**Inputs**: Feature description (user provides)

**Outputs**:

- `specs/{feature-number}-{feature-name}/spec.md` - Complete specification with:
  - User stories with priorities and acceptance scenarios
  - Functional requirements (50+ for complex features)
  - Edge cases and error scenarios
  - Success criteria (measurable outcomes)
  - Key entities and relationships

**When to use**: Always! This is the foundation of everything.

### 2. /speckit.clarify (OPTIONAL)

**Purpose**: Reduce ambiguities through interactive Q&A

**Inputs**: Completed spec.md

**Outputs**:

- Updates spec.md with clarifications section
- Resolves design decisions
- Documents rationale for choices

**When to use**:

- Spec has ambiguous requirements
- Design decisions needed (e.g., "silent by default vs verbose?")
- Multiple implementation approaches possible
- Team needs alignment on approach

**When to skip**:

- Spec is crystal clear
- Retrospective documentation (already implemented)
- Exploratory spike work

**Max questions**: 5 per session (keeps it focused)

### 3. /speckit.plan (MANDATORY)

**Purpose**: Create technical implementation plan

**Inputs**: Completed spec.md (with clarifications if applicable)

**Outputs**:

- `plan.md` - Implementation strategy, technical context, constitution check
- `research.md` - Design decisions with trade-offs (10+ decisions for complex features)
- `data-model.md` - Entities, relationships, data flows
- `contracts/` - API specifications for key operations
- `quickstart.md` - Developer getting-started guide

**When to use**: Always! Captures the "how" after defining the "what".

### 4. /speckit.tasks (MANDATORY)

**Purpose**: Break specification into actionable tasks

**Inputs**: Completed spec.md and plan.md

**Outputs**:

- `tasks.md` - Detailed task breakdown with:
  - Tasks organized by user story
  - Parallelization opportunities marked
  - Dependencies documented
  - File paths and acceptance criteria per task

**When to use**: Always! Provides the roadmap for implementation.

### 5. /speckit.analyze (OPTIONAL)

**Purpose**: Validate consistency across spec/plan/tasks

**Inputs**: Completed spec.md, plan.md, tasks.md

**Outputs**:

- Analysis report identifying:
  - Missing requirements
  - Inconsistencies between documents
  - Gaps in task coverage
  - Constitutional compliance issues

**When to use**:

- Want quality assurance before implementation
- Large/complex features (50+ requirements)
- Multiple contributors need validation
- Before major releases

**When to skip**:

- Small features (<10 tasks)
- Time-constrained
- High confidence in quality

### 6. /speckit.implement (OPTIONAL)

**Purpose**: Generate code implementation with tests

**Inputs**: Completed tasks.md

**Outputs**:

- Code changes across relevant files
- Test cases for each user story
- Git commits with conventional commit messages

**When to use**:

- Ready to implement
- Want AI-assisted coding
- Following TDD approach

**When to skip**:

- Prefer manual implementation
- Documentation-only work
- Exploratory prototyping

## Example: Pulsar v0.7.0 (Silent Redesign)

### Recommended Flow

```bash
# 1. Merge current work
git checkout main
git pull
# Merge PR #5 on GitHub

# 2. Start new feature branch
git checkout -b 003-silent-pulsar-v0.7

# 3. Run full workflow (breaking changes = need full spec)
/speckit.specify
```

**User input**:

> "Pulsar v0.7.0: Silent by default with PULSAR_VERBOSE opt-in flag. Remove legacy PULSAR_PATH/PULSAR_FPATH arrays (breaking). Remove VS Code shim. Simplify to ~700-800 LOC. Keep: parallel ops, OMZ/Prezto, version pinning, self-update, three loading modes (source/path/fpath with prefix syntax)."

```bash
# 4. Clarify design decisions
/speckit.clarify
```

Agent will ask ~3-5 questions like:

- Q: Should PULSAR_VERBOSE show output for all plugins or per-plugin control?
- Q: How should migration warnings be shown to users upgrading from v0.6?
- Q: Should compilation remain optional or be removed entirely?

```bash
# 5. Plan architecture
/speckit.plan

# 6. Break into tasks
/speckit.tasks

# 7. Validate (optional but recommended for breaking changes)
/speckit.analyze

# 8. Implement with tests
/speckit.implement

# 9. Iterate on tasks as needed
# Agent implements task-by-task with TDD approach

# 10. Ship it! 🚀
git push origin 003-silent-pulsar-v0.7
# Open PR, review, merge
```

## Quick Reference

### File Locations

```text
pulsar/
├── specs/
│   └── {NNN}-{feature-name}/
│       ├── spec.md              ← /speckit.specify
│       ├── plan.md              ← /speckit.plan
│       ├── research.md          ← /speckit.plan
│       ├── data-model.md        ← /speckit.plan
│       ├── tasks.md             ← /speckit.tasks
│       ├── quickstart.md        ← /speckit.plan
│       ├── checklists/
│       │   └── requirements.md  ← /speckit.specify
│       └── contracts/           ← /speckit.plan
│           ├── {operation-1}.md
│           ├── {operation-2}.md
│           └── {operation-3}.md
├── .specify/
│   ├── scripts/bash/
│   │   ├── check-prerequisites.sh
│   │   ├── setup-plan.sh
│   │   └── ...
│   └── memory/
│       └── constitution.md      ← Project governance rules
└── .github/
    ├── prompts/
    │   ├── speckit.specify.prompt.md
    │   ├── speckit.clarify.prompt.md
    │   ├── speckit.plan.prompt.md
    │   ├── speckit.tasks.prompt.md
    │   ├── speckit.analyze.prompt.md
    │   └── speckit.implement.prompt.md
    └── copilot-instructions.md  ← Auto-updated context
```

### Commands Summary

| Command | Purpose | Inputs | Key Outputs |
|---------|---------|--------|-------------|
| `/speckit.specify` | Create spec | Feature description | spec.md |
| `/speckit.clarify` | Resolve ambiguities | spec.md | Updated spec.md |
| `/speckit.plan` | Design architecture | spec.md | plan.md, research.md, data-model.md, contracts/ |
| `/speckit.tasks` | Break into tasks | spec.md, plan.md | tasks.md |
| `/speckit.analyze` | Validate consistency | spec.md, plan.md, tasks.md | Analysis report |
| `/speckit.implement` | Write code | tasks.md | Code + tests + commits |

## SpecKit Philosophy

> **Specification-first development with AI assistance**

### Core Principles

1. **Spec before code** - Always define "what" before "how"
2. **Iterative refinement** - Use optional steps to reduce ambiguity
3. **Documentation as code** - Specs live alongside implementation
4. **Constitutional compliance** - All work follows project governance
5. **Testable requirements** - Every requirement has measurable acceptance criteria

### Benefits

- **Clarity**: Everyone knows what's being built
- **Quality**: Catch issues before coding
- **Maintainability**: Future developers understand design rationale
- **AI-friendly**: Clear specs enable better code generation
- **Async-friendly**: Team members can review specs without synchronous meetings

---

**Ready to build?** Start with `/speckit.specify` and work through the flow! 🚀
