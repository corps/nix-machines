source $stdenv/setup
PATH=$dpkg/bin:$PATH

dpkg -x $src unpacked

mkdir -p $out/local
mkdir -p $out/bin

cd unpacked/usr/local/pulse/
tar -xzvf pulse.tgz
cp -r . $out/local/pulse


bin=$out/local/pulse/PulseClient_x86_64.sh 

patchShebangs $bin
escaped_out=$(printf '%s\n' "$out" | sed -e 's/[\/&]/\\&/g')
sed -i "s/\/usr\/local/$escaped_out\/local/g" $bin

export LD_LIBRARY_PATH=$out/local/pulse:$LD_LIBRARY_PATH
rm $out/local/pulse/pulseUi*
rm $out/local/pulse/libpulseui*
autoPatchelf $out/local/pulse

echo "#!/usr/bin/env bash
export LD_LIBRARY_PATH=${out}/local/pulse:\$LD_LIBRARY_PATH
export PATH=${out}/bin:\$PATH
exec ${bin} \$@
" >$out/bin/PulseClient

# Lul k
echo "#!/usr/bin/env bash
echo 'Ubuntu 18.XX'
" >$out/bin/lsb_release

# Lul k
echo "#!/usr/bin/env bash
echo apt-get-dummy got \$@
" >$out/bin/apt-get

# Lul k
echo "#!/usr/bin/env bash
shift
exec \$@
" >$out/bin/su

# Lul k
echo "#!/usr/bin/env bash
if [ "$1" = "-v" ]; then
  echo sudo \$@
else
  exec \$@
fi
" >$out/bin/sudo

chmod +x $out/bin/*
