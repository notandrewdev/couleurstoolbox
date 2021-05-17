@echo off
:: ONLY USE THIS FOR MEETING A TARGET FILESIZE TO UPLOAD TO SITES WHERE THERE ARE LIMITS
:: IF YOU JUST WANT TO REDUCE FILESIZE FOR STORAGE, USE OTHER SCRIPTS HERE!
:: Set size here, options:
:: Discord (8MB)
:: ClassicNitro (50MB)
:: Nitro (100MB)
:: Custom (in kbit, calculate using MB*8*1024)
set asksize=true
set size=Discord
:: Set focus here, options:
:: Original (keeps original framerate and resolution)
:: Framerate (tries to keep 60fps)
:: Resolution (tries to keep high res)
set askfocus=true
set focus=Framerate
:: 
:: ADVANCED OPTIONS
:: Be careful, only change them if you know what they do!
::
set audioencoder=aac
set audiobitrateperc=10
set minaudiobitrate=128
set maxaudiobitrate=256
set mintotalbitrate=500
set bitratetargetmult=1
set videoencoder=libx264
set forcepreset=no
set twopasscommand=-pass 
set encoderopts=-g 600
set videofilters=,mpdecimate=max=6
:: Bitrate targets
set /A target1 = 5000 * %bitratetargetmult%
set /A target2 = 3000 * %bitratetargetmult%
set /A target3 = 2000 * %bitratetargetmult%
set /A target4 = 1400 * %bitratetargetmult%
set /A target5 = 1000 * %bitratetargetmult%
set /A target6 = 700 * %bitratetargetmult%
set /A target7 = 500 * %bitratetargetmult%
:: Input check
if %1check == check (
    echo ERROR: no input file
    echo Drag this .bat into the SendTo folder - press Windows + R and type in shell:sendto
    echo After that, right click on your video, drag over to Send To and click on this bat there.
    pause
    exit
)
:: Length questions
set /p starttime=Where do you want your clip to start (in seconds): 
set /p time=How long after the start time do you want it to be: 
:: Focus and size questions
:: Disclaimer
if %askfocus% == true (set askdisclaimer=true)
else if %asksize% == true (set askdisclaimer=true)
else (set askdisclaimer=false)
if %askdisclaimer% == true (echo To disable these questions, set askfocus and asksize to false.)
:: Focus
if %askfocus% == true (
    cls
    echo What do you want to focus on?
    echo Framerate - keep FPS as high as possible
    echo Resolution - keep resolution as high as possible
    echo Original - try to keep original FPS and resolution
    set /p focus=
)
:: Size
if %asksize% == true (
    cls
    echo What filesize do you want to target?
    echo Discord - 8MB
    echo ClassicNitro - 50MB
    echo Nitro - 100MB
    set /p size=
)
:: Setting target filesize (in kbit)
if %size% == ClassicNitro (set filesize=409600
) else if %size% == Nitro (set filesize=819200
) else if %size% == Discord (set filesize=65535
) else (set filesize=%size%)
:: Fix issues with overhead
set /A filesize = %filesize% - 1000
:: Calculate bitrate
set /A bitrate = %filesize% / %time%
if %bitrate% LEQ %mintotalbitrate% (
    echo ERROR: Too long to compress!
    pause && exit
)
:: Audio bitrate
set /A audiobitrate = %bitrate% / %audiobitrateperc%
if %audiobitrate% GEQ %maxaudiobitrate% (set audiobitrate=256)
if %audiobitrate% LEQ %minaudiobitrate% (set audiobitrate=128)
:: Video bitrate
set /A videobitrate = %bitrate% - %audiobitrate%
echo bitrate: %bitrate% (audio: %audiobitrate%, video: %videobitrate%)
:: Choosing encoding settings
if %videobitrate% GEQ %target1% (
    set res=1440
    set fps=60
    set preset=medium
    set qpmin=20
) else if %videobitrate% GEQ %target2% (
    set res=1080
    set fps=60
    set preset=slow
    set qpmin=18
) else if %videobitrate% GEQ %target3% (
    if %focus% == Framerate (
        set res=720
        set fps=60
        set preset=slow
        set qpmin=18
    ) else (
        set res=1080
        set fps=45
        set preset=slow
        set qpmin=18
    )
) else if %videobitrate% GEQ %target4% (
    if %focus% == Framerate (
        set res=720
        set fps=60
        set preset=slower
        set qpmin=20
    ) else (
        set res=1080
        set fps=30
        set preset=slower
        set qpmin=18
    )
) else if %videobitrate% GEQ %target5% (
    if %focus% == Framerate (
        set res=720
        set fps=60
        set preset=veryslow
        set qpmin=21
    ) else (
        set res=900
        set fps=30
        set preset=veryslow
        set qpmin=18
    )
) else if %videobitrate% GEQ %target6% (
    if %focus% == Framerate (
        set res=540
        set fps=60
        set preset=veryslow
        set qpmin=20
    ) else (
        set res=720
        set fps=30
        set preset=veryslow
        set qpmin=19
    )
) else if %videobitrate% GEQ %target7% (
    if %focus% == Framerate (
        set res=360
        set fps=45
        set preset=veryslow
        set qpmin=17
    ) else (
        set res=720
        set fps=20
        set preset=veryslow
        set qpmin=20
    )
) else (
    set res=360
    set fps=30
    set preset=veryslow
    set qpmin=0
)
:: Preset force
if %forcepreset% == no (
    echo Not forcing preset
) else (
    set preset=%forcepreset%
)
:: Set -vf param
if %focus% == Original (
    set filters=-vf format=yuv420p
) else (
    set filters=-vf "fps=%fps%,scale='-2':'min(%res%,ih)':flags=lanczos,format=yuv420p%videofilters%"
)
:: Echo settings
echo %res%p%fps%, preset %preset%
:: Run ffmpeg
ffmpeg -ss %starttime% -t %time% -i %1 %filters% -c:v %videoencoder% %encoderopts% -preset %preset% -b:v %videobitrate%k -x264-params qpmin=%qpmin% %twopasscommand%1 -vsync vfr -an -f null NUL && ffmpeg -ss %starttime% -t %time% -i %1 %filters% -c:v %videoencoder% %encoderopts% -preset %preset% -b:v %videobitrate%k -x264-params qpmin=%qpmin% %twopasscommand%2 -c:a %audioencoder% -b:a %audiobitrate%k -vsync vfr -movflags +faststart "%~dpn1 (compressed).mp4"
del ffmpeg2pass-0.log
del ffmpeg2pass-0.log.mbtree
pause