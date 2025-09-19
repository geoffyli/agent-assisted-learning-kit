# Centralized Agent System

Single source of truth for AI agent commands and scripts in this knowledge vault.

## Directory Structure

```
.agent/
├── README.md          # This documentation
├── commands/          # Markdown files with custom commands for agent systems
└── scripts/           # Shell scripts for efficient context and feedback
```

## Purpose

- **commands/**: Markdown files containing custom commands for various agent systems (Claude Code, Gemini CLI, etc.)
- **scripts/**: Shell scripts that execute logic to provide better context to agents, reducing token cost by handling routine operations

## Usage

1. **Commands**: Create `.md` files in `commands/` with agent instructions
2. **Scripts**: Write shell scripts in `scripts/` for automated context gathering
3. **Reference**: Agent applications reference these centralized resources instead of maintaining separate copies