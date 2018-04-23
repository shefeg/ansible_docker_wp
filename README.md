## Dockerized Wordpress application deployment
Deploy dockerized Wordpress application using Ansible into Ubuntu 16.04 server.  
Project overview: NGINX + Wordpress + PHP-FPM + MySQL + Memcached.

### Getting Started
#### Prerequisites
1. Windows/Linux environment with Andible version 2.3+ installed

#### Installing
1. Clone repository
```
git clone https://shefeg@bitbucket.org/shefeg/ansible_docker_wp.git
cd ansible_docker_wp
```  

2. Specify ip of the server in `hosts` file where you will be making deployment
```
[ubuntu]
# ip of ubuntu server here
10.130.75.250
```  

3. Deploy command example with default variables:
```
ansible-playbook main.yml --vault-password-file vault_secret.sh
```  
`vault_secret.sh` contains password "123" for demo purposes.
This file is intended for using in CI-CD chain for automated deployments
with default variables.

4. You can specify your own variable values in the command line during run of `ansible-playbook` tool:
```
ansible-playbook main.yml --extra-vars "mysql_db_name=wordpressdb \
mysql_db_user=wordpressuser mysql_db_password='Foo123456*' \
mysql_db_root_password='Foo1234567*1' wp_site_url=wp-app.com \
wp_admin_user=wpadmin wp_admin_password='wpadmin1' wp_admin_email='wpadmin@example.com'"
```
Variable names should be self explonatory.
Though just in case will give you info about some of them:
`wp_site_url`: Wordpress site URL. This URL will be used in self-signed certificates.  
`wp_admin_user, wp_admin_password, wp_admin_email`: credentials to log in to the Wordpress admin page.

5. After `ansible-playbook` tool completes, self-signed certificates `.pem`,`.crt` created on the
created on the remote server in `/root/compose/nginx/certificates` directory.
You should add them to the trusted certificate store on the machine from where
you'll be accessing Wordpress site.

6. After login into Wordpress admin page you should **Enable Object Caching** to initialize memcaching.
In order to do this:
Navigate to Plugins, install and activate "WP-FFPC" plugin and click Settings.
Set the following minimal configuration options:

* **Cache Type/Select Backend:** *PHP Memcached*
* **Backend Settings/Hosts:** *memcached:11211*
* **Backend Settings/Authentication:** *username: Empty*
* **Backend Settings/Authentication:** *password: Empty*
* **Backend Settings/Enable memcached binary mode:** *Activated*

Install ans activate "W3 Total Cache" plugin.

7. Run the following commands from the remote machine where you performed deployment:
```
WP_CLI=$(docker ps -q -f name=compose_wordpress_1)
docker container exec ${WP_CLI} bash -c 'wp --allow-root core update && \
wp --allow-root plugin update --all && wp --allow-root theme update --all'
```

#### Wordpress security hardening:
1. Use SSL certificates for data security
2. Deny direct access to uploads directory
3. Prevent access to any files starting with a dot, like .htaccess
or text editor temp files
4. Prevent access to any files starting with a $ (usually temp files)
5. Do not log access to robots.txt, to keep the logs cleaner
6. Do not log access to the favicon, to keep the logs cleaner
7. Keep images and CSS around in browser cache for as long as possible,
to cut down on server load
8. Redirect all requests for unknown URLs out of images and back to the
root index.php file
9. Force potentially-malicious files in the /images directory to be served
with a text/plain mime type, to prevent them from being executed by
the PHP handler

#### Wordpress host machine security hardening:
1. Limit ssh access to the machine from outside:
2. Limit user access to the machine:
    * only admin users should have access to the machine
    * limit sudo privileges
3. Make sure only needed ports are opened on the machine, other ports should be closed
4. Use secured jump host (under vpn or access from limited subnets)
to ssh to this machine (and other machines in the environments)
5. Perform regular security patching and security updates on the machine

Popular and good option to deploy infrastructure environments in cloud providers AWS, Azure, Google.
