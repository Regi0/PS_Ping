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

# Create a runspace to ping each host simultaneously
$jobs = @()

Get-Content $HostsFile | ForEach-Object {
    $CurrentHost = $_.Trim()
    if (-not [string]::IsNullOrWhiteSpace($CurrentHost)) {
        # Start each ping in the background as a job with the ping logic defined inside the job
        $jobs += Start-Job -ScriptBlock {
            param ($HostToPing, $OutputFilePath, $PingCount)
            
            # Define the Ping-Host function inside the job
            function Ping-Host {
                param (
                    [string]$TargetHost
                )
                
                $PingResult = Test-Connection -ComputerName $TargetHost -Count $PingCount -ErrorAction SilentlyContinue | Out-String
                
                if ($PingResult) {
                    Add-Content -Path $OutputFilePath -Value "Pinging $TargetHost..."
                    Add-Content -Path $OutputFilePath -Value $PingResult
                } else {
                    Add-Content -Path $OutputFilePath -Value "Ping to $TargetHost failed."
                }
            }
            
            # Call the Ping-Host function with the current host
            Ping-Host -TargetHost $HostToPing
        } -ArgumentList $CurrentHost, $OutputFile, $PingCount
    }
}

# Wait for all jobs to complete and collect results
$jobs | ForEach-Object {
    # Wait for the job to complete and then remove it
    Wait-Job -Job $_
    Receive-Job -Job $_
    Remove-Job -Job $_
}

Write-Host "Ping results saved to $OutputFile" -ForegroundColor Green
