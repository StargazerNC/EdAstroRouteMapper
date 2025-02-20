param (
    [Parameter(Mandatory = $true)]
    [string]$RootFolder,

    [int]$ImageDuration = 5  # Duration per image in seconds
)

# Define Shotcut project file
$ProjectFile = Join-Path -Path $RootFolder -ChildPath "slideshow.mlt"

# Start building the MLT XML content
$MLTContent = @"
<?xml version="1.0" encoding="utf-8"?>
<mlt LC_NUMERIC="C" version="7.0.0">
    <profile description="automatic" width="1920" height="1080" progressive="1" sample_aspect_num="1" sample_aspect_den="1" display_aspect_num="16" display_aspect_den="9" frame_rate_num="30" frame_rate_den="1" colorspace="709"/>
"@

# Get all directories in the root folder
$Folders = Get-ChildItem -Path $RootFolder -Directory -Recurse

$FrameRate = 30
$ImageFrames = $ImageDuration * $FrameRate
$TotalFrames = 0
$ProducerID = 1

# Create the main playlist
$MLTContent += @"
    <playlist id="main_playlist">
"@

# Process each folder
foreach ($Folder in $Folders) {
    Write-Host "Processing folder: $($Folder.FullName)"

   # Add title slide as a text producer
    $TitleText = [System.IO.Path]::GetFileName($Folder.FullName)  # Extract folder name
    $MLTContent += "<producer id=`"title-$ProducerID`">"
    $MLTContent += "<property name=`"resource`">color:#000000</property>"
    $MLTContent += "<property name=`"length`">$ImageFrames</property>"
    $MLTContent += "<property name=`"eof`">pause</property>"
    $MLTContent += "<filter>"
    $MLTContent += "<property name=`"mlt_service`">dynamictext</property>"
    $MLTContent += "<property name=`"text`">$TitleText</property>"
    $MLTContent += "<property name=`"family`">Arial</property>"
    $MLTContent += "<property name=`"size`">64</property>"
    $MLTContent += "<property name=`"fgcolour`">#FFFFFF</property>"
    $MLTContent += "<property name=`"bgcolour`">#00000000</property>"
    $MLTContent += "<property name=`"outline`">1</property>"
    $MLTContent += "</filter>"
    $MLTContent += "</producer>"

    # Add title slide to the playlist
    $MLTContent += "<entry producer=`"title-$ProducerID`" in=`"0`" out=`"$ImageFrames`"/>"
    $ProducerID++
    $TotalFrames += $ImageFrames

    $ProducerID++

    # Get image files in the current folder
    $Files = Get-ChildItem -Path $Folder.FullName -Include *.jpg, *.png, *.jpeg -File -Recurse | Sort-Object FullName

    if ($Files.Count -eq 0) {
        Write-Host "No image files found in folder: $($Folder.FullName)" -ForegroundColor Red
        continue
    }

    # Add images as producers & playlist entries
    foreach ($File in $Files) {
        # Convert file path to Shotcut format
        $FilePath = $File.FullName -replace '\\', '/'

        # Add producer for the image
        $MLTContent += "<producer id=`"producer-$ProducerID`">"
        $MLTContent += "<property name=`"resource`">$FilePath</property>"
        $MLTContent += "<property name=`"ttl`">1</property>"
        $MLTContent += "<property name=`"length`">$ImageFrames</property>"
        $MLTContent += "<property name=`"eof`">pause</property>"
        $MLTContent += "</producer>"

        # Add entry to playlist
        $MLTContent += "<entry producer=`"producer-$ProducerID`" in=`"0`" out=`"$ImageFrames`"/>"

        $ProducerID++
        $TotalFrames += $ImageFrames

    }
}
    
# Close the playlist
$MLTContent += @"
    </playlist>
"@

# Add timeline (tractor)
$MLTContent += @"
    <tractor id="timeline">
        <track producer="main_playlist"/>
    </tractor>
</mlt>
"@

# Save the MLT project file
$MLTContent | Set-Content -Path $ProjectFile -Encoding UTF8

Write-Host "Shotcut project created successfully: $ProjectFile"
