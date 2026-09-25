#!/usr/bin/env python3
# Test image for tests/run.sh: gray with a soft vertical step in the
# middle, and Gaussian noise (sigma 0.05) on the left half only.
import sys

import numpy as np
from PIL import Image

h, w = 200, 400
x = np.arange(w)
row = 0.3 + 0.4 / (1 + np.exp(-(x - 200) / 1.5))
img = np.repeat(row[None, :], h, 0)
rng = np.random.default_rng(3)
img[:, :150] += rng.normal(0, 0.05, (h, 150))
img = np.clip(img, 0, 1)
Image.fromarray((np.dstack([img] * 3) * 255 + 0.5).astype(np.uint8)).save(sys.argv[1])
