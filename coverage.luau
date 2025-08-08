--!strict
-- coverage.luau
-- Simple code coverage reporting for Roblox Luau tests

local Coverage = {}

-- Coverage data structure
local coverageData = {
    files = {},
    startTime = 0,
    endTime = 0,
    totalLines = 0,
    coveredLines = 0
}

-- Configuration
local CONFIG = {
    enabled = true,
    verbose = false
}

-- Simple coverage tracking
local function trackLine(file: string, line: number)
    if not CONFIG.enabled then return end
    
    coverageData.files[file] = coverageData.files[file] or {
        path = file,
        lines = {},
        totalLines = 0,
        coveredLines = 0
    }
    
    local fileData = coverageData.files[file]
    
    -- First time seeing this line
    if not fileData.lines[line] then
        fileData.totalLines = fileData.totalLines + 1
        coverageData.totalLines = coverageData.totalLines + 1
        fileData.lines[line] = 0
    end
    
    -- Increment hit count
    if fileData.lines[line] == 0 then
        fileData.coveredLines = fileData.coveredLines + 1
        coverageData.coveredLines = coverageData.coveredLines + 1
    end
    
    fileData.lines[line] = (fileData.lines[line] or 0) + 1
end

-- Initialize coverage tracking
function Coverage.init()
    if not CONFIG.enabled then return end
    
    -- Reset coverage data
    coverageData = {
        files = {},
        startTime = os.clock(),
        endTime = 0,
        totalLines = 0,
        coveredLines = 0
    }
    
    -- Set up debug hook to track line execution
    debug.sethook(function(event: string, line: number)
        if event == "line" then
            local info = debug.info(2, "s")
            if info and info.source and info.source:find("^@") then
                local file = info.source:sub(2) -- Remove @ prefix
                trackLine(file, line)
            end
        end
    end, "l")
    
    if CONFIG.verbose then
        print("🔍 Coverage tracking started")
    end
end

-- Stop coverage tracking and print report
function Coverage.finish()
    if not CONFIG.enabled then return {} end
    
    debug.sethook()
    coverageData.endTime = os.clock()
    
    -- Calculate coverage percentage
    local coveragePercent = coverageData.totalLines > 0 
        and math.floor((coverageData.coveredLines / coverageData.totalLines) * 100) 
        or 0
    
    -- Print summary
    print("\n📊 Coverage Report")
    print("==================")
    print(string.format("📈 Coverage: %d%% (%d/%d lines)", 
        coveragePercent, 
        coverageData.coveredLines, 
        coverageData.totalLines))
    print(string.format("⏱️  Duration: %.2f seconds", 
        coverageData.endTime - coverageData.startTime))
    
    -- Print per-file coverage
    print("\n📋 File Coverage")
    print("----------------")
    
    local files = {}
    for file in pairs(coverageData.files) do
        table.insert(files, file)
    end
    table.sort(files)
    
    for _, file in ipairs(files) do
        local fileData = coverageData.files[file]
        local fileCoverage = fileData.totalLines > 0 
            and math.floor((fileData.coveredLines / fileData.totalLines) * 100) 
            or 0
            
        print(string.format("%s: %d%% (%d/%d lines)", 
            file, 
            fileCoverage,
            fileData.coveredLines,
            fileData.totalLines))
    end
    
    return coverageData
end

-- Enable or disable coverage
function Coverage.setEnabled(enabled: boolean)
    CONFIG.enabled = enabled
end

-- Set verbosity
function Coverage.setVerbose(verbose: boolean)
    CONFIG.verbose = verbose
end

return Coverage
