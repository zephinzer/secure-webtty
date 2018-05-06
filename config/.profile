#!/bin/sh
alias ll='ls -al';
get_time() {
  printf "$(date +'%Y-%m-%d %I:%M:%S %p')";
}
PS1=$'$(get_time) $(pwd) \$ ';
