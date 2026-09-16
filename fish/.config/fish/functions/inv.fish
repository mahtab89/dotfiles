function inv
    set files (fzf -m \
        --preview 'bat --color=always -- {}' \
        --preview-window=right:60%)

    if test (count $files) -gt 0
        nvim $files
    end
end

# Fuzzy find file → copy contents
