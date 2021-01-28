$ffmpeg = "D:\Download\ffmpeg-20200729-cbb6ba2-win64-static\ffmpeg.exe"
cd E:\camera\xiaomi_camera_videos\788b2ab6a8c1\

$days = dir 20210108*.mp4 -File | % { $($_.basename).substring(0,8)}  | select -Unique

$days | % {Write-Verbose -Verbose $_}

Read-Host

foreach ($aday in $days)
{

    dir "$($aday)*.mp4" | % {"file $($_.name)"}  | &$ffmpeg -protocol_whitelist file,pipe -f concat -safe 0 -i - -c:v copy -c:a aac "..\$($aday).mp4"    

}


cd E:\camera\xiaomi_camera_videos\788b2ab6a8c1\