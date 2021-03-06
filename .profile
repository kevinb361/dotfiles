# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# set PATH to include custom .scripts dir
if [ -d "$HOME/.scripts" ] ; then
	PATH="$HOME/.scripts:$PATH"
fi

# Start X Automatically
if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
        . startx
        logout
fi

# Set default audio sink
#pactl set-default-sink 2

# Set sound to 50% ## Default card set in /etc/asound.conf after listing cards
# with cat /etc/proc/asound/cards
amixer set Master 45% unmute
