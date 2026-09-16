function fzfi
    fzf \
        --preview='kitty +kitten icat --clear --transfer-mode=memory --stdin=no --place="$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES"@0x0 {}' \
        --preview-window='right:50%'
end
