function rmpc-install
    if test (count $argv) -eq 0
        echo "Usage: rmpc-install <youtube-url>"
        return 1
    end

    set music_dir "$HOME/Music"
    set temp_dir (mktemp -d)

    echo ""
    echo "Fetching song information..."
    echo ""

    set title (yt-dlp \
        --no-playlist \
        --print "%(title)s" \
        --skip-download \
        "$argv[1]" | head -1)

    if test -z "$title"
        echo "✗ Could not get song information"
        rm -rf "$temp_dir"
        return 1
    end

    echo "Title: $title"
    echo ""

    # Get existing artists from directories
    set artists (find "$music_dir" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort)

    set artist (rmpc-select-or-create "Artist:" $artists)

    if test -z "$artist"
        echo "✗ Artist selection cancelled"
        rm -rf "$temp_dir"
        return 1
    end

    echo ""
    echo "Artist: $artist"

    # Get albums belonging to this artist
    set artist_dir "$music_dir/$artist"
    set albums

    if test -d "$artist_dir"
        set albums (find "$artist_dir" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort)
    end

    # Always offer Singles
    if not contains "Singles" $albums
        set albums Singles $albums
    end

    echo ""

    set album (rmpc-select-or-create "Album:" $albums)

    if test -z "$album"
        echo "✗ Album selection cancelled"
        rm -rf "$temp_dir"
        return 1
    end

    echo ""
    echo "Artist: $artist"
    echo "Album:  $album"
    echo ""

    echo "Downloading..."

    yt-dlp \
        --no-playlist \
        -x \
        --audio-format opus \
        --embed-thumbnail \
        --embed-metadata \
        -o "$temp_dir/%(id)s.%(ext)s" \
        "$argv[1]"

    if test $status -ne 0
        echo "✗ Download failed"
        rm -rf "$temp_dir"
        return 1
    end

    set file (find "$temp_dir" -type f -name "*.opus" | head -1)

    if test -z "$file"
        echo "✗ Audio file not found"
        rm -rf "$temp_dir"
        return 1
    end

    # Replace YouTube metadata with our library metadata
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
        echo "✗ Failed to write metadata"
        rm -rf "$temp_dir"
        return 1
    end

    # Clean filesystem names
    set safe_artist (string replace -a "/" "-" "$artist")
    set safe_artist (string replace -a ":" "-" "$safe_artist")

    set safe_album (string replace -a "/" "-" "$album")
    set safe_album (string replace -a ":" "-" "$safe_album")

    set safe_title (string replace -a "/" "-" "$title")
    set safe_title (string replace -a ":" "-" "$safe_title")

    set artist_dir "$music_dir/$safe_artist"
    set album_dir "$artist_dir/$safe_album"
    set destination "$album_dir/$safe_title.opus"

    mkdir -p "$album_dir"

    if test -e "$destination"
        echo ""
        echo "⚠ Song already exists:"
        echo "  $destination"
        rm -rf "$temp_dir"
        return 1
    end

    mv "$file" "$destination"
    rm -rf "$temp_dir"

    echo ""
    echo "✓ Installed"
    echo "  Artist: $artist"
    echo "  Album:  $album"
    echo "  Title:  $title"
    echo "  File:   $destination"

    # Playlist selection
    echo ""
    echo "Add to playlists? (Esc = none)"

    set playlist_dir "$HOME/.config/mpd/playlists"
    mkdir -p "$playlist_dir"

    set playlists (find "$playlist_dir" -maxdepth 1 -type f -name "*.m3u" -printf "%f\n" 2>/dev/null | sed 's/\.m3u$//' | sort)

    if test (count $playlists) -gt 0
        set selected (printf '%s\n' $playlists | fzf \
            --height=50% \
            --layout=reverse \
            --border \
            --multi \
            --prompt="Playlists: " \
            --header="Tab = select multiple • Enter = confirm")

        for selected_playlist in $selected
            set playlist_file "$playlist_dir/$selected_playlist.m3u"
            set relative (string replace "$music_dir/" "" "$destination")

            touch "$playlist_file"

            if not grep -Fxq "$relative" "$playlist_file" 2>/dev/null
                echo "$relative" >> "$playlist_file"
                echo "  ✓ Added to $selected_playlist"
            end
        end
    end

    echo ""
    echo "Updating MPD..."
    mpc update

    echo "✓ Done"
end
