To launch simulations with the ARGOS simulator (once it is installed, cf. instructions in first Robotics exercise session),
if you ecounter Segmentation faults when launching sandbox.argos, you can fix it with:

```bash
$LIBGL_ALWAYS_SOFTWARE=1 QT_OPENGL=software argos3 -c sandbox.argos
```

Have fun!