#!/bin/sh
# Builds the plug-in into tests/output and runs it inside the Flatpak GIMP
# without a window, with a gimprc that adds that folder to the plug-in path
# (the installed plug-ins are not touched), then checks that it removes
# noise and keeps edges. Needs gimp-plugin-devtools next to this repo.
# Close GIMP first.
set -e
here=$(cd "$(dirname "$0")" && pwd)
top=$(dirname "$here")
out="$here/output"
build="$top/../gimp-plugin-devtools/gimp-build.sh"
rm -rf "$out"; mkdir -p "$out"
"$build" "$top" meson setup "$out/build" -Dplugindir="$out/plug-ins" > "$out/build.log"
"$build" "$top" ninja -C "$out/build" install >> "$out/build.log"
python3 "$here/make-image.py" "$out/test.png"
printf '(plug-in-path "${gimp_dir}/plug-ins:${gimp_plug_in_dir}/plug-ins:%s")\n' "$out/plug-ins" > "$out/gimprc"
flatpak run --filesystem="$here" --env=WT_OUT="$out" --env=WT_PROC=plug-in-wavelet-denoise \
  --env=WT_ARGS="threshold-1=2 threshold-2=2 threshold-3=2" \
  --command=gimp-console-3.2 org.gimp.GIMP --no-interface --no-data --gimprc="$out/gimprc" \
  --batch-interpreter python-fu-eval -b "exec(open('$here/apply.py').read())" --quit 2>&1 | grep -E "^status|Error|Traceback"
python3 - "$out" <<'PY'
import sys
import numpy as np
from PIL import Image
out = sys.argv[1]
L = lambda n: np.asarray(Image.open(out + '/' + n).convert('L')).astype(float) / 255
src, res = L('test.png'), L('result.png')
fails = 0
def check(ok, msg):
    global fails
    print(('ok   ' if ok else 'FAIL ') + msg)
    fails += not ok
n0, n1 = src[:, 20:130].std(), res[:, 20:130].std()
check(n1 < 0.6 * n0, 'noise %.4f -> %.4f' % (n0, n1))
e0, e1 = src[:, 205].mean() - src[:, 195].mean(), res[:, 205].mean() - res[:, 195].mean()
check(e1 > 0.9 * e0, 'edge contrast %.3f -> %.3f' % (e0, e1))
print('%d failed' % fails)
sys.exit(fails > 0)
PY
