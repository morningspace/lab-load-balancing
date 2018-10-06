# Lab: Load Balancing Using HAProxy and Keepalived

This is the lab project to demonstrate the use of HAProxy and Keepalived to set up highly available load balancing service.

Below is the instructions on how to play the lab. You can find the online slides [here](http://morningspace.github.io/lab-load-balancing/docs/slides).

## Instructions

### Build images

Go root directory of this project, and build docker images for both web server and load balancer:
```
docker build -f docker/Dockerfile.web -t morningspace/web .
docker build -f docker/Dockerfile.lb -t morningspace/lb .
```

### Launch web servers

Launch two docker containers for image morningspace/web to represent as two web server instances:
```
docker run -d --name myweb1 --hostname myweb1 --net=lab -p 18080:80 -p 18443:443 morningspace/web
docker run -d --name myweb2 --hostname myweb2 --net=lab -p 19080:80 -p 19443:443 morningspace/web
```

Note:

* Make sure the `lab` network has been created beforehand.

Run `docker ps` to make sure the two docker containers are launched successfully, and input below URLs in browser:
```
http://localhost:18080/healthz
http://localhost:19080/healthz
https://localhost:18443/healthz
https://localhost:19443/healthz
```
It should return a message such as "Greeting from <hostname>", where the `hostname` is specified by `--hostname` option when launch the docker container.

### Launch load balancers

Launch two docker containers for image morningspace/lb to represent as two load balancer instances:
```
docker run -it --name mylb1 --hostname mylb1 --net=lab -p 28080:8080 -p 28443:8443 -p 28090:8090 --sysctl net.ipv4.ip_nonlocal_bind=1 --privileged morningspace/lb
docker run -it --name mylb2 --hostname mylb2 --net=lab -p 29080:8080 -p 29443:8443 -p 29090:8090 --sysctl net.ipv4.ip_nonlocal_bind=1 --privileged morningspace/lb
```

Run `docker ps` to make sure the two docker containers are launched successfully.

### Configure and run haproxy

After launched, you should be in the container. Make sure haproxy has not been started:
```
service haproxy status
```
It should return something like: haproxy not running

Go to directory /etc/haproxy, there are multiple sample configuration files for haproxy. Copy either of them to be haproxy.cfg.
```
cp haproxy-ssl-termination.conf haproxy.cfg
```

Start haproxy as service:
```
service haproxy start
```

Check if haproxy is started successfully by monitoring its logs:
```
tail -f /var/log/haproxy.log
```

Input below URLs in browser to open the haproxy stats report views:
```
http://localhost:28090/haproxy/stats
http://localhost:29090/haproxy/stats
```
Input the predefined username and password when promted: haproxy/passw0rd

Repeat the same steps in another haproxy instance.

Note:

* If you forget which haproxy instance you are in, type `hostname` within container.
* If you exit the container for some reason, the container will be stopped as expected. To go back, e.g. mylb1:
```
docker start -i mylb1
```

### Configure and run keepalived 

Go to directory /etc/keepalived, there are two sample configuration files for keepalived. One for is master node, and the other one is for backup node.

Run ping command to get the ip addresses for all containers involved into the current network, then use a new ip address as the virtual ip address that will not conflict with all the other ones. e.g.:
node		| ip address
-------	| -------------
myweb1	| 172.18.0.2
myweb2	| 172.18.0.3
mylb1		| 172.18.0.4
mylb2		| 172.18.0.5
virtual	| 172.18.0.6
Here we use 172.18.0.6 as the virtual ip address. Replace `<your_virtual_ip>` with the selected value in both keepalived-master.conf and keepalived-backup.conf.

Note:
* The value of `interface` defined in sample configuration files is `eth0`. It could be different depending on your system. To figure out the right value, you can run `ip addr show`.

Choose one container as master, e.g. mylb1. Launch keepalived using master configuration:
```
keepalived --dump-conf --log-console --log-detail --log-facility 7 --vrrp -f /etc/keepalived/keepalived-master.conf
```

In onther container, e.g. mylb2 as backup. Launch keepalived using backup configuration:
```
keepalived --dump-conf --log-console --log-detail --log-facility 7 --vrrp -f /etc/keepalived/keepalived-backup.conf
```

Check if keepalived is started successfully by monitoring its logs:
```
tail -f /var/log/syslog
```

To verify if the virtual ip address is assigned successfully:
```
ip addr show eth0
```
If it's configured correctly, you will see the virtual ip address appeared in the output.

Run `curl` in either of the two load balancer containers. Send request to the virutal ip and see if it returns the content from web servers. e.g. for the case where ssl is not enabled:
```
curl -XGET http://<virtual_ip>:8080/healthz
```
And ssl is enabled:
```
curl --insecure --cert /etc/ssl/certs/my.crt --key /etc/ssl/private/my.key -XGET https://<virtual_ip>:8443/healthz
```

## Test


### Web server

Try to stop one of the web servers, e.g.:
```
docker stop myweb1
```

Wait for a moment then check the haproxy stats report view in browser, e.g. use the below URL:
```
http://localhost:28090/haproxy/stats
```
To see if myweb1 is down.

Hit the /healthz endpoint exposed by load balancer either in browser or using curl command, and make sure myweb1 will never be hitted.

Start myweb1 again:
```
docker start myweb1
```

Wait for a moment and check the haproxy stats report view in browser to see if myweb1 is up.

Hit the /healthz endpoint again, and make sure both myweb1 and myweb2 will be hitted.

### Load balancer

Try to stop the master haproxy service within the container, e.g. mylb1.
```
service haproxy stop
```

Wait for a moment then check the keepalived logs by monitoring /var/log/syslog in both containers, to see if mylb1 has entered BACKUP state, and mylb2 transitioned to MASTER state.

You can also verify by typing in both containers:
```
ip addr show eth0
```
If it works correctly, you will see the virtual ip address appeared in the output in container mylb2 rather than container mylb1.

Run `curl` in either of the two load balancer containers. Send request to the virutal ip and see if it still returns the content from web servers.

Start mylb1 again:
```
service haproxy start
```

Wait for a moment then check the keepalived logs, to see if mylb1 gained MASTER state, and mylb2 returned back to BACKUP state.

You can also verify by `ip addr` command, to see if the virtual ip address appeared in the output in container mylb1 again.

Run `curl` in either of the two load balancer containers. Send request to the virutal ip and see if it still returns the content from web servers.
