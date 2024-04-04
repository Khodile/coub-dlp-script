# coub-dlp-script
Script for downloading and looping video developed for coub.com.

## How it works
First of all script trying to download video- and audio- files separately from all urls in batch-file. Then it loops files to obtain video- and audio- files longer than specified as minimum. Thus will be selected such a duration so that the audio is played an integer number of times.

## Installation (Linux)
You must have installed ffmpeg, ffprobe and yt-dlp.

1. Clone repository

```git clone https://github.com/Khodile/coub-dlp-script.git```

2. Configure the script
   a) Open coub-dlp.sh in your favourite text editor.
   b) Change the parameter values to the desired ones on lines 3 to 12.
      (Note: Strings for the *_DIRECTORY parameters must end with /)

3. Create batch-file and archive-file in choosen destinations

4. Copy urls to the batch-file

5. Start script

```bash /path/to/script/coub-dlp.sh```

## Parameters
| Parameter                | Type   | Description |
|--------------------------|--------|-------------|
| MINIMAL_DURATION_SECONDS | int    | Target minimal duration of resulting video files in seconds
| FREE_SPACE_RESERVE_KiB   | int    | Minimal amount of free space in target directory in KiB at which processing can be started |
| YT_DLP_ARCHIVE_FILE      | String | Path to the download-archive file for yt-dlp call. Yt-dlp download only videos not listed in the archive file. Record the IDs of all downloaded videos in it |
| YT_DLP_BATCH_FILE        | String | Path to the batch-file for yt-dlp call. Batch-file is a file containing URLs to download ("-" for stdin), one URL per line. Lines starting with "#", ";" or "]" are considered as comments and ignored |
| LOGS_DIRECTORY           | String | Path to the directory where script will create log files |
| YT_DLP_TARGET_DIRECTORY  | String | Path to the directory where files will be saved by yt-dlp |
| YT_DLP_OUTPUT_TEMPLATE   | String | Yt-dlp [output template](https://github.com/yt-dlp/yt-dlp#output-template) (relative path in YT_DLP_TARGET_DIRECTORY).  |
| FINAL_TARGET_DIRECTORY   | String | Path to the directory where resulting video files will be saved |
