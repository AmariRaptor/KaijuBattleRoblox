# Rebuild script for Rojo project
Write-Host "=== Rebuilding Rojo project ==="
rojo build -o build.rbxlx

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "✅ Build successful!"
