#!/bin/bash

# Name: clitter v0.2
# Author: Night <nightcooki3[at]gmail[dot]com>
# License: GPL v2+
# Description: A bash script for Twitter that utilizes cURL
# Dependencies: cURL

# To-do:
# gui & cli version

# History of cli-twitter
# v0.2 (not complete yet)
# * Added wget support for people that don't
#   have cURL on their system
# * Added a nicer log output so it's easier
#   to see if your tweet suceeded or not
# * Added dialogs, removed old stuff
#
# v0.1 (15/09/09)
#
# * Basic cURL check
# * Simple status update via Twitter API

# Functions
post_curl() {
# Put user info in cURL, POST HTTP request 
# and log it for the current session
## Change curl to read new LOGIN

curl --basic --user $LOGIN --data status="$tweet" http://twitter.com/statuses/update.xml > $LOGFILE 2>&1
}

post_wget() {
# Put user info in wget, POST HTTP request 
# and log it for the current session

## Mangle LOGIN for wget
wget_user="$(echo $LOGIN |sed '{s|:| |}'|awk '{print $1}')"
wget_pass="$(echo $LOGIN |sed '{s|:| |}'|awk '{print $2}')"


# Use wget to post
wget --keep-session-cookies --http-user=$wget_user --http-password=$wget_pass --post-data=”status=$tweet” http://twitter.com:80/statuses/update.xml >> $LOGFILE
}


format_log() {


cat <<EOF > "$LOGFILE".tmp
Reply from twitter:
----------------------------------------------

User info:
         Name: $(cat $LOGFILE |grep "<name>" |sed '{s|<name>|| ; s|</name>||; s/^ *//;s/ *$//}')
  Screen Name: $(cat $LOGFILE |grep "<screen_name>" |sed '{s|<screen_name>|| ; s|</screen_name>||; s/^ *//;s/ *$//}')


        Tweet: $(cat $LOGFILE |grep "<text>" |sed '{s|<text>|| ; s|</text>||; s/^ *//;s/ *$//}')

    Followers: $(cat $LOGFILE |grep "<followers_count>" |sed '{s|<followers_count>|| ; s|</followers_count>||; s/^ *//;s/ *$//}')
EOF

mv "$LOGFILE".tmp "$LOGFILE"
}

goodbye() {
clear

# Reformat the log file for viewing
format_log

# Grab the log and display it in dialog
dialog --title "Status log" --textbox $LOGFILE 22 70 2>&1 >/dev/tty

# Remove the temp log
rm $LOGFILE
clear

# Print the goodbye screen
printf "\nThanks for using the script, if you didn't mistype your username and/or password you successfully twitted your message ('"; tput setaf 2; printf "$tweet"; tput sgr0; printf "').\n\nBye bye! ;)\n"
sleep 1

}

# Script startup
printf "Welcome to clitter, a bash script utilizing cURL to communicate with Twitter\n\n"
sleep 1
printf "Please wait while the script checks for dependencies...\n\n"
sleep 1
# Check for cURL
printf "Checking for curl...\n\n"
if [ -f "$(which curl )" ]; then
  POST_METHOD=curl
else
  printf "Curl not found! Checking for wget...\n\n"
  if [ -f "$(which wget )" ]; then
    POST_METHOD=wget
  else
    printf "Curl or wget not found! Aborting...\n\n"
    exit 1
  fi 
fi

printf "Will use post method: "$POST_METHOD"\n\n"


# Define Log file with mktemp
LOGFILE=$(mktemp)

# Let check for account file
ACNT_FILE=~/.clitter/account
[ -f "$ACNT_FILE" ] && . "$ACNT_FILE"

# Check to see if LOGIN is set
if [ -z "$LOGIN" ]; then
  # Login info empty - Lets ask for it
  # Create dialogs and gather user info
  user=$(dialog --inputbox "Username / e-mail" 8 40 2>&1 >/dev/tty) || exit
  pass=$(dialog --passwordbox "Password" 8 40 2>&1 >/dev/tty) || exit

  # Ask to save it (dialog needs errorlevel to do this)
  dialog --yesno "Save account info?" 8 40 2>&1 >/dev/tty  
  answer=$?
  if [ "$answer" = "0" ]; then
    # 0 for Yes
    # Store username & password
    mkdir -p ~/.clitter
    echo "LOGIN=$user:$pass" > "$ACNT_FILE"
    chmod 700 "$ACNT_FILE"
    . "$ACNT_FILE"
  else
    # 1 for no
    # Dont store - just make a string
    LOGIN="$user:$pass"
  fi
fi

# Ask for tweet
tweet=$(dialog --inputbox "Tweet (max 140 characters, everything over 140 characters will be cropped to fit the max size allowed)" 8 80 2>&1 >/dev/tty) || exit


if [ "$POST_METHOD" = "curl" ]; then
  post_curl 
else
  post_wget
fi


# Say goodbye
goodbye
exit 0

