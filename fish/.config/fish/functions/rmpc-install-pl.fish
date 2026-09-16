function rmpc-install-pl
    if test (count $argv) -eq 0
        echo "Usage: rmpc-install-pl <youtube-playlist-url>"
        return 1
    end

    set music_dir "$HOME/Music"
    set playlist_dir "$HOME/.config/mpd/playlists"
    set temp_dir (mktemp -d)

    mkdir -p "$playlist_dir"

    echo ""
    echo "Playlist destination"
    echo ""

    set playlists (find "$playlist_dir" -maxdepth 1 -type f -name "*.m3u" -printf "%f\n" 2>/dev/null | sed 's/\.m3u$//' | sort)

    set playlist (rmpc-select-or-create "Playlist (Esc = skip):" $playlists)

    if test -n "$playlist"
        set playlist_file "$playlist_dir/$playlist.m3u"
        touch "$playlist_file"

        echo ""
        echo "Playlist: $playlist"
    else
        set playlist_file ""

        echo ""
        echo "Playlist: None"
    end

    echo ""
    echo "Mood playlist: $playlist"
    echo ""
    echo "Reading YouTube playlist..."
    echo ""

    set entries (yt-dlp \
    --flat-playlist \
    --print "%(id)s|||%(title)s" \
    --ignore-errors \
    "$argv[1]")

    if test $status -ne 0; or test (count $entries) -eq 0
        echo "✗ Could not read playlist"
        rm -rf "$temp_dir"
        return 1
    end

    set total (count $entries)
    set current 0
    set installed 0
    set skipped 0

    # Remember previous selections
    set last_artist ""
    set last_album ""

    echo "Found $total songs"
    echo ""

    for entry in $entries
        set current (math $current + 1)

        set parts (string split "|||" "$entry")
        set video_id "$parts[1]"
        set title "$parts[2]"
        set url "https://www.youtube.com/watch?v=$video_id"

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "[$current/$total]"
        echo "$title"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        echo "  1) Install"
        echo "  2) Skip"
        echo ""

        read -P "Choice: " action

        if test "$action" = 2
            echo "→ Skipped"
            set skipped (math $skipped + 1)
            continue
        end

        # ─────────────────────────────────────
        # ARTIST SELECTION
        # ─────────────────────────────────────

        set artists (find "$music_dir" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -printf "%f\n" 2>/dev/null | sort)

        set same_artist 0

        if test -n "$last_artist"
            echo ""
            echo "Last artist: $last_artist"
            read -P "Press Enter to reuse, or type 'search': " reuse_artist

            if test -z "$reuse_artist"
                set artist "$last_artist"
                set same_artist 1
            else
                set artist (rmpc-select-or-create "Artist:" $artists)
            end
        else
            set artist (rmpc-select-or-create "Artist:" $artists)
        end

        if test -z "$artist"
            echo "→ Skipped"
            set skipped (math $skipped + 1)
            continue
        end

        # Remember artist AFTER determining whether it was reused
        set last_artist "$artist"

        # ─────────────────────────────────────
        # ALBUM SELECTION
        # ─────────────────────────────────────

        set artist_dir "$music_dir/$artist"
        set albums

        if test -d "$artist_dir"
            set albums (find "$artist_dir" \
                -mindepth 1 \
                -maxdepth 1 \
                -type d \
                -printf "%f\n" 2>/dev/null | sort)
        end

        # Singles is always available
        if not contains Singles $albums
            set albums Singles $albums
        end

        echo ""

        if test $same_artist -eq 1; and test -n "$last_album"
            echo "Last album: $last_album"
            read -P "Press Enter to reuse, or type 'search': " reuse_album

            if test -z "$reuse_album"
                set album "$last_album"
            else
                set album (rmpc-select-or-create "Album:" $albums)
            end
        else
            set album (rmpc-select-or-create "Album:" $albums)
        end

        if test -z "$album"
            echo "→ Skipped"
            set skipped (math $skipped + 1)
            continue
        end

        set last_album "$album"

        echo ""
        echo "Artist: $artist"
        echo "Album:  $album"
        echo ""

        # ─────────────────────────────────────
        # DOWNLOAD
        # ─────────────────────────────────────

        echo "Downloading..."

        yt-dlp \
            --no-playlist \
            -x \
            --audio-format opus \
            --embed-thumbnail \
            --embed-metadata \
            -o "$temp_dir/%(id)s.%(ext)s" \
            "$url"

        if test $status -ne 0
            echo "✗ Download failed — skipping"
            set skipped (math $skipped + 1)
            continue
        end

        set file "$temp_dir/$video_id.opus"

        if not test -f "$file"
            set file (find "$temp_dir" -type f -name "*.opus" | head -1)
        end

        if test -z "$file"; or not test -f "$file"
            echo "✗ Audio file not found — skipping"
            set skipped (math $skipped + 1)
            continue
        end

        # ─────────────────────────────────────
        # WRITE OUR METADATA
        # ─────────────────────────────────────

        python -c '
from mutagen.oggopus import OggOpus
import sys

path, title, artist, album = sys.argv[1:]

audio = OggOpus(path)

audio["title"] = [title]
audio["artist"] = [artist]
audio["album"] = [album]
audio["albumartist"] = [artist]

audio.save()
' "$file" "$title" "$artist" "$album"

        if test $status -ne 0
            echo "✗ Metadata failed — skipping"
            rm -f "$file"
            set skipped (math $skipped + 1)
            continue
        end

        # ─────────────────────────────────────
        # CLEAN FILESYSTEM NAMES
        # ─────────────────────────────────────

        set safe_artist (string replace -a "/" "-" "$artist")
        set safe_artist (string replace -a ":" "-" "$safe_artist")

        set safe_album (string replace -a "/" "-" "$album")
        set safe_album (string replace -a ":" "-" "$safe_album")

        set safe_title (string replace -a "/" "-" "$title")
        set safe_title (string replace -a ":" "-" "$safe_title")

        set album_dir "$music_dir/$safe_artist/$safe_album"
        set destination "$album_dir/$safe_title.opus"

        mkdir -p "$album_dir"

        # ─────────────────────────────────────
        # EXISTING FILE CHECK
        # ─────────────────────────────────────

        if test -e "$destination"
            echo ""
            echo "⚠ Already exists:"
            echo "  $destination"

            rm -f "$file"

            # Still add existing song to playlist
            if test -n "$playlist_file"
                set relative (string replace "$music_dir/" "" "$destination")

                if not grep -Fxq "$relative" "$playlist_file" 2>/dev/null
                    echo "$relative" >>"$playlist_file"
                    echo "✓ Added existing song to $playlist"
                end
            end

            continue
        end

        # ─────────────────────────────────────
        # MOVE INTO LIBRARY
        # ─────────────────────────────────────

        mv "$file" "$destination"

        # ─────────────────────────────────────
        # ADD TO MOOD PLAYLIST
        # ─────────────────────────────────────

        if test -n "$playlist_file"
            set relative (string replace "$music_dir/" "" "$destination")

            if not grep -Fxq "$relative" "$playlist_file" 2>/dev/null
                echo "$relative" >>"$playlist_file"
            end
        end

        echo ""
        echo "✓ Installed"
        echo "  $artist / $album / $title"

        set installed (math $installed + 1)
    end

    # ─────────────────────────────────────────
    # CLEANUP
    # ─────────────────────────────────────────

    rm -rf "$temp_dir"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Playlist complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Installed: $installed"
    echo "Skipped:   $skipped"
    if test -n "$playlist"
        echo "Playlist:  $playlist"
    else
        echo "Playlist:  None"
    end
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""
    echo "Updating MPD..."
    mpc update

    echo ""
    echo "✓ Done"
end
