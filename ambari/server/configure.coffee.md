
## Configuration
 
Exemple:
 
```json
{ "ambari": {
  "name": "big",
  "username": process.env["HADOOP_USERNAME"],
  "password": process.env["HADOOP_PASSWORD"],
  "config": {
    "client.security": "ldap",
    "authentication.ldap.useSSL": true,
    "authentication.ldap.primaryUrl": "master3.ryba:636",
    "authentication.ldap.baseDn": "ou=users,dc=ryba",
    "authentication.ldap.bindAnonymously": false,
    "authentication.ldap.managerDn": "cn=admin,ou=users,dc=ryba",
    "authentication.ldap.managerPassword": "XXX",
    "authentication.ldap.usernameAttribute": "cn"
} } }
```
 
    
    module.exports  = handler: ->
      # Servers onfiguration
      ambari_server = @config.ryba.ambari_server ?= {}
      # Install 1.2.0 with rpm (http://incubator.apache.org/ambari/1.2.0/installing-hadoop-using-ambari/content/ambari-chap2-1.html)
      # http://public-repo-1.hortonworks.com/AMBARI-1.x/repos/centos6/AMBARI-1.x-1.el6.noarch.rpm
      # Upgrading from 1.2 to 1.2.1 by replacing repo file (http://incubator.apache.org/ambari/1.2.1/installing-hadoop-using-ambari/content/ambari-chap7.html)
      # http://public-repo-1.hortonworks.com/ambari/centos6/1.x/GA/ambari.repo
      # Install 1.2.1 with rpm (http://incubator.apache.org/ambari/1.2.1/installing-hadoop-using-ambari/content/ambari-chap2-1.html)
      # http://public-repo-1.hortonworks.com/ambari/centos6/1.x/GA/ambari-1.2.0.1-1.el6.noarch.rpm
      # ambari.proxy ?= proxy.http_proxy
      ambari_server.http ?= '/var/www/html'
      ambari_server.repo ?= 'http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.1.2/ambari.repo'
      ambari_server.conf_dir ?= '/etc/ambari-server/conf'
      ambari_server.database_password ?= 'ambari123'
      ambari_server.config ?= {}
      ambari_server.config['ambari-server.user'] ?= 'root'
      ambari_server.config['server.jdbc.user.passwd'] ?= '/etc/ambari-server/conf/password.dat'
      ambari_server.config['server.jdbc.user.name'] ?= 'ambari'
      ambari_server.config['server.jdbc.database'] ?= 'mysql'
      ambari_server.config['server.jdbc.database_name'] ?= 'ambari'
      cluster = @config.cluster ?= {}
      cluster.name ?= "cluster-6vm"

      # ambari.java ?= null
      ambari_server.java_home ?= '/usr/lib/jvm/java'
    # ambari.local ?= 
    #   '1.2.0':
    #     'centos6,redhat6,oraclelinux6': [
    #       baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/GA/1.2.0'
    #       repoid: 'HDP-1.3.0'
    #       reponame: 'HDP'
    #     ,
    #       baseurl: 'HDP-epel'
    #       repoid: 'HDP-epel'
    #       reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch]]>'
    #     ]
    #     'centos6,redhat5,oraclelinux5': [
    #       baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos5/1.x/GA/1.2.0'
    #       repoid: 'HDP-1.3.0'
    #       reponame: 'HDP'
    #     ,
    #       baseurl: 'HDP-epel'
    #       repoid: 'HDP-epel'
    #       reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-5&arch=$basearch]]>'
    #     ]
    #     'suse11,sles11': [
    #       baseurl: 'http://public-repo-1.hortonworks.com/HDP/suse11/1.x/GA/1.2.0'
    #       repoid: 'HDP-1.3.0'
    #       reponame: 'HDP'
    #     ]
    #   '1.2.1':
    #     'centos6,redhat6,oraclelinux6': [
    #       baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/GA/1.2.1'
    #       repoid: 'HDP-1.3.0'
    #       reponame: 'HDP'
    #     ,
    #       baseurl: 'HDP-epel'
    #       repoid: 'HDP-epel'
    #       reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch]]>'
    #     ]
    #     'centos6,redhat5,oraclelinux5': [
    #       baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos5/1.x/GA/1.2.1'
    #       repoid: 'HDP-1.3.0'
    #       reponame: 'HDP'
    #     ,
    #       baseurl: 'HDP-epel'
    #       repoid: 'HDP-epel'
    #       reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-5&arch=$basearch]]>'
    #     ]
    #     'suse11,sles11': [
    #       baseurl: 'http://public-repo-1.hortonworks.com/HDP/suse11/1.x/GA/1.2.1'
    #       repoid: 'HDP-1.3.0'
    #       reponame: 'HDP'
    #     ]
    #   '1.3.0':
    #     'centos6,redhat6,oraclelinux6': [
    #       baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/GA/1.3.0.0'
    #       repoid: 'HDP-1.3.0'
    #       reponame: 'HDP'
    #     ,
    #       baseurl: 'HDP-epel'
    #       repoid: 'HDP-epel'
    #       reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch]]>'
    #     ]
    #     'centos6,redhat5,oraclelinux5': [
    #       baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos5/1.x/GA/1.3.0.0'
    #       repoid: 'HDP-1.3.0'
    #       reponame: 'HDP'
    #     ,
    #       baseurl: 'HDP-epel'
    #       repoid: 'HDP-epel'
    #       reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-5&arch=$basearch]]>'
    #     ]
    #     'suse11,sles11': [
    #       baseurl: 'http://public-repo-1.hortonworks.com/HDP/suse11/1.x/GA/1.3.0.0'
    #       repoid: 'HDP-1.3.0'
    #       reponame: 'HDP'
    #     ]
