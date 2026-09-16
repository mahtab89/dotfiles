function rmpc-select
    set prompt $argv[1]
    set items $argv[2..-1]

    if test (count $items) -eq 0
        return 1
    end

    printf '%s\n' $items | fzf \
        --height=50% \
        --layout=reverse \
        --border \
        --prompt="$prompt " \
        --header="Type to search • Enter to select • Esc to cancel"
end

function rmpc-select-or-create
    set prompt $argv[1]
    set items $argv[2..-1]

    # No existing items
    if test (count $items) -eq 0
        read -P "$prompt " new_name

        if test -n "$new_name"
            echo "$new_name"
            return 0
        end

        return 1
    end

    set create_option "➕ Create new..."

    set choice (printf '%s\n' $create_option $items | env -u FZF_DEFAULT_OPTS -u FZF_DEFAULT_OPTS_FILE fzf \
        --no-phony \
        --height=50% \
        --layout=reverse \
        --border \
        --prompt="$prompt " \
        --header="Enter = select • Choose Create new to add one • Esc = cancel")

    if test $status -ne 0
        return 1
    end

    # User chose to create
    if test "$choice" = "$create_option"
        read -P "New name: " new_name

        if test -n "$new_name"
            echo "$new_name"
            return 0
        end

        return 1
    end

    # Existing item
    if test -n "$choice"
        echo "$choice"
        return 0
    end

    return 1
end
