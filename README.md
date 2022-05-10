# tcpdump-fetch

The tcpdump-fetch script will start two daemonsets.  The first will capture all traffic on every node in an openhift cluster.  The second is used to assist in copying the pcaps from each node back to the directory where the script was executed.

## Current limitations:

- kubeconfig must be in /tmp/kubeconfig


