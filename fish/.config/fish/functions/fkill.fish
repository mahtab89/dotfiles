function fkill
    set process (ps -eo pid,comm --sort=comm | fzf \
        --height=60% \
        --layout=reverse \
        --border \
        --prompt="Kill > ")

    if test -n "$process"
        set pid (string split -m1 ' ' (string trim "$process"))[1]
        kill "$pid"
    end
end

# Fuzzy find file → open in Neovim
