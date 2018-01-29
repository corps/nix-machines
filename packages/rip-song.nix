{ youtube-dl, dropbox_uploader, bash, substituteAll, icu }:

substituteAll {
  src = ./rip-song.sh;
  name = "rip-song";
  isExecutable = true;
  dir = "bin";
  yt = youtube-dl;
  db = dropbox_uploader;
  inherit bash icu;
}
