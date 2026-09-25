# Runs inside GIMP (tests/run.sh): applies the plug-in to the test image
# non-interactively and exports the result.
import os

import gi
gi.require_version('Gimp', '3.0')
from gi.repository import Gimp, Gio

out = os.environ['WT_OUT']
image = Gimp.file_load(Gimp.RunMode.NONINTERACTIVE, Gio.File.new_for_path(os.path.join(out, 'test.png')))
proc = Gimp.get_pdb().lookup_procedure(os.environ['WT_PROC'])
config = proc.create_config()
config.set_property('run-mode', Gimp.RunMode.NONINTERACTIVE)
config.set_property('image', image)
config.set_core_object_array('drawables', image.get_layers())
for arg in os.environ['WT_ARGS'].split():
    name, value = arg.split('=')
    config.set_property(name, type(config.get_property(name))(value) if not isinstance(config.get_property(name), bool) else value == 'true')
result = proc.run(config)
print('status', result.index(0))
Gimp.file_save(Gimp.RunMode.NONINTERACTIVE, image, Gio.File.new_for_path(os.path.join(out, 'result.png')), None)
