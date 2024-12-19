# Configuration
$HostsFile = "/home/regi/PS_Ping/hosts.txt"            # File containing the list of hosts (one per line)
$OutputDir = "/home/regi/PS_Ping/Results"                      # Directory to store output files
$PingCount = 3                                         # Number of ping attempts per host

# Ensure the output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Get the current timestamp for the output file
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path -Path $OutputDir -ChildPath "ping_results_$Timestamp.txt"

# Check if the hosts file exists
if (-not (Test-Path $HostsFile)) {
    Write-Host "Error: Hosts file '$HostsFile' not found." -ForegroundColor Red
    exit 1
}

# Ping each host and write results to the output file
Get-Content $HostsFile | ForEach-Object {
    $CurrentHost = $_.Trim()  # Use a descriptive variable name
    if (-not [string]::IsNullOrWhiteSpace($CurrentHost)) {
        Add-Content -Path $OutputFile -Value "Pinging $CurrentHost..."
        $PingResult = Test-Connection -ComputerName $CurrentHost -Count $PingCount -ErrorAction SilentlyContinue | Out-String
        if ($PingResult) {
            Add-Content -Path $OutputFile -Value $PingResult
        } else {
            Add-Content -Path $OutputFile -Value "Ping to $CurrentHost failed."
        }
    }
}

Write-Host "Ping results saved to $OutputFile" -ForegroundColor Green
