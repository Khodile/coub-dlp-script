#!/bin/bash

MINIMAL_DURATION_SECONDS=45
FREE_SPACE_RESERVE_KiB=1024

YT_DLP_ARCHIVE_FILE='./yt-dlp/downloaded.txt'
YT_DLP_BATCH_FILE='./yt-dlp/batch-file.txt'
LOGS_DIRECTORY='./logs/'

YT_DLP_TARGET_DIRECTORY='./coubs/temp/'
YT_DLP_OUTPUT_TEMPLATE='%(title)s by <%(uploader)s> [%(id)s].%(ext)s'
FINAL_TARGET_DIRECTORY='./coubs/final/'


TIMESTAMP="$(date +'%Y-%m-%d_%H:%M:%S')"
LOG_FILE="${LOGS_DIRECTORY}${TIMESTAMP}_coub-dlp.log"

yt-dlp --ignore-config --download-archive $YT_DLP_ARCHIVE_FILE --batch-file $YT_DLP_BATCH_FILE --format bestvideo/mp4/bestvideo*,bestaudio/mp3/bestaudio* --output "${YT_DLP_TARGET_DIRECTORY}${YT_DLP_OUTPUT_TEMPLATE}"

echo -e "All coubs are downloaded.\n" > $LOG_FILE

shopt -s dotglob
echo -e "Included hidden files.\n" >> $LOG_FILE

for VIDEO_FILE in $YT_DLP_TARGET_DIRECTORY*.mp4
do
  echo -e "\n====================\n" >> $LOG_FILE
  echo -e "\tStart processing video file:\t$VIDEO_FILE\n" >> $LOG_FILE
  
  AUDIO_FILE="${VIDEO_FILE%.mp4}.mp3"
  FREE_SPACE=$(df "$FINAL_TARGET_DIRECTORY" | awk '/[0-9]%/{print $(NF-2)}')
  if [[ -e "$AUDIO_FILE" && -e "$VIDEO_FILE" && $FREE_SPACE -gt $FREE_SPACE_RESERVE_KiB ]]
  then
    echo -e "\t\tThere is enough free space. $FREE_SPACE / $FREE_SPACE_RESERVE_KiB\n" >> $LOG_FILE
    echo -e "\t\tFound audio file:\n\t$AUDIO_FILE\n" >> $LOG_FILE
    
    LOOPED_VIDEO_FILE="${VIDEO_FILE%.mp4}_looped.mp4"
    LOOPED_VIDEO_FILE="${LOOPED_VIDEO_FILE/$YT_DLP_TARGET_DIRECTORY/$FINAL_TARGET_DIRECTORY}"
    LOOPED_AUDIO_FILE="${AUDIO_FILE%.mp3}_looped.mp3"
    LOOPED_AUDIO_FILE="${LOOPED_AUDIO_FILE/$YT_DLP_TARGET_DIRECTORY/$FINAL_TARGET_DIRECTORY}"
    RESULT_FILE="${VIDEO_FILE/$YT_DLP_TARGET_DIRECTORY/$FINAL_TARGET_DIRECTORY}"
    
    AUDIO_DURATION=$(ffprobe -i "$AUDIO_FILE" -show_entries format=duration -v quiet -of csv="p=0")
    if [[ $(echo -e "$AUDIO_DURATION < $MINIMAL_DURATION_SECONDS" | bc) -eq 1 ]]
    then
      echo -e "\t\tDuration of the audio file is not enough. $AUDIO_DURATION < $MINIMAL_DURATION_SECONDS\n" >> $LOG_FILE
      
      LOOPS_COUNT=$(echo -e $MINIMAL_DURATION_SECONDS $AUDIO_DURATION | awk '{printf("%d",$1 / $2 + 1)}')
      ffmpeg -y -stream_loop "$LOOPS_COUNT" -i "$AUDIO_FILE" -c copy "$LOOPED_AUDIO_FILE"
      AUDIO_DURATION=$(ffprobe -i "$LOOPED_AUDIO_FILE" -show_entries format=duration -v quiet -of csv="p=0")
    else
      echo -e "\t\tDuration of the audio file is enough. $AUDIO_DURATION >= $MINIMAL_DURATION_SECONDS\n" >> $LOG_FILE
      
      ffmpeg -y -stream_loop 0 -i "$AUDIO_FILE" -c copy "$LOOPED_AUDIO_FILE"
    fi
    VIDEO_DURATION=$(ffprobe -i "$VIDEO_FILE" -show_entries format=duration -v quiet -of csv="p=0")
    
    if [[ $(echo -e "$VIDEO_DURATION < $AUDIO_DURATION" | bc) -eq 1 ]]
    then
      echo -e "\t\tDuration of the video file is not enough. $VIDEO_DURATION < $AUDIO_DURATION\n" >> $LOG_FILE
      
      LOOPS_COUNT=$(echo -e $AUDIO_DURATION $VIDEO_DURATION | awk '{printf("%d",$1 / $2 + 1)}')
    else
      echo -e "\t\tDuration of the video file is enough. $VIDEO_DURATION >= $AUDIO_DURATION\n" >> $LOG_FILE
      
      LOOPS_COUNT=0
    fi
    
    ffmpeg -y -stream_loop "$LOOPS_COUNT" -i "$VIDEO_FILE" -c copy "$LOOPED_VIDEO_FILE"
    
    echo -e "\t\tFinal processing.\n" >> $LOG_FILE
    
    ffmpeg -y -i "$LOOPED_VIDEO_FILE" -i "$LOOPED_AUDIO_FILE" -shortest "$RESULT_FILE"
    
    
    if [[ -e "$RESULT_FILE" && "$RESULT_FILE" != "$AUDIO_FILE" ]]
    then
      echo -e "\t\tRemoving initial audio file.\n" >> $LOG_FILE
      rm "$AUDIO_FILE"
    fi
    
    if [[ -e "$LOOPED_AUDIO_FILE" && "$RESULT_FILE" != "$LOOPED_AUDIO_FILE" ]]
    then
      echo -e "\t\tRemoving looped audio file.\n" >> $LOG_FILE
      rm "$LOOPED_AUDIO_FILE"
    fi
    
    if [[ -e "$RESULT_FILE" && "$RESULT_FILE" != "$VIDEO_FILE" ]]
    then
      echo -e "\t\tRemoving initial video file.\n" >> $LOG_FILE
      rm "$VIDEO_FILE"
    fi
    
    if [[ -e "$LOOPED_VIDEO_FILE" && "$RESULT_FILE" != "$LOOPED_VIDEO_FILE" ]]
    then
      echo -e "\t\tRemoving looped video file.\n" >> $LOG_FILE
      rm "$LOOPED_VIDEO_FILE"
    fi
    
    echo -e "\tProcessing ended successfully." >> $LOG_FILE
    
  else
    echo -e "\tThere is not enough free space ($FREE_SPACE / $FREE_SPACE_RESERVE_KiB) or file(s) not exist(s)." >> $LOG_FILE
  fi
done

shopt -u dotglob
echo -e "Excluded hidden files.\n" >> $LOG_FILE

echo -e "\nScript processing ended."
