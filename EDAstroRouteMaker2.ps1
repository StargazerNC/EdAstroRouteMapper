param (
    [string]$inputFile = "systems.txt",
    [string]$outputFile = "output.json"
)

$baseUrl = "https://www.edsm.net/api-v1/systems"
$markers = @()
$lines = @()
$firstCoords = $null
$previousCoords = $null

# Read system names from file
$systemNames = Get-Content $inputFile

foreach ($name in $systemNames) {
    $url = "$($baseUrl)?systemName=$($name)&onlyKnownCoordinates=1&showCoordinates=1"
    $response = Invoke-RestMethod -Uri $url -Method Get
    
    if ($response -and $response.Count -gt 0) {
        foreach ($system in $response) {
            # Create a marker
            $marker = @{
                "pin"  = "blue"  # Set pin color to blue
                "text" = "System: $($system.name)"
                "x"    = $system.coords.x
                "y"    = $system.coords.y  # Not used but included for completeness
                "z"    = $system.coords.z
            }
            $markers += $marker

            # Store first system coordinates for closing the loop
            if (-not $firstCoords) {
                $firstCoords = $system.coords
            }

            # Create a line from the previous system to the current one
            if ($previousCoords) {
                $line = @{
                    "x1"    = $previousCoords.x
                    "z1"    = $previousCoords.z
                    "x2"    = $system.coords.x
                    "z2"    = $system.coords.z
                    "color" = "#FFF"  # White color for lines
                }
                $lines += $line
            }

            # Store current system coords for next iteration
            $previousCoords = $system.coords
        }
    }
}

# Close the loop by connecting the last system back to the first
if ($firstCoords -and $previousCoords -and ($firstCoords -ne $previousCoords)) {
    $lines += @{
        "x1"    = $previousCoords.x
        "z1"    = $previousCoords.z
        "x2"    = $firstCoords.x
        "z2"    = $firstCoords.z
        "color" = "#FFF"  # White color for the closing line
    }
}

# Format JSON output
$jsonOutput = @{
    "markers" = $markers
    "lines"   = $lines
} | ConvertTo-Json -Depth 3

# Save to file
$jsonOutput | Set-Content -Path $outputFile -Encoding UTF8

Write-Host "Data saved to $outputFile"
