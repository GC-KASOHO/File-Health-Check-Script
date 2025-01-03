# Function to check for duplicate files
function Check-Duplicates {
    param (
        [string]$path
    )

    $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue
    $hashTable = @{}

    foreach ($file in $files) {
        $hash = Get-FileHash -Path $file.FullName
        if ($hashTable.ContainsKey($hash.Hash)) {
            $hashTable[$hash.Hash] += ,$file.FullName
        } else {
            $hashTable[$hash.Hash] = @($file.FullName)
        }
    }

    $duplicates = $hashTable.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    return $duplicates
}

# Function to check for corrupted files
function Check-CorruptedFiles {
    param (
        [string]$path
    )

    $corruptedFiles = @()
    $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        try {
            # Attempt to read the file
            Get-Content -Path $file.FullName -ErrorAction Stop | Out-Null
        } catch {
            # If an error occurs, the file is considered corrupted
            $corruptedFiles += $file.FullName
        }
    }

    return $corruptedFiles
}

# Function to delete files
function Delete-Files {
    param (
        [string[]]$files
    )

    foreach ($file in $files) {
        try {
            Remove-Item -Path $file -Force
            Write-Host "Deleted: $file"
        } catch {
            Write-Host "Failed to delete: $file. Error: $_"
        }
    }
}

# Main script
$directory = Read-Host "Enter the directory path to check for duplicates and corrupted files"

if (Test-Path $directory) {
    # Check for duplicates
    $duplicates = Check-Duplicates -path $directory

    if ($duplicates) {
        Write-Host "Duplicate files found:`n"
        foreach ($duplicate in $duplicates) {
            Write-Host "Hash: $($duplicate.Key)"
            Write-Host "Files: $($duplicate.Value -join ', ')`n"
        }

        $filesToDelete = @()
        foreach ($duplicate in $duplicates) {
            # Keep the first file and suggest deleting the rest
            $filesToDelete += $duplicate.Value[1..($duplicate.Value.Count - 1)]
        }

        # Ask user for confirmation to delete duplicates
        $confirmation = Read-Host "Do you want to delete the duplicate files? (Y/N)"
        if ($confirmation -eq 'Y') {
            Delete-Files -files $filesToDelete
        } else {
            Write-Host "No files were deleted."
        }
    } else {
        Write-Host "No duplicates found."
    }

    # Check for corrupted files
    $corruptedFiles = Check-CorruptedFiles -path $directory

    if ($corruptedFiles) {
        Write-Host "Corrupted files found:`n"
        foreach ($corruptedFile in $corruptedFiles) {
            Write-Host $corruptedFile
        }

        # Ask user for confirmation to delete corrupted files
        $confirmation = Read-Host "Do you want to delete the corrupted files? (Y/N)"
        if ($confirmation -eq 'Y') {
            Delete-Files -files $corruptedFiles
        } else {
            Write-Host "No corrupted files were deleted."
        }
    } else {
        Write-Host "No corrupted files found."
    }
} else {
    Write-Host "The specified directory does not exist."
}