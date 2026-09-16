function fh
    set cmd (history | fzf \
        --height=60% \
        --layout=reverse \
        --border \
        --prompt="History > ")

    if test -n "$cmd"
        commandline -- "$cmd"
    end
end

# Fuzzy process killer
