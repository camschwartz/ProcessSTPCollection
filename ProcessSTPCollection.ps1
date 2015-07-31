# This is the dev version

## If ($args.GetLength() > 0) {
#        Foreach ($arg in $args) {
#            If ($arg = "-v") { $MyVerbose = True }
#            Write-Console "Verbose mode enabled."
#            }
#        }


If (Test-Path 'C:\Program Files (x86)\GnuWin32\bin\gzip.exe') 
    { $gzip_Path = 'C:\Program Files (x86)\GnuWin32\bin\gzip.exe' }
ElseIf ( Test-Path '.\gzip.exe' )
    { $gzip_Path = '.\gzip.exe' }
Else
    { 
    
    Write-Console "Gzip not detected. Please download the package from http://gnuwin32.sourceforge.net/packages/gzip.htm"
    Exit
    }

If (Test-Path 'C:\Program Files (x86)\EMC\STPTools\StpTtpCnv_4GB.exe')
    { $StpTtpCnv_Path = 'C:\Program Files (x86)\EMC\STPTools\StpTtpCnv_4GB.exe' }
ElseIf (Test-Path 'C:\Program Files (x86)\EMC\STPTools\StpTtpCnv.exe')
    { $StpTtpCnv_Path = 'C:\Program Files (x86)\EMC\STPTools\StpTtpCnv.exe' }
Else
    { 
    
    Write-Console "STPTools not detected. Please download the package from https://speed.corp.emc.com/"
    Exit
    }

## CLI Method
## $BasePath = Read-Host 'Directory/path to process?'


## GUI Method (Preferred)

## Function: Show an Open Folder Dialog and return the directory selected by the user.
function Read-FolderBrowserDialog([string]$Message, [string]$InitialDirectory, [switch]$NoNewFolderButton)
{
    $browseForFolderOptions = 0
    if ($NoNewFolderButton) { $browseForFolderOptions += 512 }

    $app = New-Object -ComObject Shell.Application
    $folder = $app.BrowseForFolder(0, $Message, $browseForFolderOptions, $InitialDirectory)
    if ($folder) { $selectedDirectory = $folder.Self.Path } else { $selectedDirectory = '' }
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($app) > $null
    return $selectedDirectory
}

$BasePath = Read-FolderBrowserDialog -Message 'Please select a directory with STP files to process.' -InitialDirectory 'C:\' -NoNewFolderButton

if (![string]::IsNullOrEmpty($BasePath)) { Write-Host "You selected the directory: $BasePath" }
else { "You did not select a directory. Exiting..."
        Exit
 }

""
"Searching for files..."

$Master_TTP_GZ_FileList = Get-ChildItem -Recurse -Path $BasePath -Filter *.ttp.gz

If ($Master_TTP_GZ_FileList) {

    $Master_TTP_GZ_FileList.Count.ToString() + " files found."

    $i = 0
    foreach ($Item in $Master_TTP_GZ_FileList) 
        {
        # Increment file counter
        $i = $i + 1

        # Build & Update Progress bar
        Write-Progress -Activity "Extracting TTP archives..." -status ("Decompressing " + $Item.Name) -PercentComplete ($i / $Master_TTP_GZ_FileList.Count * 100)

        # Test for existing file; remove as necessary
        If (Test-Path $Item.FullName.TrimEnd(".gz") ) {Remove-Item ($Item.FullName.TrimEnd(".gz"))}
    
        # Uncompress/deflate gzip files
    
        Try 
            {
            If ($MyVerbose) {
            & $gzip_Path -d -v $Item.FullName
                }
            Else {
            & $gzip_Path -d $Item.FullName
                }
            }
        Catch [Exception]
            {write-host $_.Exception.Message}
        
        Catch [NativeCommandError]
            {write-host $_.Exception.Message}
    
        # Test for successful TTP file creation
        }
    
    $Master_TTP_FileList = Get-ChildItem -Recurse -Path $BasePath -Filter *.ttp

    foreach ($Item in $Master_TTP_FileList)
        {
    
            $Item_TTPFile = Get-Item ( $Item.FullName.TrimEnd(".gz") )
        
            # Convert TTP file to BTP file
            & $StpTtpCnv_Path -f $Item_TTPFile.FullName
                
            # Test for successful TTP -> BTP conversion
            If (Test-Path ( $Item_TTPFile.FullName.TrimEnd(".ttp") + ".btp") )
                {
        
                $Item_BTPFile = Get-Item ( $Item_TTPFile.FullName.TrimEnd(".ttp") + ".btp" )
            
                # Clean up TTP file if BTP file creation successful
                Remove-Item ($Item_TTPFile)
        
            }

        }

# All finished, report to user.
 ""
 "Batch run complete."


    }
Else
    { "No files found." }

