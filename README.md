Miscellaneous ParaView support files for HPC systems at NCSA.

See the Blue Waters User Guide entry on ParaView for full details:

https://bluewaters.ncsa.illinois.edu/paraview1

Blue Waters users should first try the "Fetch Servers" option within the ParaView client. If that doesn't work, next try downloading a pvsc to your local machine and using "Load Servers" instead.

bw.pvsc is the client-side configuration file for establishing a remote server connection to a pvserver running on Blue Waters. Use for Linux or OS X.

bw-win.pvsc should be used from Windows machines. 

jyc-private.pvsc is the same, but for the limited-access JYC test system.

The .pvsc's tell the client to launch a terminal window, which in turn executes an ssh command. The terminal window will show the prompt for entering the Blue Waters passcode and PIN to establish the ssh connection. ssh will also execute the create_pvserver_job.sh script on the head node, which will in turn submit aprun_pvserver.qsub to start the job. These scripts also configure the network tunneling to make sure that ParaView traffic will reach a client which is behind a firewall.
