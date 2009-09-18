#!/bin/bash

# Name: clitter v0.1
# Author: Night <nightcooki3[at]gmail[dot]com>
# License: GPL v2+
# Description: A bash script for Twitter that utilizes cURL
# Dependencies: cURL

# To-do:
# gui & cli version

# History of cli-twitter
# v0.2 (being worked on)
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

# Script startup
printf "Welcome to clitter, a bash script utilizing cURL to communicate with Twitter\n\n"
sleep 1
printf "Please wait while the script checks for dependencies...\n\n"
sleep 1

# Check for cURL
if [ -f "$(which curl )" ]; then

  # cURL found
  printf "cURL is present on your system, proceeding with the script...\n\n"
  sleep 1

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


  # Put user info in cURL, POST HTTP request 
  # and log it for the current session
  ## Change curl to read new LOGIN_STRING
  curl --basic --user $LOGIN --data status="$tweet" http://twitter.com/statuses/update.xml > log.tmp

  # Grab the log and display it in dialog
  log=$(dialog --title "Status log" --textbox log.tmp 22 70 2>&1 >/dev/tty) 

  # Remove the temp log
  rm log.tmp
  clear

  # Print the goodbye screen
  printf "\nThanks for using the script, if you didn't mistype your username and/or password you successfully twitted your message ('"; tput setaf 2; printf "$tweet"; tput sgr0; printf "').\n\nBye bye! ;)\n"
  sleep 1
  clear
else

  # Well if you have no cURL, let's do it with wget ;)
  # ** NEW / UNTESTED CODE **
  printf "No cURL found, trying with wget...\n\n"
  sleep 1
  printf "**NOTE** Not sure if script works fine with wget and it needs additional testing\n\n"
  sleep 1

  # Create dialogs and gather user info
  user=$(dialog --inputbox "Username / e-mail" 8 40 2>&1 >/dev/tty) || exit
  pass=$(dialog --passwordbox "Password" 8 40 2>&1 >/dev/tty) || exit
  tweet=$(dialog --inputbox "Tweet (max 140 characters, everything over 140 characters will be cropped to fit the max size allowed)" 8 80 2>&1 >/dev/tty) || exit

  # Use wget to post
  wget --keep-session-cookies --http-user=$user --http-password=$pass --post-data=â€status=$tweetâ€ http://twitter.com:80/statuses/update.xml >> log.tmp

  # Grab the log and display it in dialog
  log=$(dialog --title "Status log" --textbox log.tmp 22 70 2>&1 >/dev/tty) 

  # Remove the temp log
  rm log.tmp
  clear

  # Print the goodbye screen
  printf "\nThanks for using the script, if you didn't mistype your username and/or password you successfully twitted your message ('"; tput setaf 2; printf "$tweet"; tput sgr0; printf "').\n\nBye bye! ;)\n"
  sleep 1
  clear
fi
