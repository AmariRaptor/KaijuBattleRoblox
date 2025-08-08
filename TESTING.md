# Testing Guide for Kaiju Battle

This guide covers how to write, run, and maintain tests for the Kaiju Battle project.

## Table of Contents
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Test Structure](#test-structure)
- [Best Practices](#best-practices)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

## Running Tests

### Local Development

1. **Run all tests**:
   ```bash
   luau test_runner.luau
   ```

2. **Run with verbose output**:
   ```bash
   luau test_runner.luau --verbose
   ```

3. **Stop on first failure**:
   ```bash
   luau test_runner.luau --stop-on-failure
   ```

### Pre-commit Hook

A pre-commit hook is set up to run tests automatically before each commit. If any tests fail, the commit will be aborted.

To skip the pre-commit hook (not recommended):
```bash
git commit --no-verify -m "Your commit message"
```

## Writing Tests

### Test File Naming
- Place test files in the `Tests` directory
- Use `.spec.luau` suffix (e.g., `MySystem.spec.luau`)
- Group related tests in subdirectories (e.g., `Tests/Systems/Combat.spec.luau`)

### Basic Test Structure

```lua
--!strict
-- Tests/MySystem.spec.luau

return function()
    local results = {}
    
    -- Test setup
    local function setup()
        -- Initialize test data
        return {
            mockPlayer = { Name = "TestPlayer" },
            mockCharacter = { Health = 100 }
        }
    end
    
    -- Test case 1
    do
        local testData = setup()
        local success = MySystem.doSomething(testData.mockPlayer, testData.mockCharacter)
        if success then
            table.insert(results, "✅ doSomething returns true with valid input")
        else
            table.insert(results, "❌ doSomething should return true with valid input")
        end
    end
    
    -- Test case 2 with assertions
    do
        local testData = setup()
        local result = MySystem.calculateDamage(100, 0.5)
        if result == 50 then
            table.insert(results, "✅ calculateDamage applies damage multiplier correctly")
        else
            table.insert(results, string.format(
                "❌ Expected calculateDamage(100, 0.5) to return 50, got %s",
                tostring(result)
            ))
        end
    end
    
    return results
end
```

## Test Structure

### Unit Tests
- Test individual functions in isolation
- Mock all dependencies
- Focus on one specific behavior per test

### Integration Tests
- Test interactions between components
- Use minimal mocks when necessary
- Focus on component boundaries

### Test Helpers

#### Mocking
```lua
local function mockPlayer(name, userId)
    return {
        Name = name,
        UserId = userId or 12345,
        ClassName = "Player"
    }
end
```

#### Assertions
```lua
local function assertEquals(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s\nExpected: %s\nActual: %s", 
            message or "Assertion failed", 
            tostring(expected), 
            tostring(actual)
        ))
    end
end
```

## Best Practices

1. **Keep tests simple** - Each test should verify one specific behavior
2. **Use descriptive test names** - Clearly state what's being tested and expected
3. **Test edge cases** - Include tests for boundary conditions and error cases
4. **Keep tests independent** - Tests should not depend on each other
5. **Mock external dependencies** - Don't rely on actual game services in unit tests
6. **Run tests frequently** - Run tests after every significant change

## CI/CD Integration

Tests are automatically run on:
- Push to `main` or `develop` branches
- Any pull request targeting these branches
- Manually triggered via GitHub Actions

### Viewing Test Results
1. Go to the "Actions" tab in GitHub
2. Select the workflow run
3. View the "Run tests" step output
4. Download "test-results" artifact for detailed results

## Troubleshooting

### Common Issues

#### Test not found
- Ensure test file has `.spec.luau` extension
- Check file is in the `Tests` directory
- Verify file permissions

#### Test failures
1. Read the error message carefully
2. Check the test file and line number mentioned
3. Verify expected vs actual values
4. Ensure all dependencies are properly mocked

#### Pre-commit hook not running
```bash
# Make the hook executable
chmod +x .git/hooks/pre-commit
```

#### Luau version issues
```bash
# Check installed version
luau -v

# Install/update Luau
# Follow instructions at: https://luau-lang.org/setup
```

## Getting Help

If you encounter issues:
1. Check the test output for error messages
2. Review recent changes to the test or related code
3. Ask for help in the #development channel
4. Open an issue with details about the problem
