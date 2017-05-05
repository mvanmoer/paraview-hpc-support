Miscellaneous ParaView support files for HPC systems at NCSA.

Blue Waters users should use the "Fetch Servers" option within the ParaView client rather than download these directly.

bw.pvsc is the client-side configuration file for establishing a remote server connection to a pvserver running on Blue Waters.

jyc-private.pvsc is the same, but for the limited-access JYC test system.

The .pvsc's tell the client to launch an xterm window, which in turn executes an ssh command. The xterm window will show the prompt for entering the Blue Waters passcode and PIN to establish the ssh connection. ssh will also execute the create_pvserver_job.sh script on the head node, which will in turn submit aprun_pvserver.qsub to start the job. These scripts also configure the network tunneling to make sure that ParaView traffic will reach a client which is behind a firewall.
