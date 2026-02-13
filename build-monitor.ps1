<#
.SYNOPSIS
    Automated Build Script - Reads config and builds monitor EXE
.DESCRIPTION
    Reads build-config.ini, encrypts token, injects settings, and creates EXE
#>

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "AUTOMATED MONITOR BUILD SYSTEM" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

# Function to read INI file
function Read-IniFile {
    param([string]$Path)
    
    $config = @{}
    
    if (-not (Test-Path $Path)) {
        Write-Host "Error: Config file not found: $Path" -ForegroundColor Red
        return $null
    }
    
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and -not $line.StartsWith('[')) {
            if ($line -match '^(.+?)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $config[$key] = $value
            }
        }
    }
    
    return $config
}

# Read build config
Write-Host "[1/6] Reading build configuration..." -ForegroundColor Yellow
$config = Read-IniFile -Path ".\build-config.ini"

if ($null -eq $config) {
    Write-Host "Failed to read build-config.ini" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Validate required fields
Write-Host "[2/6] Validating configuration..." -ForegroundColor Yellow
$requiredFields = @('AppName', 'ExePath', 'DropboxAccessToken')
$missing = @()

foreach ($field in $requiredFields) {
    if (-not $config.ContainsKey($field) -or [string]::IsNullOrEmpty($config[$field])) {
        $missing += $field
    }
}

if ($missing.Count -gt 0) {
    Write-Host "Error: Missing required fields in build-config.ini:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "`nPlease edit build-config.ini and fill in all required fields." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  Success - App Name: $($config['AppName'])" -ForegroundColor Green
Write-Host "  Success - Exe Path: $($config['ExePath'])" -ForegroundColor Green
Write-Host "  Success - Dropbox Token: $(if ($config['DropboxAccessToken']) { 'Provided' } else { 'Missing' })" -ForegroundColor Green

# Encryption key (must match the one in the template)
$ENCRYPTION_KEY = @(0x1F, 0x3A, 0x5C, 0x7E, 0x9B, 0xAD, 0xCF, 0xE1,
                    0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0x01,
                    0x13, 0x24, 0x35, 0x46, 0x57, 0x68, 0x79, 0x8A,
                    0x9B, 0xAC, 0xBD, 0xCE, 0xDF, 0xE0, 0xF1, 0x02)

# Encrypt the Dropbox token
Write-Host "`n[3/6] Encrypting Dropbox token..." -ForegroundColor Yellow

function Encrypt-Token {
    param([string]$Token, [byte[]]$Key)
    
    try {
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $Key
        $aes.GenerateIV()
        
        $tokenBytes = [System.Text.Encoding]::UTF8.GetBytes($Token)
        $encryptor = $aes.CreateEncryptor()
        $encryptedBytes = $encryptor.TransformFinalBlock($tokenBytes, 0, $tokenBytes.Length)
        
        $result = $aes.IV + $encryptedBytes
        $encryptedString = [Convert]::ToBase64String($result)
        
        $aes.Dispose()
        return $encryptedString
    }
    catch {
        Write-Host "Error encrypting token: $_" -ForegroundColor Red
        return $null
    }
}

$encryptedToken = Encrypt-Token -Token $config['DropboxAccessToken'] -Key $ENCRYPTION_KEY

if ($null -eq $encryptedToken) {
    Write-Host "Failed to encrypt token!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  Success - Token encrypted successfully" -ForegroundColor Green

# Load the template script
Write-Host "`n[4/6] Generating monitor script..." -ForegroundColor Yellow

if (-not (Test-Path ".\monitor-template.ps1")) {
    Write-Host "Error: monitor-template.ps1 not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$template = Get-Content ".\monitor-template.ps1" -Raw

# Inject configuration values
$script = $template
$script = $script -replace '<<ENCRYPTED_TOKEN>>', $encryptedToken
$script = $script -replace '<<APP_NAME>>', $config['AppName']
$script = $script -replace '<<EXE_PATH>>', $config['ExePath']
$script = $script -replace '<<LOG_DIRECTORY>>', $(if ($config['LogDirectory']) { $config['LogDirectory'] } else { '.\logs' })
$script = $script -replace '<<QUIET_TIMEOUT_SECONDS>>', $(if ($config['QuietTimeoutSeconds']) { $config['QuietTimeoutSeconds'] } else { '2' })
$script = $script -replace '<<SHOW_LOG_LOCATION>>', $(if ($config['ShowLogLocation']) { $config['ShowLogLocation'] } else { 'true' })
$script = $script -replace '<<SHOW_CONSENT_MESSAGE>>', $(if ($config['ShowConsentMessage']) { $config['ShowConsentMessage'] } else { 'true' })
$script = $script -replace '<<AUTO_SUBMIT_CRASH_REPORTS>>', $(if ($config['AutoSubmitCrashReports']) { $config['AutoSubmitCrashReports'] } else { 'false' })

# Save the generated script
$generatedScript = ".\monitor-app-generated.ps1"
Set-Content -Path $generatedScript -Value $script

Write-Host "  Success - Script generated: $generatedScript" -ForegroundColor Green

# Check if PS2EXE is installed
Write-Host "`n[5/6] Checking for PS2EXE module..." -ForegroundColor Yellow

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "  Installing PS2EXE module..." -ForegroundColor Yellow
    Install-Module -Name ps2exe -Scope CurrentUser -Force
    Write-Host "  Success - PS2EXE installed" -ForegroundColor Green
} else {
    Write-Host "  Success - PS2EXE already installed" -ForegroundColor Green
}

# Convert to EXE
Write-Host "`n[6/6] Converting to EXE..." -ForegroundColor Yellow

$outputExe = if ($config['OutputExeName']) { $config['OutputExeName'] } else { 'monitor-app.exe' }
$companyName = if ($config['CompanyName']) { $config['CompanyName'] } else { 'YourCompany' }
$productName = if ($config['ProductName']) { $config['ProductName'] } else { 'App Monitor' }
$copyright = if ($config['CopyrightYear']) { $config['CopyrightYear'] } else { '2024' }
$version = if ($config['Version']) { $config['Version'] } else { '2.0.0.0' }
$iconFile = if ($config['IconFile']) { $config['IconFile'] } else { '' }

# Validate icon file if provided
if ($iconFile -and -not (Test-Path $iconFile)) {
    Write-Host "  Warning: Icon file not found: $iconFile" -ForegroundColor Yellow
    Write-Host "  Continuing without icon..." -ForegroundColor Yellow
    $iconFile = ''
} elseif ($iconFile) {
    Write-Host "  Using icon: $iconFile" -ForegroundColor Cyan
}

Import-Module ps2exe

try {
    Invoke-PS2EXE -inputFile $generatedScript `
                  -outputFile $outputExe `
                  -noConsole:$false `
                  -requireAdmin:$false `
                  -title $config['AppName'] `
                  -description "$($config['AppName']) Monitor and Crash Reporter" `
                  -company $companyName `
                  -product $productName `
                  -copyright $copyright `
                  -version $version `
                  -iconFile $iconFile
    
    if (Test-Path $outputExe) {
        Write-Host "`n============================================================" -ForegroundColor Green
        Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
        Write-Host "============================================================`n" -ForegroundColor Green
        
        Write-Host "Output file: $outputExe" -ForegroundColor White
        Write-Host "File size: $((Get-Item $outputExe).Length / 1KB) KB`n" -ForegroundColor White
        
        Write-Host "Configuration Summary:" -ForegroundColor Cyan
        Write-Host "  App Name: $($config['AppName'])" -ForegroundColor White
        Write-Host "  Monitored EXE: $($config['ExePath'])" -ForegroundColor White
        Write-Host "  Log Directory: $(if ($config['LogDirectory']) { $config['LogDirectory'] } else { '.\logs' })" -ForegroundColor White
        Write-Host "  Quiet Timeout: $(if ($config['QuietTimeoutSeconds']) { $config['QuietTimeoutSeconds'] } else { '2' }) seconds" -ForegroundColor White
        Write-Host "  Icon: $(if ($iconFile) { $iconFile } else { 'Default Windows icon' })" -ForegroundColor White
        Write-Host "  Dropbox: Enabled (Encrypted)" -ForegroundColor White
        
        Write-Host "`nNext Steps:" -ForegroundColor Yellow
        Write-Host "  1. Test the EXE: .\$outputExe" -ForegroundColor White
        Write-Host "  2. Distribute $outputExe with your game" -ForegroundColor White
        Write-Host "  3. Place it in the same directory as $($config['ExePath'])" -ForegroundColor White
        Write-Host "`n  DO NOT distribute:" -ForegroundColor Red
        Write-Host "    - build-config.ini (contains your unencrypted token)" -ForegroundColor Red
        Write-Host "    - monitor-app-generated.ps1 (source code)" -ForegroundColor Red
        Write-Host "    - Any .ps1 files" -ForegroundColor Red
        
    } else {
        Write-Host "Error: EXE was not created!" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error during conversion: $_" -ForegroundColor Red
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
