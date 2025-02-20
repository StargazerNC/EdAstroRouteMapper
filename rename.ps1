param (
    [Parameter(Mandatory = $true)]
    [string]$RootFolder
)

# Check if the folder exists
if (!(Test-Path -Path $RootFolder -PathType Container)) {
    Write-Host "Error: The specified folder does not exist." -ForegroundColor Red
    exit
}

# Get all files recursively
$Files = Get-ChildItem -Path $RootFolder -File -Recurse

foreach ($File in $Files) {
    # Get file creation date in YYYYMMDD format
    $CreationDate = $File.CreationTime.ToString("yyyyMMdd")

    # Create the new file name with the date prefix
    $NewName = "$CreationDate-$($File.Name)"

    # Define the full new path
    $NewFullPath = Join-Path -Path $File.DirectoryName -ChildPath $NewName

    # Check if a file with the new name already exists and add a counter if needed
    $Counter = 1
    while (Test-Path -Path $NewFullPath) {
        $NewName = "$CreationDate-$Counter-$($File.Name)"
        $NewFullPath = Join-Path -Path $File.DirectoryName -ChildPath $NewName
        $Counter++
    }

    # Rename the file
    Rename-Item -Path $File.FullName -NewName $NewFullPath -Force
}

Write-Host "Renaming complete!"
# Example usage: .\RenameFiles.ps1 -RootFolder "C:\Path\To\Your\Folder"