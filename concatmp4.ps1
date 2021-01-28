param ($dirstring="*")

$ffmpeg = "D:\Download\ffmpeg-20200729-cbb6ba2-win64-static\ffmpeg.exe"
cd E:\camera\xiaomi_camera_videos\788b2ab6a8c1\

$days = dir -Directory | where {$_.name -match "$dirstring"} 

$days | % {write-verbose -verbose $_.fullname}

foreach ($aday in $days)
{
    write-verbose -Verbose $aday
    cd $aday.fullname 
    
    $kameravideos = dir "*m*s_*.mp4" -File | % {"file $($_.name)"}
    Write-Verbose -Verbose $($kameravideos -join ",")
    
    if ($kameravideos.count -ge 1)
    { 
       $kameravideos | &$ffmpeg -protocol_whitelist file,pipe -f concat -safe 0 -i - -c:v copy -c:a aac "..\$(split-path (pwd).path -leaf).mp4"
    } 
}


cd E:\camera\xiaomi_camera_videos\788b2ab6a8c1\

dir | Group-Object -Property basename | where {$_.count -ge 2}