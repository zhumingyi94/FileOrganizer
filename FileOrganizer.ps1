# Define the root directory for organized files
$rootDir = "C:\Users\Admin\Documents"

# Define your categories and their subcategories with updated directory names
$categories = @{
    "DL" = @("Deep Learning")
    "MATH" = @("Mathematics")
    "CS" = @("Computer Science")
    "PROD" = @("Productivity")
    "MIS" = @("Miscellaneous")
}

# Define file types
$fileTypes = @("Mis", "Paper", "Books", "Image", "Vids", "Short pdf")

# Function to log messages
function Log-Message($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message"
    Add-Content -Path "FileOrganizerLog.txt" -Value "[$timestamp] $message"
}

# Function to determine the category and subcategory
function Get-FileCategory($fileName) {
    Log-Message "Determining category for file: $fileName"
    foreach ($cat in $categories.Keys) {
        if ($fileName -match "^$cat") {
            Log-Message "Matched category: $cat"
            # Assuming that subcategories are no longer used
            return @{Category = $cat; Subcategory = $categories[$cat][0]}
        }
    }
    Log-Message "No category matched, using 'MIS'"
    return @{Category = "MIS"; Subcategory = $categories["MIS"][0]}
}

# Function to determine the file type
function Get-FileType($fileName) {
    Log-Message "Determining file type for: $fileName"
    if ($fileName -match "_(\d+)\.") {
        $typeIndex = [int]$Matches[1]
        Log-Message "File type index: $typeIndex"
        if ($typeIndex -ge 0 -and $typeIndex -lt $fileTypes.Count) {
            $type = $fileTypes[$typeIndex]
            Log-Message "Matched file type: $type"
            return $type
        }
    }
    Log-Message "No specific file type matched, using 'Mis'"
    return "Mis"
}

# Function to organize a file
function Organize-File($filePath) {
    try {
        Log-Message "Starting to organize file: $filePath"
        if (!(Test-Path $filePath)) {
            Log-Message "File no longer exists: $filePath"
            return
        }
        $fileName = [System.IO.Path]::GetFileName($filePath)
        Log-Message "File name: $fileName"
        
        $fileInfo = Get-FileCategory $fileName
        Log-Message "Category: $($fileInfo.Category), Subcategory: $($fileInfo.Subcategory)"
        
        $fileType = Get-FileType $fileName
        Log-Message "File Type: $fileType"
        
        $destPath = Join-Path $rootDir $fileInfo.Category
        $destPath = Join-Path $destPath $fileType
        Log-Message "Destination Path: $destPath"
        
        if (!(Test-Path $destPath)) {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            Log-Message "Created directory: $destPath"
        }
        
        $newFilePath = Join-Path $destPath $fileName
        Log-Message "Attempting to move file from $filePath to $newFilePath"
        Move-Item $filePath $newFilePath -Force
        Log-Message "Moved $fileName to $newFilePath"
    }
    catch {
        Log-Message "Error organizing file $filePath : $_"
        Log-Message "Error details: $($_.Exception.Message)"
        Log-Message "Error stack trace: $($_.ScriptStackTrace)"
    }
}

# Function to scan and organize files in both Downloads and Documents
function Scan-And-Organize-Files {
    $foldersToWatch = @("C:\Users\Admin\Downloads", "C:\Users\Admin\Documents")
    
    foreach ($folder in $foldersToWatch) {
        Log-Message "Watching folder: $folder"
        
        # Immediate check for existing files
        Log-Message "Checking for existing files matching the pattern..."
        $existingFiles = Get-ChildItem -Path $folder -File | Where-Object { $_.Name -match '^(DL|MATH|CS|PROD|MIS)_\d+\.\d+\.' }
        Log-Message "Found $($existingFiles.Count) matching files in $folder"
        foreach ($file in $existingFiles) {
            Log-Message "Found existing file: $($file.FullName)"
            Organize-File $file.FullName
        }
    }
}

# Main loop that runs the file organizer every 30 seconds
try {
    while ($true) {
        Scan-And-Organize-Files
        Log-Message "Sleeping for 30 seconds before next scan..."
        Start-Sleep -Seconds 30
    }
}
finally {
    Log-Message "File organizer stopped."
}
