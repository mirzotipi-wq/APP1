# W05 R08 candidate wording

## invalidLight

Use a nonblank light name of at most 80 characters. Check its position and emitter settings, output (0–100,000 cd), and color temperature (1,000–20,000 K), then try again.

## unsupportedGeometry

The model could not calculate this light's contribution. Check the scene settings and all lights. For a positive target in lux, separate the camera from the subject and try moving or re-aiming the light toward the camera-facing subject plane.

## outputOutOfRange

The requested lux could not be achieved within the model's 0–100,000 cd range and numerical accuracy. Try a different positive target or adjust the light's position or aim; enter 0 lux to turn this light off.

Geometry advice is conditional on positive targets because scene validation also fails before the zero-target branch. No universal 0.05 m remedy is promised: rectangular emitters require perpendicular depth of at least max(0.05 m, longest side / 4). A different positive target covers both upper-limit and tiny-target failures without prescribing a direction. These messages remain static and describe the model, not measured lamp output or total-rig illuminance.
