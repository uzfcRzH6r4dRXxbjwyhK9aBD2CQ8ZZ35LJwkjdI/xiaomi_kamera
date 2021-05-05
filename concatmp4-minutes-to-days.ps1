Start-Transcript -Path "C:\SHARED\Log\$(get-date -format yyyyMMdd-HHmmss).log" -Append
# minutes -> day
$ffmpeg = "c:\bin\ffmpeg.exe"
$ffprobe = "c:\bin\ffprobe.exe"

$source_folder = "C:\SHARED\xiaomi_camera_videos"
# $source_folder = "c:\SHARED\1\"
# $dest_folder = "C:\shared\GoogleBackup"
$dest_folder = "F:\camera"
$delete_folder = "c:\SHARED\to_be_deleted"


$script_folder = Split-Path -parent $MyInvocation.MyCommand.Path
cd $script_folder


$today = get-date -format yyyyMMdd
Write-Verbose "$(get-date) | Today = $today"
$days = dir $source_folder -rec -Directory  | where {$_.name -lt $today} | % { ($_.fullname).substring(0,$_.FullName.Length-2)}  | select -Unique
# $days = dir $source_folder -rec -Directory  | where {$_.fullname -match "xiaomi_camera_videos\\.*\\20210414"} | % { ($_.fullname).substring(0,$_.FullName.Length-2)}  | select -Unique


$days | % {Write-Verbose "$(get-date) | $_"}

foreach ($aday in $days)
{

    Write-Verbose "$(get-date) | working day: $aday"

    "$(get-date) | **************** Processing $aday *********************"

    $kamera = split-path -path (split-path -Path $aday) -Leaf
    switch ($kamera)
    {
        "788b2aab82a9" {$kamera = "macskamera2";break}
        "788b2ab6a8c1" {$kamera = "macskamera1";break}
        "788b2ab6b647" {$kamera = "macskamera3";break}
        "788b2ab6be5c" {$kamera = "macskamera4";break}
        default {$kamera = "FASZOMTUGGYA";break}
    }
    Write-Verbose "$(get-date) | kamera = $kamera"


    $filename = split-path -Path $aday -Leaf
    $filename = $filename.substring(0,4) + "." + $filename.substring(4,2) + "." + $filename.substring(6,2)
    Write-Verbose "$(get-date) | Filename = $filename"

    # test if there is already a file with that name
    if (test-path "$(get-date) | $dest_folder\$filename-$kamera.mp4")
    {
        Write-Verbose "$(get-date) | $dest_folder\$filename-$kamera.mp4 already exists, skipping this day '$aday'."
        Write-Verbose "$(get-date) | File size: $((dir $dest_folder\$filename-$kamera.mp4).length/1GB) GB."
        continue
    }
    
    else
    {
        Write-Verbose "$(get-date) | $dest_folder\$filename-$kamera.mp4 does NOT exist, processing files for day '$aday'."
    }



    Write-Verbose "$(get-date) | getting files"
    $allvideos = dir -Recurse "$($aday)*" | where {$_.Length -gt 0} | sort -pro fullname | % {$_.fullname}
    Write-Verbose "$(get-date) | checking for corrupt video files"
    Write-Verbose "$(get-date) | All videos: $($allvideos.count)"

    $goodvideos = @()
    $allvideos | % {
        & $ffprobe -i $_ -loglevel quiet
        if ($lastexitcode)
        {
            Write-Verbose "$(get-date) | Corrupt video file: $_"
        }
        else {$goodvideos += $_}
    }
    Write-Verbose "$(get-date) | Good videos: $($goodvideos.count)"
    Write-Verbose "$(get-date) | Bad videos: $($allvideos.count - $goodvideos.count)"

    Write-Verbose "$(get-date) | massaging file names for ffmpeg list"
    $ffmpeglist = $goodvideos | % {"file $($_.replace('\','/'))"}  
    # $minutevideos | % {Write-Verbose $_}
    

    $ffmpeglist | % {write-debug "$(get-date) | $_" }
    Write-Verbose "$(get-date) | Starting ffmpeg work."
    $ffmpeglist | &$ffmpeg -protocol_whitelist file,pipe -f concat -safe 0 -i - -c:v copy -c:a aac "$dest_folder\$filename-$kamera.mp4" -y  -hide_banner -loglevel error -nostats
    $ffmpeg_result_code = $lastexitcode
    Write-Verbose "$(get-date) | ffmpeg exit code: $ffmpeg_result_code"

    $videofile = dir "$dest_folder\$filename-$kamera.mp4"
    Write-Verbose "$(get-date) | Filename: $($videofile.fullname), size: $($videofile.length)"
 
    if ($ffmpeg_result_code -eq 0)
    {
            Write-Verbose "$(get-date) | No error from last ffmpeg command (lastexitcode = $ffmpeg_result_code)."
        
            if ($videofile.length -gt 5GB)
            {
                "$(get-date) | File size -gt 5GB -> Moving source files to $delete_folder\$kamera\$aday*..."
                if (-NOT (Test-Path -Path "$delete_folder\$kamera\" -PathType Container)) {New-Item -Path "$delete_folder" -Name $kamera -ItemType Directory}
                Move-Item -Path $aday* -Destination "$delete_folder\$kamera\"

                # Write-Verbose "$(get-date) | Starting motion detection on $($videofile.fullname)"
                # c:\shared\DVR-Scan\dvr-scan.exe -i $($videofile.fullname) -so -df 2 2>$null
                # Write-Verbose "$(get-date) | Motion detection done."
            }
            else {Write-Warning "$(get-date) | File size -lt 5GB, not deleting source files."}

     }
     else {Write-Warning "$(get-date) | Error from last ffmpeg run (lastexitcode = $ffmpeg_result_code)."}

     Write-Verbose "$(get-date) | ------------------------------------------------------------"

}



# add dvr-scan step
Stop-Transcript