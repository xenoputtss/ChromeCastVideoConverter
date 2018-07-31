# Scripts to convert most videos into a format that is streamable to a chromecast

I use Plex to stream video to various devices, chromecasts are the most common devices.  I prefer to not to have to do on the fly conversions of videos, if I have time to convert the videos into an appropriate format.  

I run this script nightly on my video folders, it doesn't re-encode videos unless necessary

There is also a script to try an identify videos that do not have an english sound track and delete them

## Usage

Create or modify the `DailyConversion.ps1` file to fit your needs and then schedule it as a task (run powershell with -file paramter )

you can also run the script manually
```
convertfiles.ps1 [your folder directory]
```

## Usage

To delete videos without english
```
HasNoEnglish.ps1 [your folder directory]
```
