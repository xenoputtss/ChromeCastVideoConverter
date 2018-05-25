param (
    [Parameter(Mandatory = $true)][string]$inputFolder
)

Get-ChildItem -File -Recurse $inputFolder | Sort-Object | ForEach-Object { 
    $fullName = $_.fullname
    $cmdOutput = ffprobe -i "$fullName" 2>&1

    $hasVideo = $cmdOutput|Select-String -Pattern "Video:" #is there a video stream
    $hasAudio = $cmdOutput|Select-String -Pattern "\(eng\): Audio:" #is there an audio stream
    if(-Not $hasAudio){
        Remove-Item $fullName
        "$fullName"
    }
}   