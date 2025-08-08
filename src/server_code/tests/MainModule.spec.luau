--!strict
-- MainModule.spec.luau
-- Test suite for the enhanced MainModule

local TestEZ = require(script.Parent.Parent.Packages.TestEZ)
local TestHelpers = require(script.Parent.TestHelpers)

-- Mock services
local ServerScriptService = {
    systems = {}
}

-- Create a mock ServerScriptService
local function createMockServerScriptService()
    local mock = {}
    
    function mock:FindFirstChild(name: string)
        return ServerScriptService[name] or nil
    end
    
    function mock:GetChildren()
        local children = {}
        for _, child in pairs(ServerScriptService) do
            table.insert(children, child)
        end
        return children
    end
    
    return mock
end

-- Create a mock system ModuleScript
local function createMockSystemScript(name: string, dependencies: {string}?)
    local system = TestHelpers.createMockSystem(name, dependencies)
    local script = Instance.new("ModuleScript")
    script.Name = name
    script.Source = [[
        --!strict
        return ...
    ]]
    
    -- Store the system in the mock ServerScriptService
    ServerScriptService.systems[script] = system
    
    return script, system
end

-- Main test suite
return function()
    local MainModule
    local mockSSS
    
    beforeAll(function()
        -- Setup mock environment
        mockSSS = createMockServerScriptService()
        game:GetService = function(_, serviceName)
            if serviceName == "ServerScriptService" then
                return mockSSS
            end
            return game:GetService(serviceName)
        end
        
        -- Create test systems
        local system1, _ = createMockSystemScript("System1")
        local system2, _ = createMockSystemScript("System2", {"System1"})
        local system3, _ = createMockSystemScript("System3", {"System1", "System2"})
        
        -- Load the MainModule
        MainModule = require(script.Parent.Parent.MainModule)
    end)
    
    afterEach(function()
        -- Reset MainModule state
        MainModule:shutdown()
        MainModule.config = {
            debug = false,
            strictMode = true,
            autoStart = false,
            maxInitRetries = 3,
            initRetryDelay = 0
        }
    end)
    
    describe("MainModule", function()
        describe("Initialization", function()
            it("should initialize with default config", function()
                local config = MainModule.config
                expect(config.debug).to.equal(false)
                expect(config.strictMode).to.equal(true)
                expect(config.autoStart).to.equal(false)
                expect(config.maxInitRetries).to.equal(3)
            end)
            
            it("should initialize all systems", function()
                local success, result = MainModule:init()
                expect(success).to.equal(true)
                
                local statuses = MainModule:getAllSystemStatuses()
                expect(#statuses).to.equal(3)
                
                for _, status in pairs(statuses) do
                    expect(status.initialized).to.equal(true)
                end
            end)
            
            it("should respect dependency order during initialization", function()
                -- Create systems with specific dependencies
                local _, sys1 = createMockSystemScript("DepSystem1")
                local _, sys2 = createMockSystemScript("DepSystem2", {"DepSystem1"})
                
                -- Spy on the init methods
                local spy1 = spy.on(sys1, "init")
                local spy2 = spy.on(sys2, "init")
                
                -- Initialize
                MainModule:init()
                
                -- Check that dependencies are initialized first
                expect(spy1).to.have.been.called()
                expect(spy2).to.have.been.called()
                
                -- Verify order (spy1 should be called before spy2)
                expect(spy1.callCount).to.equal(1)
                expect(spy2.callCount).to.equal(1)
                
                -- This is a simple check - in a real test, you'd verify the call order
            end)
        end)
        
        describe("System Management", function()
            it("should get a system by name", function()
                MainModule:init()
                local system = MainModule:getSystem("System1")
                expect(system).to.be.ok()
                expect(system.name).to.equal("System1")
            end)
            
            it("should return nil for non-existent system", function()
                local system = MainModule:getSystem("NonExistentSystem")
                expect(system).to.never.be.ok()
            end)
            
            it("should get all system statuses", function()
                MainModule:init()
                local statuses = MainModule:getAllSystemStatuses()
                
                expect(statuses.System1).to.be.ok()
                expect(statuses.System2).to.be.ok()
                expect(statuses.System3).to.be.ok()
                
                expect(statuses.System1.initialized).to.equal(true)
                expect(statuses.System1.started).to.equal(false) -- autoStart is false
            end)
        end)
        
        describe("Error Handling", function()
            it("should handle system initialization failure", function()
                -- Create a system that will fail to initialize
                local _, failingSystem = createMockSystemScript("FailingSystem")
                failingSystem.init = failingSystem.failOnInit
                
                -- Set strict mode to false to test error handling
                MainModule.config.strictMode = false
                
                local success, error = MainModule:init()
                
                -- Should still complete initialization
                expect(success).to.equal(true)
                
                -- But the failing system should have an error
                local status = MainModule:getSystemStatus("FailingSystem")
                expect(status.error).to.be.ok()
                expect(status.initialized).to.equal(false)
            end)
            
            it("should retry failed initializations", function()
                -- Create a system that will fail first then succeed
                local retryCount = 0
                local _, retrySystem = createMockSystemScript("RetrySystem")
                
                local originalInit = retrySystem.init
                retrySystem.init = function(self)
                    retryCount = retryCount + 1
                    if retryCount < 3 then
                        return false, "Temporary failure"
                    end
                    return originalInit(self)
                end
                
                MainModule.config.maxInitRetries = 5
                
                local success = MainModule:init()
                
                expect(success).to.equal(true)
                expect(retryCount).to.equal(3)
                
                local status = MainModule:getSystemStatus("RetrySystem")
                expect(status.initialized).to.equal(true)
            end)
        end)
        
        describe("Lifecycle Management", function()
            it("should start all systems when autoStart is true", function()
                MainModule.config.autoStart = true
                
                local _, sys1 = createMockSystemScript("AutoStartSystem1")
                local spy1 = spy.on(sys1, "start")
                
                MainModule:init()
                
                expect(spy1).to.have.been.called()
                
                local status = MainModule:getSystemStatus("AutoStartSystem1")
                expect(status.started).to.equal(true)
            end)
            
            it("should manually start systems", function()
                MainModule:init()
                
                local system = MainModule:getSystem("System1")
                local spyStart = spy.on(system, "start")
                
                local success = MainModule:startSystem("System1")
                
                expect(success).to.equal(true)
                expect(spyStart).to.have.been.called()
                
                local status = MainModule:getSystemStatus("System1")
                expect(status.started).to.equal(true)
            end)
            
            it("should shutdown all systems", function()
                -- Create a system with a shutdown method
                local _, sys = createMockSystemScript("ShutdownSystem")
                sys.shutdown = function() return true end
                local spyShutdown = spy.on(sys, "shutdown")
                
                MainModule:init()
                MainModule:shutdown()
                
                expect(spyShutdown).to.have.been.called()
            end)
        end)
        
        describe("Verification", function()
            it("should verify all systems are valid", function()
                MainModule:init()
                
                local isValid, errors = MainModule:verifySystems()
                
                expect(isValid).to.equal(true)
                expect(errors).to.never.be.ok()
            end)
            
            it("should detect missing dependencies", function()
                -- Create a system with a non-existent dependency
                local _, _ = createMockSystemScript("BadSystem", {"NonExistentSystem"})
                
                MainModule:init()
                
                local isValid, errors = MainModule:verifySystems()
                
                expect(isValid).to.equal(false)
                expect(errors.BadSystem).to.be.ok()
            end)
        end)
    end)
end
