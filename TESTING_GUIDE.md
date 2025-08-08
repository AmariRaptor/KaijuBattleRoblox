# Testing Guide for Kaiju Battle Arena

This guide explains how to test the systems in the Kaiju Battle Arena project using Roblox Studio.

## Prerequisites

- Roblox Studio installed
- The project opened in Roblox Studio
- All system modules properly placed in `ServerScriptService/systems/`

## Testing Systems in Roblox Studio

1. **Open the Project in Roblox Studio**
   - Open the Kaiju Battle Arena project in Roblox Studio
   - Ensure all system modules are properly placed in the `systems` folder under `ServerScriptService`

2. **Run the Test Script**
   - In Roblox Studio, open the Output window (View → Output)
   - Run the game in Play mode (F5 or the Play button)
   - The test script will automatically run and output the results to the Output window

## Expected Output

When the test script runs successfully, you should see output similar to:

```
🚀 Starting System Tests in Roblox Studio...

🔍 Testing system: ClassSystem
✅ ClassSystem initialized successfully

🔍 Testing system: CharacterSystem
✅ CharacterSystem initialized successfully

🔍 Testing system: BuildingSystem
✅ BuildingSystem initialized successfully

🔍 Testing system: KaijuSystem
✅ KaijuSystem initialized successfully

🔍 Testing system: ScoringSystem
✅ ScoringSystem initialized successfully

📊 Test Results:
✅ 5/5 tests passed
📈 100% success rate
```

## Troubleshooting

If you encounter any issues:

1. **Script Not Running**
   - Ensure the script is placed in `ServerScriptService`
   - Check for any syntax errors in the Output window

2. **Module Not Found**
   - Verify all system modules are in the `systems` folder
   - Check for correct file names and extensions (should be `.server.luau`)

3. **Initialization Failures**
   - Check the Output window for specific error messages
   - Verify that each system has a proper `init()` method
   - Ensure all required services and dependencies are available

## Manual Testing

You can also test individual systems by requiring them in the command bar:

```lua
-- Example: Test BuildingSystem
local BuildingSystem = require(game:GetService("ServerScriptService").systems.BuildingSystem)
print("BuildingSystem loaded successfully:", BuildingSystem ~= nil)
```

## Next Steps

- Add more detailed test cases for each system
- Implement automated testing with TestService
- Add integration tests for system interactions
