#!/bin/bash
#
# Bash script to set date and time of image and video files downloaded from the Signal
# Messenger, by using the date and time pattern of the filename.
# The date and time will be set in the EXIF metadata by using the tool "exiftool".
#
# Precondition
#  Install "exiftool": sudo apt install libimage-exiftool-perl
#
# Usage
#  signal-datetime.sh -p <path> [-l]
#  -p <path>: Path of signal image/video files
#  -l: Optional. If this flag is used, only the date and time of the metadata
#      is printed. No modifications are done.
#
# (c) Reiner Kopf, May 21, 2023
#

usage() { echo "Usage: $0 [-l] -p <path>"  1>&2; exit 1; }

LIST_ONLY=0

# Evaluate arguments
[ $# -eq 0 ] && usage
while getopts p:l flag
do
    case "${flag}" in
          p)   PATH_ARG=${OPTARG};;
          l)
               LIST_ONLY=1
               LIST_ARG=${OPTARG};;
          h | *) # Display help. TO DO: does not work correctly right now.
               usage
               exit 0
               ;;
      esac
done

# Debug output
echo "- Path: $PATH_ARG"
echo "- List: $LIST_ARG, list_only: $LIST_ONLY"

if ! [ -d $PATH_ARG ]; then
    echo "ERROR: The directory < $PATH_ARG > does not exist!"
    exit
fi

FILES_PROCESSED=0

# Find all files "signal-*.*" under ... folder 
for PATH_FILE in $(find $PATH_ARG -type f -name "signal-*.*")
do
     # Remove path, keep filename only
     FILE=${PATH_FILE##*/}
     # Use a regular expression to find files starting with "signal-" and extract the
     # year, month, day, hour, minute, second and milisecond from the filename
     if [[ $FILE =~ (signal-)([0-9]{4})(-)([0-9]{2})(-)([0-9]{2})(-)([0-9]{2})(-)([0-9]{2})(-)([0-9]{2})(-)([0-9]{3}) ]]; then
          YEAR="${BASH_REMATCH[2]}"
          MONTH="${BASH_REMATCH[4]}"
          DAY="${BASH_REMATCH[6]}"
          HOUR="${BASH_REMATCH[8]}"
          MINUTE="${BASH_REMATCH[10]}"
          SECOND="${BASH_REMATCH[12]}"
          MSECOND="${BASH_REMATCH[14]}"
    
          # Print the year, month, day, hour, minute, second and milisecond extracted from the filename
          #echo " File: $FILE | Year: $YEAR | Month: $MONTH | Day: $DAY | Hour: $HOUR | Minute: $MINUTE | Second: $SECOND | ms: $MSECOND"
          #echo " Year:   $YEAR"
          #echo " Month:    $MONTH"
          #echo " Day:      $DAY"
          #echo " Hour:     $HOUR"
          #echo " Minute:   $MINUTE"
          #echo " Second:   $SECOND"
          #echo " ms:      $MSECOND"
          #echo ""

          # In case '-l' for listing date/time is not selected, set date and time
          if [ $LIST_ONLY -eq 0 ]; then
               # Handle image and video files differently
               if [[ $FILE =~ (.*\.jpg)|(.*\.png) ]]; then
                    # JPG image file
                    # Set date and time in EXIF metadata
                    echo "Setting date and time of ${PATH_FILE} ..."
                    exiftool -q -overwrite_original -DateTimeOriginal="$YEAR:$MONTH:$DAY $HOUR:$MINUTE:$SECOND" -CreateDate="$YEAR:$MONTH:$DAY $HOUR:$MINUTE:$SECOND" $PATH_FILE
                    ((FILES_PROCESSED++))
               elif [[ $FILE =~ (.*\.mp4) ]]; then
                    # MP4 video file
                    # Set file modification date
                    echo "Setting file modification date and time of ${PATH_FILE} ..."
                    exiftool -q -overwrite_original -FileModifyDate="$YEAR:$MONTH:$DAY $HOUR:$MINUTE:$SECOND" $PATH_FILE
                    ((FILES_PROCESSED++))
               else
                    echo "Set date/time: unknown file type: ${FILE}!"
               fi
          fi

          # List EXIF data
          if [ $LIST_ONLY -eq 1 ]; then
               echo "Listing date and time of ${PATH_FILE} ..."
          fi
          if [[ $FILE =~ (.*\.jpg)|(.*\.png) ]]; then
               OUTPUT=$(exiftool -T -EXIF:DateTimeOriginal -EXIF:CreateDate $PATH_FILE)
               echo "  exiftool: DateTimeOriginal CreateDate: $OUTPUT"
          elif [[ $FILE =~ (.*\.mp4) ]]; then
               OUTPUT=$(exiftool -T -FileModifyDate $PATH_FILE)
               echo "  exiftool: FileModifyDate: $OUTPUT"
          else
               echo "List date/time: unknown file type: ${FILE}!"
          fi
     else
          echo "Warning, no valid Signal file pattern: ${FILE}"
     fi

done
sync
echo "Done, $FILES_PROCESSED files processed."
