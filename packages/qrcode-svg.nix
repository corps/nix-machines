{ fetchFromGitHub, nodejs, writeText, substituteAll }:

substituteAll {
  src = writeText "qrcode-svg" ''
    #! @nodejs@/bin/node
    require("@code@/app.js");
  '';

  inherit nodejs;

  name = "qrcode-svg";
  isExecutable = true;
  dir = "bin";

  code = fetchFromGitHub {
    owner = "papnkukn";
    repo = "qrcode-svg";
    rev = "e48892136b1655fa557d45b521120f482afafd3d";
    sha256 = "0hcya3mrkv1hv00pjjqi1gnyfry0wdysy93zmnh9cmfslzwvh3r0";
  }; 
}

