--!strict
-- TestCharacterSystem2.luau
-- A minimal test file to verify Rojo build inclusion with strict Luau types

print("=== TestCharacterSystem2 loaded successfully ===")

-- Define return type
type TestResult = {
    success: boolean,
    message: string
}

-- Return a simple success result with type annotation
local result: TestResult = {
    success = true,
    message = "TestCharacterSystem2 loaded and executed successfully"
}

print("✅", result.message)
return result
