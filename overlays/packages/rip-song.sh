#! @bash@/bin/bash

PATH=@yt@/bin:@db@/bin:$PATH
#! nix-shell -i bash -p youtube-dl dropbox_uploader

set -euo pipefail
IFS=$'\n\t'

echo "Enter a url"
read -r url
echo "Enter song title"
read -r title
echo "Enter Band Name"
read -r band

url=`echo "${url}" | sed -E "s/\&(list|index)\=[^\&]*//g"`
echo "Url ${url} band ${band} title ${title}"

tmpfile="/tmp/${title}"
youtube-dl -x "${url}" -o "${tmpfile}.%(ext)s"
tmpfile=`ls ${tmpfile}*`
dropbox_uploader upload "${tmpfile}" "/Music/${band} - Unknown Album/"
rm $tmpfile