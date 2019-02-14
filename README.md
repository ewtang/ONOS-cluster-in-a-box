# ONOS-cluster-in-a-box
Docker containers which work with ONOS Scenario Test Coordinator (STC)

Before building docker image:
1. Put these files inside a directory.
2. Copy $ONOS_ROOT/bazel-bin/onos.tar.gz here, assuming you have successfully built one.
3. Copy your public key ~/.ssh/id_rsa.pub here.


Build docker image as follows. You may tag your image as you like.
```
$ sudo docker build -t onos-sshd .
```

Run 3 docker containers:
```
$ sudo docker run -t -d --name onos1 onos-sshd
$ sudo docker run -t -d --name onos2 onos-sshd
$ sudo docker run -t -d --name onos3 onos-sshd
```

Check ip of docker containers:
```
$ sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' onos1
```

Create cell definition file e.g. $ONOS_ROOT/tools/test/cells/3docker. Make sure ip's match your settings.
```
export ONOS_NIC="172.17.0.*"
export OCI="172.17.0.2"
export OC1="172.17.0.2"
export OC2="172.17.0.3"
export OC3="172.17.0.4"
export ONOS_APPS="drivers,openflow"
export ONOS_USER="sdn"
```

Set up cell definition:
```
$ cell 3docker
```

Execute STC setup: 
```
$ stc setup
```

Check status using ONOS CLI:
```
$ ssh -p 8101 karaf@$OC1    # password is karaf
```
