## Easy NGINX Reverse Proxy

This is a simple Reverse Proxy container, designed to make creating reverse proxies super easy. 
When I learning how to set this up, I had a bunch of issues getting my containers to talk to each other outside of my NordVPN image.
Once I figured out how to do it, I built a script to automate the setup of additional proxies. 
See the 'Scripts' section for details on the script itself. 

## About the Image
* This is just an official nginx image with a custom script installed into it, and bash installed to run the script. Nothing fancy. 

## Scripts
The image contains 3 custom scripts. Only 2 of them are actually used.
* `setupscript` 
     - This script checks the /etc/nginx folder for any existing configurations. 
        - If no configuration is found, it creates the base nginx.conf file. 
	    - This script also adds the /etc/nginx/sites folder, where the proxy configurations are stored.
	 - Once the config files have been setup, it will try and verify the configs. 
	    - If a fault occurs, the script fails and exits the container. See the container's output for details.
		   - You can view the fault at /etc/nginx/errlog.txt (Only the last attempt is stored)
		- If no fault occurs, then the script will start nginx using the configs in /etc/nginx/
		   - Then the script runs /bin/bash (because otherwise the container exits due to script finishing)

* `wait-for`
	- Located in /usr/bin for easy access from bash. 
	- Script that waits for a connection to become active. I did not write this script, and have not used the script, as I was unable to get it functioning prior to writing my 'setupscript'. 
	- This script came from another reverse-proxy help thread (that was really not much help). Its included if someone else wants to figure it out.
	- This script is probably useful if another container goes down. Nginx does not like starting up if if cannot see all configured upstreams, so this script may solve that. I just haven't looked into it. 
	
* `new-site`
	- This script is stored in /usr/bin so that it can be easily called when attaching to the container
	- `new-site` help produces a short help guide.
	- `new-site build' will save a new conf file to /etc/nginx/sites. All parameters below are required.
		* filename 		 -- This is the filename of the conf file. (filename.conf). 
						 -- This is also used in the 'upstream' section to have unique IDs (required by nginx)
						 
		* Container_ID 	 -- The destination container name for nginx to look at. See examples: 
						 -- 'apache' / 'couchpotato' / 'webserver' / etc...
						 -- if using services behind a vpn container, this should be the name of the vpn container.
		
		* Container_Port -- Port the destination container is listening for communication on.  
						 -- All data nginx receives on its listening port passes to this port on the container specified above.

		* Listen_Port 	 -- Port that the nginx container is listening on for communication. 
						 -- This is the port that must be mapped when starting this nginx container.
	

## Adding additional proxy configurations

Use the `new-site` command after attaching to the container. proper syntax is:
```
	new-site build [UniqueFilename] [Container] [Container's Port] [Nginx Listening Port]
	new-site build apache80 apache 80 8080
```
The second command shown above will create 'apache80.conf' in /etc/nginx/sites. 
This will tell nginx to direct all traffic received on nginx port 8080 to the apache container's port 80.

You can also map /etc/nginx to a volume and have direct access to your config files for manipulation outside of the container.

## Docker Run

```
    docker run -ti --name reverseproxy \
	-v "/etc/localtime:/etc/localtime:ro" \
	-v "/CONFIG_LOCATION:/etc/nginx/"
	-p 8080:80 \
    -d rfbomb/easyproxy
```

## Docker Compose

```
version: '2'
services:
#--------------   Reverse Proxy  ---------------------------
proxy:
   image: rfbomb/easyproxy
   container_name: ReverseProxy
   stdin_open: true
   tty: true
   networks:
      - TS_Bridge
   #Map all ports that are exposed in the VPN service
   ports:
     - "80:80" 
     - "9090:9090"
   volumes:
      - /etc/localtime:/etc/localtime:ro
      - /CONFIG_LOCATION:/etc/nginx/
   #restart: unless-stopped
```