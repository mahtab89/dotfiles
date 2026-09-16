function mount-cachyos
    if mountpoint -q /mnt/cachyos
        echo "CachyOS is already mounted."
        return 0
    end

    if not test -d /mnt/cachyos
        sudo mkdir -p /mnt/cachyos
    end

    sudo mount -o rw,subvol=@home UUID=34b21b05-885f-41dc-9a14-456f3f5339e0 /mnt/cachyos
end
