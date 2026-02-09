#!/data/data/com.termux/files/usr/bin/bash
# Not used: we start the server from ~/.bashrc instead.
# See README: add this line to ~/.bashrc (one command does it):
#   [ -f "$HOME/termux_git_server.py" ] && nohup python3 "$HOME/termux_git_server.py" >> "$HOME/autogit_git_server.log" 2>&1 &

if [ -f "$HOME/termux_git_server.py" ]; then
  nohup python3 "$HOME/termux_git_server.py" >> "$HOME/autogit_git_server.log" 2>&1 &
fi
