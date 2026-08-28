param(
    [ValidateSet('run', 'debug', 'release')]
    [string]$Mode = 'run',
    [string]$Device = 'emulator-5554'
)

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $repositoryRoot '.env'
$flutterProject = Join-Path $repositoryRoot 'apps\logicx_loom_flutter'
$flutterCommand = 'C:\Users\sunda\development\flutter\bin\flutter.bat'

if (-not (Test-Path -LiteralPath $environmentFile)) {
    throw "Missing $environmentFile. Copy .env.example to .env first."
}

$values = @{}
foreach ($line in Get-Content -LiteralPath $environmentFile) {
    if ($line -match '^\s*([^#][^=]*)=(.*)$') {
        $values[$matches[1].Trim()] = $matches[2].Trim()
    }
}

function Get-MobileValue([string]$Name, [string]$Fallback) {
    $value = $values[$Name]
    if ([string]::IsNullOrWhiteSpace($value)) { return $Fallback }
    return $value
}

function Get-MobileBool([string]$Name, [string]$Fallback) {
    return ((Get-MobileValue $Name $Fallback) -eq '1').ToString().ToLowerInvariant()
}

$mobileEnvironment = (Get-MobileValue 'MOBILE_APP_ENVIRONMENT' (Get-MobileValue 'NODE_ENV' 'development')).ToLowerInvariant()
if ($mobileEnvironment -notin @('development', 'production')) {
    throw 'MOBILE_APP_ENVIRONMENT must be development or production.'
}

$mobileApiUrl = if ($mobileEnvironment -eq 'production') {
    Get-MobileValue 'MOBILE_PRODUCTION_API_URL' 'https://log.logicx.in/api/platform'
} else {
    Get-MobileValue 'MOBILE_DEVELOPMENT_API_URL' 'http://10.0.2.2:9350'
}

$defines = @(
    "--dart-define=LOGICX_LOOM_API_URL=$mobileApiUrl",
    "--dart-define=LOGICX_LOOM_DEVELOPMENT_AUTO_LOGIN=$(Get-MobileBool 'MOBILE_DEVELOPMENT_AUTO_LOGIN' '0')",
    "--dart-define=LOGICX_LOOM_UPDATE_URL=$(Get-MobileValue 'MOBILE_UPDATE_URL' 'https://log.logicx.in/storage/mobile/release/update.json')"
)

Push-Location $flutterProject
try {
    Write-Host "Building LogicX Loom Flutter for $mobileEnvironment."
    switch ($Mode) {
        'run' { & $flutterCommand run -d $Device @defines }
        'debug' { & $flutterCommand build apk --debug @defines }
        'release' { & $flutterCommand build apk --release @defines }
    }
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
