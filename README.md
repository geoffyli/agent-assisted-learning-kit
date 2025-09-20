# Agent-Assisted Learning Kit

A comprehensive system for AI agent-assisted learning integrated with knowledge management vault.

## Overview

This project provides a structured framework for learning with AI agents, designed to work seamlessly with knowledge management systems like Obsidian. Instead of fragmented learning across multiple tools, this system creates a cohesive learning experience through specialized agent commands and automation scripts.

## Features

- **Three-Phase Learning Workflow**: SCOPE → PLAN → STUDY
- **Vault Integration**: Seamlessly creates and organizes notes following vault standards
- **Interactive Learning**: AI-guided step-by-step learning
- **Progress Tracking**: Session management and learning progress monitoring
- **Knowledge Connection**: Automatically links new learning to existing knowledge

## Project Structure

```
├── src/                   # Source code
│   ├── commands/          # Agent command files (.md)
│   ├── scripts/           # Automation scripts
│   └── templates/         # Learning session templates
├── docs/                  # Documentation
├── tests/                 # Testing framework
└── examples/              # Usage examples
```

## Development vs Production

- **Development**: This repository for designing, testing, and refining the system
- **Production**: Your vault's `.agent/` directory where the system runs

## Learning Workflow

### 1. SCOPE Phase
Define what to learn, gather resources, set goals

### 2. PLAN Phase  
Create knowledge framework, learning path, and MOC structure

### 3. STUDY Phase
Interactive learning execution with note creation and practice

## Contributing

This is a personal learning system, but the methodology can be adapted for other knowledge management workflows.