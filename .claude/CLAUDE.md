# cc-knowledge - Claude Code Configuration

## Project Information
- **Name**: cc-knowledge
- **Type**: generic
- **Knowledge Management**: Enabled
- **Auto-promotion**: Enabled

## Project-Specific Guidelines

### Development Standards
- Follow existing code patterns in the codebase
- Use TDD for new features
- Update tests when modifying existing code

### Knowledge Management
- Project-specific patterns are stored in `.claude/knowledge/patterns/`
- Lessons learned are stored in `.claude/knowledge/lessons/`
- Patterns with high reusability are auto-promoted to global knowledge

### Custom Commands
Commands are customized for generic projects and available in `.claude/commands/`

## Auto-Knowledge Settings
- **Promotion Threshold**: 90% success rate + 3+ references
- **Scope Detection**: Automatic based on content analysis
- **Pattern Recognition**: Enabled

## Local Overrides
Add project-specific overrides below:

<!-- Add custom guidelines here -->

