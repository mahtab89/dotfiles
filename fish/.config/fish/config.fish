if status is-interactive
    # Commands to run in interactive sessions can go here

  bind \cl '\''printf "\e[H\e[3J"'\''
  set -g fish_greeting
  set -gx PATH /home/mahtab/flutter-sdk/bin $PATH
  starship init fish | source
end
bind \cl 'printf "\e[H\e[3J"'
