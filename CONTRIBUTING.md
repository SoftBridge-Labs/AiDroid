# Contributing to Aidroid

Thank you for considering contributing to **Aidroid**! 🎉

We welcome contributions of all kinds – bug fixes, new features, documentation improvements, tests, and more. Please follow the guidelines below to make the process smooth for everyone.

---

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Submitting Pull Requests](#submitting-pull-requests)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Style Guide](#style-guide)
- [License](#license)

---

## Code of Conduct
We adhere to the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you agree to uphold this code.

---

## How to Contribute
### Reporting Bugs
1. Search the existing issues to see if the bug has already been reported.
2. If not, open a new issue with:
   - A clear title.
   - Steps to reproduce.
   - Expected vs. actual behavior.
   - Screenshots or logs if relevant.

### Suggesting Enhancements
1. Check the issue tracker for similar suggestions.
2. Open a new issue describing the enhancement, its motivation, and any design ideas.

### Submitting Pull Requests
1. **Fork** the repository and **clone** your fork.
2. Create a new branch for your work:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes, ensuring the code follows the style guide.
4. Write or update tests as needed.
5. Run the test suite:
   ```bash
   flutter test
   ```
6. Commit your changes with a clear, concise message.
7. Push the branch to your fork and open a Pull Request against the `main` branch.
8. Fill out the PR template, linking any related issues.

---

## Development Setup
1. **Clone the repository** (if you haven't already):
   ```bash
   git clone https://github.com/yourusername/aidroid.git
   cd aidroid
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app** to verify everything works:
   ```bash
   flutter run
   ```

---

## Testing
- Unit and widget tests live in the `test/` directory.
- Run all tests with:
  ```bash
  flutter test
  ```
- Ensure new code includes appropriate tests and that the overall test suite passes before submitting a PR.

---

## Style Guide
- Follow the official Dart style guide: <https://dart.dev/guides/language/effective-dart>
- Use `flutter format .` to auto‑format code.
- Keep UI code declarative and avoid business logic in widgets.
- Document public classes, methods, and complex logic with DartDoc comments.

---

## License
By contributing, you agree that your contributions will be licensed under the same MIT License as the project.

---

**Happy coding!**
