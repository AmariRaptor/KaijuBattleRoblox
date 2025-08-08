<#
.SYNOPSIS
    Sets up the development environment for Kaiju Battle project.
.DESCRIPTION
    This script helps set up the development environment by installing required tools,
    setting up Git hooks, and configuring the project.
#>

# Set error action preference
$ErrorActionPreference = "Stop"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Colors for output
$colors = @{
    "Reset" = "\e[0m"
    "Red" = "\e[31m"
    "Green" = "\e[32m"
    "Yellow" = "\e[33m"
    "Blue" = "\e[34m"
    "Magenta" = "\e[35m"
    "Cyan" = "\e[36m"
}

function Write-Color {
    param(
        [string]$Message,
        [string]$Color = "Reset"
    )
    
    $colorCode = $colors[$Color]
    if (-not $colorCode) { $colorCode = $colors["Reset"] }
    
    Write-Host "$colorCode$Message$($colors["Reset"])"
}

function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

function Install-Luau {
    Write-Color "\n🔧 Installing Luau..." "Cyan"
    
    if (Test-CommandExists "luau") {
        Write-Color "✓ Luau is already installed" "Green"
        return
    }
    
    # Check for Chocolatey
    if (-not (Test-CommandExists "choco")) {
        Write-Color "! Chocolatey is required to install Luau" "Yellow"
        if ($isAdmin) {
            $installChoco = Read-Host "Do you want to install Chocolatey now? (y/n)"
            if ($installChoco -eq 'y') {
                Write-Color "Installing Chocolatey..." "Yellow"
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                Write-Color "✓ Chocolatey installed successfully" "Green"
            } else {
                Write-Color "Skipping Chocolatey installation" "Yellow"
                return
            }
        } else {
            Write-Color "! Please run this script as administrator to install Chocolatey" "Red"
            return
        }
    }
    
    # Install Luau via Chocolatey
    Write-Color "Installing Luau via Chocolatey..." "Yellow"
    choco install luau -y
    
    if ($LASTEXITCODE -eq 0) {
        Write-Color "✓ Luau installed successfully" "Green"
    } else {
        Write-Color "! Failed to install Luau" "Red"
    }
}

function Install-VSCodeExtensions {
    param(
        [string[]]$extensions = @(
            "johnnymorganz.luau-lsp",
            "Kampfkarren.selene-vscode",
            "eamodio.gitlens",
            "ms-vscode.powershell"
        )
    )
    
    Write-Color "\n🔧 Installing VS Code extensions..." "Cyan"
    
    if (-not (Test-CommandExists "code")) {
        Write-Color "! VS Code CLI not found. Please add 'code' to your PATH" "Yellow"
        return
    }
    
    foreach ($extension in $extensions) {
        Write-Color "  Installing $extension..." "Yellow"
        code --install-extension $extension --force
    }
    
    Write-Color "✓ VS Code extensions installed" "Green"
}

function Initialize-GitHooks {
    Write-Color "\n🔧 Setting up Git hooks..." "Cyan"
    
    $hooksDir = ".git/hooks"
    $preCommitHook = "$hooksDir/pre-commit"
    
    # Create hooks directory if it doesn't exist
    if (-not (Test-Path $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    }
    
    # Make pre-commit hook executable
    if (Test-Path $preCommitHook) {
        Write-Color "  Updating pre-commit hook..." "Yellow"
    } else {
        Write-Color "  Creating pre-commit hook..." "Yellow"
    }
    
    # Create the pre-commit hook
    @"
#!/bin/sh
# Pre-commit hook to run tests before allowing a commit

echo ""
echo "🔍 Running tests before commit..."
echo ""

# Run the test runner
luau test_runner.luau --stop-on-failure
TEST_RESULT=`$?`

echo ""

if [ `$TEST_RESULT -ne 0 ]; then
    echo "❌ Tests failed. Please fix the issues before committing."
    echo "   You can run tests manually with: luau test_runner.luau"
    echo "   Use 'git commit --no-verify' to skip this check (not recommended)"
    exit 1
fi

echo "✅ All tests passed! Proceeding with commit..."
echo ""
exit 0
"@ | Out-File -FilePath $preCommitHook -Encoding ASCII -Force
    
    # Make the hook executable
    try {
        icacls $preCommitHook /grant "$env:USERNAME:(RX)" | Out-Null
        Write-Color "✓ Git hooks set up successfully" "Green"
    } catch {
        Write-Color "! Failed to set permissions on pre-commit hook" "Red"
        Write-Color "  Please make sure the file is executable: chmod +x $preCommitHook" "Yellow"
    }
}

function Show-SetupComplete {
    Write-Color "\n🎉 Setup Complete!" "Green"
    Write-Color "==================" "Green"
    Write-Color "\nYour development environment is ready!"
    Write-Color "\nNext steps:" "Cyan"
    Write-Color "1. Open the project in VS Code"
    Write-Color "2. Install the recommended extensions if not already installed"
    Write-Color "3. Run 'luau test_runner.luau' to verify everything works"
    Write-Color "4. Read TESTING.md for information on writing and running tests"
    Write-Color "\nHappy coding! 🚀" "Magenta"
}

# Main execution
Write-Color "\n🚀 Kaiju Battle Development Environment Setup" "Cyan"
Write-Color "==================================" "Cyan"

# Install required tools
Install-Luau
Install-VSCodeExtensions

# Setup Git hooks
Setup-GitHooks

# Show completion message
Show-SetupComplete

# Pause to see the output
Write-Host "\nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
