# EarningsEdgeDetection CLI Scanner Runner (PowerShell)
# Usage:
#   .\run.ps1                     - Run scanner with current date
#   .\run.ps1 MM/DD/YYYY          - Run scanner with specified date
#   .\run.ps1 -l                  - Run with list format
#   .\run.ps1 -i                  - Run with iron fly calculations
#   .\run.ps1 -a TICKER           - Analyze a specific ticker
#   .\run.ps1 -a TICKER -i        - Analyze ticker with iron fly strategy

# Ensure dependencies are installed
# pip install -r requirements.txt

# Get number of logical processors
$NUM_CORES = [Environment]::ProcessorCount

# Use half the available cores (minimum 2, maximum 6)
$WORKERS = [math]::Max(2, [math]::Min(6, [math]::Floor($NUM_CORES / 2)))

# Initialize flags
$LIST_FLAG = ""
$IRONFLY_FLAG = ""
$ANALYZE_FLAG = ""
$FINNHUB_FLAG = ""
$DOLTHUB_FLAG = ""
$COMBINED_FLAG = ""
$ANALYZE_TICKER = $null
$ANALYZE_MODE = $false

get-content .env | ForEach-Object {
    $name, $value = $_.split('=')
    set-content env:\$name $value
}

# Parse arguments
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "-l" { $LIST_FLAG = "--list" }
        "--list" { $LIST_FLAG = "--list" }
        "-i" { $IRONFLY_FLAG = "--iron-fly" }
        "--iron-fly" { $IRONFLY_FLAG = "--iron-fly" }
        "-f" { $FINNHUB_FLAG = "--use-finnhub" }
        "--use-finnhub" { $FINNHUB_FLAG = "--use-finnhub" }
        "-u" { $DOLTHUB_FLAG = "--use-dolthub" }
        "--use-dolthub" { $DOLTHUB_FLAG = "--use-dolthub" }
        "-c" { $COMBINED_FLAG = "--all-sources" }
        "--all-sources" { $COMBINED_FLAG = "--all-sources" }
        "-a" { $ANALYZE_MODE = $true }
        "--analyze" { $ANALYZE_MODE = $true }
        default {
            if ($ANALYZE_MODE -and -not $args[$i].StartsWith("-")) {
                $ANALYZE_TICKER = $args[$i]
                $ANALYZE_FLAG = "--analyze $ANALYZE_TICKER"
                $ANALYZE_MODE = $false
            }
        }
    }
}

# Handle analyze mode specifically
if ($ANALYZE_TICKER) {
    Write-Host "Analyzing ticker: $ANALYZE_TICKER"
    python scanner.py $ANALYZE_FLAG $IRONFLY_FLAG $FINNHUB_FLAG $DOLTHUB_FLAG $COMBINED_FLAG
    exit 0
}

# Check if the first argument is a date
if ($args.Count -eq 0) {
    # No arguments - run with current date
    python scanner.py --parallel $WORKERS $LIST_FLAG $IRONFLY_FLAG $FINNHUB_FLAG $DOLTHUB_FLAG $COMBINED_FLAG
} elseif ($args[0] -match '^\d{1,2}/\d{1,2}/\d{4}$') {
    # First argument is a date
    $dateArg = $args[0]
    python scanner.py --date "$dateArg" --parallel $WORKERS $LIST_FLAG $IRONFLY_FLAG $FINNHUB_FLAG $DOLTHUB_FLAG $COMBINED_FLAG
} else {
    # Assume it's a flag-based run
    python scanner.py --parallel $WORKERS $LIST_FLAG $IRONFLY_FLAG $FINNHUB_FLAG $DOLTHUB_FLAG $COMBINED_FLAG
}
