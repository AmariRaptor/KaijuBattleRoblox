local MainModule = require(script.Parent.MainModule)
MainModule:init()

-- Test getting a system
local classSystem = MainModule:getSystem("ClassSystem")
print("ClassSystem found:", classSystem ~= nil)

-- Test isInitialized
print("MainModule initialized:", MainModule:isInitialized())

-- Test getInitializedSystems
local systems = MainModule:getInitializedSystems()
print("\nInitialized Systems:")
for name, _ in pairs(systems) do
    print("- " .. name)
end
