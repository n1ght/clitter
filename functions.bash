#!/bin/bash
#
# Name: functions.bash
# Description: Functions used by clitter
# Author: Night <nightcooki3[at]gmail[dot]com>
# Contributor(s): onemyndseye
# License: GPL v2+
# Dependencies: dialog, cURL
# Optional dependencies: zenity

###################### DEPS
dep_check () {

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

}

###################### SCRIPT CORE

###################### CLI DEFINES
core_cli () {

# Define Log file with mktemp
LOGFILE=$(mktemp)

# Let check for account file
ACNT_FILE=~/.clitter/account
[ -f "$ACNT_FILE" ] && . "$ACNT_FILE"

# Check to see if LOGIN is set
if [ -z "$LOGIN" ]; then

  # Login info empty - Lets ask for it
  # Create dialogs and gather user info

  # Grab user input
  user=$(dialog --inputbox "Username / e-mail" 8 40 2>&1 >/dev/tty) || exit
  pass=$(dialog --passwordbox "Password" 8 40 2>&1 >/dev/tty) || exit

  # Ask to save it (dialog needs errorlevel to do this)
  dialog --yesno "Save account info?" 8 40 2>&1 >/dev/tty  
  answer=$?

  # 0 fpr yes
  if [ "$answer" -eq 0 ]; then

    # Store username & password
    store

  # 1 for no
  else

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

}

###################### ZEN DEFINES
core_zen () {

# Define Log file with mktemp
LOGFILE=$(mktemp)

# Let check for account file
ACNT_FILE=~/.clitter/account
[ -f "$ACNT_FILE" ] && . "$ACNT_FILE"

# Check to see if LOGIN is set
if [ -z "$LOGIN" ]; then

  # Login info empty - Lets ask for it
  # Create dialogs and gather user info

  # Grab user input
  user=$(zenity --entry --title="Username / e-mail" --text="Your twitter username or e-mail goes in the field below") || exit
  pass=$(zenity --entry --hide-text --title="Password" --text="Your twitter password goes in the field below") || exit
  
  # Ask to save it (dialog needs errorlevel to do this)
  zenity --question --title="Save account info?" --text="If you answer yes, your username and password will be stored in a file and you will not be prompted to enter them again"  
  answer=$?

  # 0 fpr yes
  if [ "$answer" -eq 0 ]; then

    # Store username & password
    store

  # 1 for no
  else

    # Dont store - just make a string
    LOGIN="$user:$pass"
  fi
fi

# Ask for tweet
tweet=$(zenity --entry --title="Tweet" --text="Max 140 characters, everything over 140 characters will be cropped to fit the max size allowed") || exit


if [ "$POST_METHOD" = "curl" ]; then
  post_curl 
else
  post_wget
fi

}

###################### CURL
post_curl() {

# Put user info in cURL, POST HTTP request 
# and log it for the current session
## Change curl to read new LOGIN
curl --basic --user $LOGIN --data status="$tweet" http://twitter.com/statuses/update.xml > $LOGFILE 2>&1
}

###################### WGET
post_wget() {
# Put user info in wget, POST HTTP request 
# and log it for the current session

## Mangle LOGIN for wget
wget_user="$(echo $LOGIN |sed '{s|:| |}'|awk '{print $1}')"
wget_pass="$(echo $LOGIN |sed '{s|:| |}'|awk '{print $2}')"


# Use wget to post
wget --keep-session-cookies --http-user=$wget_user --http-password=$wget_pass --post-data=”status=$tweet” http://twitter.com:80/statuses/update.xml >> $LOGFILE
}

###################### LOG SETTINGS
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

###################### STORE LOGIN DATA
store () {

mkdir -p ~/.clitter
echo "LOGIN=$user:$pass" > "$ACNT_FILE"
chmod 700 "$ACNT_FILE"
. "$ACNT_FILE"

}

###################### END DIALOG
goodbye_cli() {
clear

# Reformat the log file for viewing
format_log

# Grab the log and display it in dialog
dialog --title "Status log" --textbox $LOGFILE 22 70 2>&1 >/dev/tty

# Remove the temp log
rm $LOGFILE
clear

# Print the goodbye screen
printf "\nThanks for using the script, if you didn't mistype your username and/or password you should've seen the dialog box with your tweeter account info. Report all bugs to nightcookie@gmail.com"
sleep 1

} 

###################### END ZENITY
goodbye_zen() {
clear

# Reformat the log file for viewing
format_log

# Grab the log and display it in dialog
cat $LOGFILE | zenity --title "Status log" --text-info

# Remove the temp log
rm $LOGFILE
clear

# Print the goodbye screen
zenity --title="Goodbye" --info --text="Thanks for using the script, if you didn't mistype your username and/or password you should've seen the dialog box with your tweeter account info. Report all bugs to nightcookie@gmail.com"
sleep 1

}