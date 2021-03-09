# minutes -> day
$ffmpeg = "c:\ffmpeg\ffmpeg.exe"

$source_folder = "C:\SHARED\xiaomi_camera_videos"
# $source_folder = "c:\SHARED\1\"
$dest_folder = "C:\shared\GoogleBackup"
$delete_folder = "C:\SHARED\to_be_deleted"


$script_folder = Split-Path -parent $MyInvocation.MyCommand.Path
cd $script_folder


$today = get-date -format yyyyMMdd
write-verbose -verbose "Today = $today"
$days = dir $source_folder -rec -Directory  | where {$_.name -lt $today} | % { ($_.fullname).substring(0,$_.FullName.Length-2)}  | select -Unique


$days | % {Write-Verbose -Verbose "$(get-date) | $_"}

foreach ($aday in $days)
{

    Write-Verbose -verbose "working day: $aday"

    Write-Verbose -Verbose "$(get-date) | **************** Processing $aday *********************"
    write-verbose -verbose "$(get-date) | getting files"
    $allvideos = dir -Recurse "$($aday)*" | where {$_.Length -gt 0} | sort -pro fullname | % {$_.fullname}
    write-verbose -verbose "$(get-date) | checking for corrupt video files"
    $goodvideos = @()
    $allvideos | % {
        & $ffprobe -i $_ -loglevel quiet
        if ($lastexitcode)
        {
            write-verbose -verbose "$(get-date) | Corrupt video file: $_"
        }
        else {$goodvideos += $_}
    }
    write-verbose -verbose "$(get-date) | All videos: $($allvideos.count)"
    write-verbose -verbose "$(get-date) | Good videos: $($goodvideos.count)"
    write-verbose -verbose "$(get-date) | Bad videos: $($allvideos.count - $goodvideos.count)"

    write-verbose -verbose "$(get-date) | massaging file names for ffmpeg list"
    $ffmpeglist = $goodvideos | % {"file $($_.replace('\','/'))"}  
    # $minutevideos | % {write-verbose -Verbose $_}
    
    $filename = split-path -Path $aday -Leaf
    $filename = $filename.substring(0,4) + "." + $filename.substring(4,2) + "." + $filename.substring(6,2)
    Write-Verbose -Verbose "$(get-date) | Filename = $filename"

    $kamera = split-path -path (split-path -Path $aday) -Leaf
    switch ($kamera)
    {
        "788b2aab82a9" {$kamera = "macskamera2";break}
        "788b2ab6a8c1" {$kamera = "macskamera1";break}
        "788b2ab6b647" {$kamera = "macskamera3";break}
        "788b2ab6be5c" {$kamera = "macskamera4";break}
        default {}
    }
    Write-Verbose -Verbose "$(get-date) | kamera = $kamera"

    $ffmpeglist | % {write-debug "$(get-date) | $_" }
    write-verbose -verbose "$(get-date) | Starting ffmpeg work."
    $ffmpeglist | &$ffmpeg -protocol_whitelist file,pipe -f concat -safe 0 -i - -c:v copy -c:a aac "$dest_folder\$filename-$kamera.mp4" -y  -hide_banner -loglevel error -nostats
    $ffmpeg_result_code = $lastexitcode
    Write-Verbose -Verbose "$(get-date) | ffmpeg exit code: $ffmpeg_result_code"

    $videofile = dir "$dest_folder\$filename-$kamera.mp4"
    Write-Verbose -verbose "$(get-date) | Filename: $($videofile.fullname), size: $($videofile.length)"
 
    if ($ffmpeg_result_code -eq 0)
    {
            Write-Verbose -Verbose "$(get-date) | No error from last ffmpeg command (lastexitcode = $ffmpeg_result_code)."
        
            if ($videofile.length -gt 5GB)
            {
                Write-Verbose -Verbose "$(get-date) | File size -gt 5GB -> Deleting source files - $aday*..."
                if (-NOT (Test-Path -Path "$delete_folder\$kamera\" -PathType Container)) {New-Item -Path "$delete_folder" -Name $kamera -ItemType Directory -Verbose}
                Move-Item -Path $aday* -Destination "$delete_folder\$kamera\" -Verbose

                # write-verbose -Verbose "$(get-date) | Starting motion detection on $($videofile.fullname)"
                # c:\shared\DVR-Scan\dvr-scan.exe -i $($videofile.fullname) -so -df 2 2>$null
                # write-verbose -Verbose "$(get-date) | Motion detection done."
            }
            else {write-verbose -verbose "$(get-date) | File size -lt 5GB, not deleting source files."}

     }
     else {write-verbose -verbose "$(get-date) | Error from last ffmpeg run (lastexitcode = $ffmpeg_result_code)."}



}



# add dvr-scan step
