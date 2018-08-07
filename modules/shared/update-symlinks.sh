scratch=$(mktemp -d -t tmp.XXXXXXXXXX)
update_symlink() {
    local SRC
    local DEST
    local OUTDIR

    SRC="$1"
    DEST="$2"
    OUTDIR=$(dirname "$DEST");
    if [ ! -d "$OUTDIR" ]; then
        echo "Creating $OUTDIR"
        mkdir -p "$OUTDIR"
    fi

    if [ ! -h "$DEST" ] && [ -d "$DEST" ]; then
        echo "Failed updating symlink for $DEST: is directory"
        return 1
    fi

    if [ -f "$DEST" ]; then
        local CURSRC

        if [ ! -h "$DEST" ]; then
          return 0
        fi

        CURSRC=$(realpath "$DEST")
        if [ "x$CURSRC" == "x$SRC" ]; then
            return 0
        fi
    fi

    if [ -d "$DEST" ]; then
        rm "$DEST"
    fi

    ln -s "$SRC" "$scratch/tmp"
    echo "Updating link $DEST = $SRC"
    mv "$scratch/tmp" "$DEST"
  }
