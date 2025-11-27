# Code Quality & Standards Check

Please perform a comprehensive code quality review of all changes made in this session:

## 1. Run Quality Checks
- Run `mix precommit` and fix any issues found
- Run `mix test` and ensure all tests pass
- Run `mix compile --warnings-as-errors` to catch any warnings
- Run `mix format --check-formatted` to verify formatting

## 2. Review Against AGENTS.md Guidelines
Check all code against the project guidelines in AGENTS.md:
- Phoenix v1.8 guidelines (LiveView templates, components, etc.)
- Elixir guidelines (immutability, pattern matching, no nested modules)
- Phoenix HTML/HEEx guidelines (proper form usage, interpolation, class syntax)
- LiveView guidelines (streams, navigation, hooks)
- JS/CSS guidelines (Tailwind usage, no inline scripts)
- Mix guidelines

## 3. Code Quality Review
Verify the code follows modern software engineering best practices:
- **DRY (Don't Repeat Yourself)**: Check for duplicated logic that should be extracted
- **SOLID Principles**:
  - Single Responsibility: Each module/function has one clear purpose
  - Open/Closed: Code is extensible without modification
  - Liskov Substitution: Subtypes are substitutable
  - Interface Segregation: Interfaces are focused and minimal
  - Dependency Inversion: Depend on abstractions, not concretions
- **Clean Code**:
  - Clear, descriptive names for functions, modules, and variables
  - Functions are small and focused
  - Proper documentation for public APIs
  - No commented-out code or dead code
  - Consistent error handling patterns

## 4. Maintainability Check
- Code is easy to understand and reason about
- Proper separation of concerns
- Appropriate use of pattern matching and guards
- Type specs are present for public functions
- Test coverage is adequate for new functionality

## 5. Security & Performance
- No security vulnerabilities (SQL injection, XSS, etc.)
- No obvious performance issues
- Database queries are optimized
- No N+1 query problems

## Output Format
For each issue found:
1. Specify the file and line number
2. Describe the issue
3. Provide the corrected code
4. Explain why the change is necessary

If no issues are found, confirm that all checks pass and the code is ready to commit.
