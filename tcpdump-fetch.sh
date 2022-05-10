#!/bin/bash

CAPTURE=1;

oc --kubeconfig /tmp/kubeconfig apply -f ./manifests/tcpdump-capture-daemonset-ovn.yaml
oc --kubeconfig /tmp/kubeconfig apply -f ./manifests/tcpdump-retrieve-daemonset-ovn.yaml

# Keepalive is to avoid stale/timout issues with `oc debug/exec` requests
keepalive() {
    while [ "$CAPTURE" -eq 1 ]; do
        sleep 1
        echo -n .
    done
    echo "Finished"
}

term() {
    echo "Completed TCPDump"
    pkill -P $$
    
    CAPTURE=0;

    #
    oc --kubeconfig /tmp/kubeconfig delete -f ./manifests/tcpdump-capture-daemonset-ovn.yaml

    WAITING=1;
    while [ "$WAITING" -eq 1 ];
    do
	podList=$(oc --kubeconfig /tmp/kubeconfig --namespace openshift-ovn-kubernetes get pods -l app=tcpdump-capture -o jsonpath='{range@.items[*]}{.metadata.name}{"\n"}{end}');
	#echo "podList is " ${podList};

	if [[ -z $podList || $podList = "" ]]
	then
	    WAITING=0;
	    echo "tarballs created";
	else
	    echo "waiting for " ${podList} "to finish...";
	fi 
	
	sleep 1; 
    done

    # Collect PCAPs
    echo "Collecting PCAPs"

    for pod in $(oc --kubeconfig /tmp/kubeconfig --namespace openshift-ovn-kubernetes get pods -l app=tcpdump-retrieve -o jsonpath='{range@.items[*]}{.metadata.name}{"\n"}{end}');
    do 
	echo $pod;
	nodeName=$(oc --kubeconfig /tmp/kubeconfig -n openshift-ovn-kubernetes get pod $pod -o=custom-columns=NODE:.spec.nodeName)
	nodeName=$(echo $nodeName|tr -d '\n');
	prefix="NODE ";
	nodeName=${nodeName#$prefix};
	echo $nodeName; 
	oc --kubeconfig /tmp/kubeconfig --namespace openshift-ovn-kubernetes cp $pod:tmp/tcpdump_$nodeName.tgz tcpdump_$nodeName.tgz
    done

    oc --kubeconfig /tmp/kubeconfig delete -f ./manifests/tcpdump-retrieve-daemonset-ovn.yaml
}
trap term SIGTERM SIGINT

echo "----------------------------------------------------------"
echo "Starting the pcaps. These will run until failure of killed. Kill with Crtl + C to copy back the contents"
echo "----------------------------------------------------------"

keepalive;

