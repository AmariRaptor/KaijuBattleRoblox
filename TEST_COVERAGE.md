# Test Coverage for Kaiju Battle

This document explains how to use the code coverage features in the Kaiju Battle project.

## Overview

The test coverage system tracks which lines of code are executed during test runs, helping you identify untested parts of your codebase. The coverage system is integrated with the test runner and provides both summary and detailed reports.

## Enabling Coverage

Coverage is enabled by default when running tests. The coverage module is automatically loaded if available.

## Running Tests with Coverage

```bash
# Run all tests with coverage
luau test_runner.luau

# Run specific test file with coverage
luau test_runner.luau Tests/coverage_demo.spec.luau
```

## Coverage Reports

After running tests, you'll see a coverage report in the console output:

```
📊 Coverage Report
==================
📈 Total Coverage: 75% (30/40 lines)

📋 File Coverage
----------------
src/Utils.luau: 80% (16/20 lines)
src/Game.luau: 70% (14/20 lines)
```

## Interpreting the Report

- **Total Coverage**: The overall percentage of lines covered across all files
- **File Coverage**: A breakdown of coverage for each source file
  - Each entry shows the file path, coverage percentage, and line counts (covered/total)

## Best Practices

1. **Aim for High Coverage**: Strive for at least 80% line coverage in your codebase.
2. **Focus on Critical Paths**: Ensure all critical business logic is thoroughly tested.
3. **Review Uncovered Code**: Pay special attention to code that isn't covered by tests.
4. **Use Coverage Data**: Use the coverage report to guide your testing efforts.

## Troubleshooting

### No Coverage Data

If you don't see coverage data:

1. Ensure the `coverage.luau` file is in your project root
2. Check that tests are actually exercising the code you expect
3. Verify that the coverage module is being loaded (look for "Code coverage enabled" in the test output)

### Inaccurate Coverage

If coverage seems inaccurate:

1. Make sure all code paths are being exercised by your tests
2. Check for conditional logic that might be skipping code blocks
3. Verify that your test data covers all edge cases

## Advanced Configuration

You can customize coverage behavior by modifying the `coverage.luau` file:

```lua
-- Enable verbose output for debugging
coverage.setVerbose(true)

-- Disable coverage if needed
coverage.setEnabled(false)
```

## Limitations

- The coverage system tracks line execution but doesn't measure branch coverage
- Coverage data is only as good as your test cases - make sure to test all logical paths
- Some edge cases in the Luau VM might not be perfectly tracked

## Future Improvements

- Add HTML report generation
- Track branch coverage
- Integrate with CI/CD pipelines
- Add historical coverage tracking
