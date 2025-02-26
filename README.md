Miscellaneous ParaView support files for HPC systems at NCSA.

See the Delta User Guide entry on ParaView for full details:

https://docs.ncsa.illinois.edu/systems/delta/en/latest/user_guide/visualization.html#paraview

Delta users should first try the "Fetch Servers" option within the ParaView client. If that doesn't work, next try downloading a pvsc to your local machine and using "Load Servers" instead.

ncsa-delta-cpu.pvsc is the client-side configuration for launching a job on Delta's cpu partition. Generally speaking, you probably only want to request one node unless your data is decomposed into multiple spatial domains, each in a separate file. If that is the case, then try requesting a node per file.

ncsa-delta-gpu.pvsc is the client-side configuration for launching a job on Delta's gpuA40x4 partition. Generally speaking, you probably only want one GPU per node, you are unlikely to see benefit from trying to use multiple GPUs per node.

The BASH scripts are what get executed to submit a SLURM job once ParaView connects to Delta. These are shown for only for completeness, users don't need to do anything with them. They are in /sw/external/kitware on Delta.

The archive directory contains examples from decommisioned systems.
