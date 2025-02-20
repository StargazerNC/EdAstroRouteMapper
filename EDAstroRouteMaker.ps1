param (
    [string]$inputFile = "systems.txt",
    [string]$outputFile = "output.json"
)

$baseUrl = "https://www.edsm.net/api-v1/systems"
$results = @()

# Read system names from file
$systemNames = Get-Content $inputFile

foreach ($name in $systemNames) {
    $url = "$($baseUrl)?systemName=$($name)&onlyKnownCoordinates=1&showCoordinates=1"

    #Write-Host "Url to be called: $($url)"

    $response = Invoke-RestMethod -Uri $url -Method Get
    
    if ($response -and $response.Count -gt 0) {
        foreach ($system in $response) {
            $results += @{
                "pin"  = "blue"
                "text" = $system.name
                "x"    = $system.coords.x
                "y"    = $system.coords.y
                "z"    = $system.coords.z
            }
        }
    }
}

# Format JSON output
$jsonOutput = @{
    "markers" = $results
} | ConvertTo-Json -Depth 3

# Save to file
$jsonOutput | Set-Content -Path $outputFile -Encoding UTF8

Write-Host "Data saved to $outputFile"
