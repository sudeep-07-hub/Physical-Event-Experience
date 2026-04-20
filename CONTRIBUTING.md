# Contributing to AVCP

Thank you for your interest in contributing to the Autonomous Venue Control Plane!

## 🚀 Getting Started

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/Physical-Event-Experience.git`
3. **Create a branch**: `git checkout -b feature/your-feature-name`
4. **Make your changes** and commit with clear messages
5. **Push** to your fork and submit a **Pull Request**

## 🛠️ Development Setup

### Python Backend
```bash
pip install -e ".[dev]"
pytest tests/ -v --cov=avcp
```

### Flutter Frontend
```bash
cd avcp_flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test --coverage
```

## 📋 Guidelines

- **Zero PII**: Never add fields that could identify individuals (device IDs, user IDs, IP addresses, etc.)
- **Type Safety**: All Python code must pass `mypy --strict` checks
- **Test Coverage**: New features must include unit tests
- **Commit Messages**: Use conventional commits (`feat:`, `fix:`, `docs:`, `test:`, `ci:`)

## 🔒 Privacy First

This project has a strict **Zero-PII** policy. Before submitting, verify:
- No personal identifiers in data schemas
- All sector hashes use time-bucketed rotation
- Edge-node IDs are session-scoped (never persisted)

## 🐛 Reporting Issues

Use GitHub Issues with one of these labels:
- `bug` — Something isn't working
- `enhancement` — New feature request
- `privacy` — Privacy concern or PII leak
- `performance` — Latency or throughput issue
