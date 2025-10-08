# SpecKit Workflow Guide

## The Complete Process - Crystal Clear

### 1. Initialize Your Project

```bash
# You're already here after running: specify init --here
```

---

### 2. `/speckit.constitution` - Establish Project Principles

**What it does:** Creates governance rules and principles for your project

**Do you need to provide arguments?**

- ❌ **NO** - It will guide you interactively or infer from your repo
- ✅ **YES** - If you want to specify exact principles upfront

**Examples:**

```bash
# Let it guide you (recommended for first time)
/speckit.constitution

# Or provide specific guidance
/speckit.constitution 5 principles: security-first, performance, accessibility, testing, documentation
```

**What happens:**

- Loads template from `.specify/memory/constitution.md`
- Fills in placeholders (asks you for missing info)
- Creates versioned governance document

---

### 3. `/speckit.specify` - Create Feature Specification

**What it does:** Transforms your idea into a structured specification

**Do you need to provide arguments?**

- ✅ **YES - REQUIRED** - You must describe your feature

**Examples:**

```bash
# Describe what you want to build
/speckit.specify Create a podcast landing page with episode cards, playback controls, and related episodes section

/speckit.specify Build a user authentication system with email/password login and JWT tokens
```

**What happens:**

- Runs `.specify/scripts/bash/create-new-feature.sh` to create feature branch
- Creates `spec.md` from template
- Generates initial specification
- May ask clarifying questions if critical info is missing (max 3 questions)
- Creates quality checklist to validate spec completeness

---

### 4. `/speckit.clarify` *(OPTIONAL)* - De-risk Ambiguities

**When to use:** Before planning, if your spec has unclear areas

**Do you need to provide arguments?**

- ❌ **NO** - It will scan your spec and ask what needs clarification
- ✅ **YES** - If you want to focus on specific areas

**Examples:**

```bash
# Let it find ambiguities
/speckit.clarify

# Focus on specific concerns
/speckit.clarify Focus on security requirements and data privacy
```

**What happens:**

- Scans spec for ambiguous, partial, or missing requirements
- Asks up to 5 targeted questions (one at a time)
- Presents multiple choice options in tables
- Updates spec.md after each answer
- Reports coverage summary

**Interaction style:**

```
Q1: How should user sessions be managed?

| Option | Description |
|--------|-------------|
| A | JWT tokens (stateless) |
| B | Server-side sessions (stateful) |
| C | Hybrid approach |

Your choice: _
```

---

### 5. `/speckit.plan` - Create Implementation Plan

**What it does:** Generates technical architecture and design decisions

**Do you need to provide arguments?**

- ❌ **NO** - It will choose appropriate tech stack
- ✅ **YES** - If you have tech preferences or constraints

**Examples:**

```bash
# Let it choose the stack
/speckit.plan

# Specify your preferences
/speckit.plan Use Next.js 14, PostgreSQL, Tailwind CSS, avoid external APIs
```

**What happens:**

- Runs `.specify/scripts/bash/setup-plan.sh` to create plan structure
- Generates `plan.md` with tech stack and architecture
- Creates `research.md` for technical decisions
- Generates `data-model.md` for entities
- Creates API contracts in `/contracts/`
- Updates agent context files (Copilot/Claude/Cursor)
- Validates against constitution principles

---

### 6. `/speckit.checklist` *(OPTIONAL)* - Validate Quality

**When to use:** After planning, to validate requirements before tasks

**Do you need to provide arguments?**

- ❌ **NO** - It will create a general quality checklist
- ✅ **YES** - If you want a specific type of checklist

**Examples:**

```bash
# General quality checklist
/speckit.checklist

# Specific domain checklist
/speckit.checklist UX checklist focused on accessibility and responsive design

/speckit.checklist Security checklist for API endpoints and data protection

/speckit.checklist Performance requirements validation
```

**What happens:**

- Asks 3-5 clarifying questions about scope, focus, depth
- Generates checklist in `FEATURE_DIR/checklists/[domain].md`
- Creates "unit tests for requirements" (tests the spec quality, not implementation)
- Each item validates requirement completeness, clarity, consistency

**Important:** Checklists test if requirements are well-written, NOT if implementation works!

✅ Good: "Are hover state requirements consistently defined across all interactive elements?"
❌ Bad: "Verify hover states work correctly"

---

### 7. `/speckit.tasks` - Generate Action Items

**What it does:** Breaks down implementation into executable tasks

**Do you need to provide arguments?**

- ❌ **NO** - It will generate standard task breakdown
- ✅ **YES** - If you have execution preferences

**Examples:**

```bash
# Standard task generation
/speckit.tasks

# With preferences
/speckit.tasks TDD approach, include comprehensive tests

/speckit.tasks Skip tests for now, MVP implementation only
```

**What happens:**

- Runs `.specify/scripts/bash/check-prerequisites.sh` to verify plan exists
- Generates `tasks.md` organized by user story
- Numbers tasks sequentially (T001, T002...)
- Marks parallelizable tasks with [P]
- Creates dependency graph
- Groups by phases: Setup → Foundational → User Stories → Polish

**Task organization:**

- Phase 1: Setup (project initialization)
- Phase 2: Foundational (blocking prerequisites)
- Phase 3+: One phase per user story (P1, P2, P3...)
- Final: Polish & cross-cutting concerns

---

### 8. `/speckit.analyze` *(OPTIONAL)* - Consistency Check

**When to use:** After tasks, before implementation, for final validation

**Do you need to provide arguments?**

- ❌ **NO** - Comprehensive analysis across all artifacts
- ✅ **YES** - If you want to focus on specific concerns

**Examples:**

```bash
# Full analysis
/speckit.analyze

# Focused analysis
/speckit.analyze Focus on constitution alignment and coverage gaps

/speckit.analyze Check security requirement coverage
```

**What happens:**

- **READ-ONLY** - Does not modify any files
- Loads spec.md, plan.md, tasks.md
- Validates against constitution principles
- Checks for:
  - Duplications
  - Ambiguities
  - Coverage gaps (requirements without tasks)
  - Inconsistencies
  - Constitution violations (CRITICAL)
- Generates severity-ranked report
- Suggests remediation actions

**Report includes:**

- Finding table with severity levels
- Coverage summary
- Constitution alignment issues
- Metrics and next steps

---

### 9. `/speckit.implement` - Execute Implementation

**What it does:** Executes all tasks to build your feature

**Do you need to provide arguments?**

- ❌ **NO** - Executes all tasks as defined
- ✅ **YES** - If you want to control execution

**Examples:**

```bash
# Execute everything
/speckit.implement

# Controlled execution
/speckit.implement Start with Phase 1 setup only

/speckit.implement Execute only P1 user story tasks
```

**What happens:**

- Checks checklist completion status first
- **If checklists incomplete:** Asks if you want to proceed anyway
- **If checklists complete:** Proceeds automatically
- Loads tasks.md and executes phase by phase
- Respects dependencies and [P] parallel markers
- Marks completed tasks with [X] in tasks.md
- Reports progress after each task
- Validates completion at the end

---

## Quick Decision Tree

### "Should I provide arguments?"

```
Do you have specific preferences or requirements?
├─ YES → Provide arguments to guide the AI
└─ NO → Skip arguments, let AI use defaults or guide you

Is it /speckit.specify?
└─ Always provide your feature description (REQUIRED)

Do you want interactive guidance?
├─ /speckit.clarify → Asks questions interactively
├─ /speckit.checklist → Asks about scope/focus interactively
└─ /speckit.constitution → Fills in missing info interactively

Want focused analysis/checklists?
└─ Provide arguments to narrow the scope
```

---

## The Minimal Path (Fewest Decisions)

```bash
# 1. Create principles (guided)
/speckit.constitution

# 2. Describe your feature (REQUIRED)
/speckit.specify [your feature description]

# 3. Generate plan (auto-selects tech)
/speckit.plan

# 4. Generate tasks (standard breakdown)
/speckit.tasks

# 5. Implement everything
/speckit.implement
```

---

## The Thorough Path (Maximum Quality)

```bash
# 1. Create principles with specific focus
/speckit.constitution 5 principles: security, performance, testing, documentation, accessibility

# 2. Describe your feature with details
/speckit.specify [detailed feature description with user stories]

# 3. Clarify ambiguities
/speckit.clarify

# 4. Generate plan with tech preferences
/speckit.plan Use Next.js 14, PostgreSQL, Tailwind

# 5. Validate quality
/speckit.checklist UX and accessibility focused

# 6. Generate tasks with TDD
/speckit.tasks TDD approach with comprehensive tests

# 7. Validate consistency
/speckit.analyze

# 8. Implement with validation
/speckit.implement
```

---

## Command Summary Table

| Command | Required Args? | Interactive? | Purpose |
|---------|---------------|--------------|---------|
| `/speckit.constitution` | No | Yes | Establish project principles |
| `/speckit.specify` | **YES** | Minimal | Create feature spec |
| `/speckit.clarify` | No | **Highly** | De-risk ambiguities (5 Q&A) |
| `/speckit.plan` | No | Minimal | Generate technical plan |
| `/speckit.checklist` | No | Yes | Validate quality (3-5 Q&A) |
| `/speckit.tasks` | No | No | Generate action items |
| `/speckit.analyze` | No | No | Consistency check (read-only) |
| `/speckit.implement` | No | Yes | Execute implementation |

---

## Pro Tips

✨ **First time?** Use the Minimal Path without arguments - let the AI guide you

🎯 **Know what you want?** Provide arguments to skip questions and guide decisions

🔍 **Quality matters?** Use the Thorough Path with optional commands

⚡ **Moving fast?** Skip `/speckit.clarify`, `/speckit.checklist`, and `/speckit.analyze`

📋 **Checklists incomplete?** `/speckit.implement` will ask if you want to proceed anyway

🚫 **Never modify files manually** during implementation - let the commands handle it

---

## Where Files Are Created

```
.specify/
├── memory/
│   └── constitution.md          # From /speckit.constitution
└── templates/
    ├── spec-template.md
    ├── plan-template.md
    └── tasks-template.md

feature-[name]/                   # Created by /speckit.specify
├── spec.md                       # Feature specification
├── plan.md                       # Technical plan (from /speckit.plan)
├── tasks.md                      # Action items (from /speckit.tasks)
├── research.md                   # Technical decisions (from /speckit.plan)
├── data-model.md                 # Entity definitions (from /speckit.plan)
├── quickstart.md                 # Integration scenarios (from /speckit.plan)
├── contracts/                    # API contracts (from /speckit.plan)
│   ├── endpoints.yaml
│   └── schemas.json
└── checklists/                   # Quality checklists (from /speckit.checklist)
    ├── ux.md
    ├── security.md
    └── performance.md
```

---

## Common Questions

**Q: Can I run commands in a different order?**
A: Some commands have dependencies - follow the workflow order for best results.

**Q: What if I skip the optional commands?**
A: You can still implement successfully, but you'll have less validation and might encounter issues later.

**Q: Can I run `/speckit.checklist` multiple times?**
A: Yes! Each run creates a new checklist file with a descriptive name (ux.md, security.md, etc.)

**Q: What if `/speckit.analyze` finds CRITICAL issues?**
A: Fix them before running `/speckit.implement` - they usually indicate missing requirements or constitution violations.

**Q: Do I need to provide arguments every time?**
A: No! Only `/speckit.specify` requires arguments. All others work fine without them.

---

**Ready to start?** Run `/speckit.constitution` to begin! 🚀
