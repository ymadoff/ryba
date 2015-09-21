# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrotr can  provision, 
manage and monitor  a Hadoop cluster.
    
    module.exports = []

## Configuration
 
Exemple:
 
```json
ambari:
  name: 'big'
  username: process.env['HADOOP_USERNAME']
  password: process.env['HADOOP_PASSWORD']
  config: 
    'client.security': 'ldap'
    'authentication.ldap.useSSL': false
    'authentication.ldap.primaryUrl': 'pcy0qstar.pcy.edfgdf.fr:389'
    'authentication.ldap.baseDn': 'ou=users,dc=edfgdf,dc=fr'
    'authentication.ldap.bindAnonymously': false
    'authentication.ldap.managerDn': 'cn=solaix,ou=systems,ou=lotc,dc=edfgdf,dc=fr'
    'authentication.ldap.managerPassword': 'XXX'
    'authentication.ldap.usernameAttribute': 'cn'
```
 
    
    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      # Servers onfiguration
      ambari_server = ctx.config.ryba.ambari_server ?= {}
      # Install 1.2.0 with rpm (http://incubator.apache.org/ambari/1.2.0/installing-hadoop-using-ambari/content/ambari-chap2-1.html)
      # http://public-repo-1.hortonworks.com/AMBARI-1.x/repos/centos6/AMBARI-1.x-1.el6.noarch.rpm
      # Upgrading from 1.2 to 1.2.1 by replacing repo file (http://incubator.apache.org/ambari/1.2.1/installing-hadoop-using-ambari/content/ambari-chap7.html)
      # http://public-repo-1.hortonworks.com/ambari/centos6/1.x/GA/ambari.repo
      # Install 1.2.1 with rpm (http://incubator.apache.org/ambari/1.2.1/installing-hadoop-using-ambari/content/ambari-chap2-1.html)
      # http://public-repo-1.hortonworks.com/ambari/centos6/1.x/GA/ambari-1.2.0.1-1.el6.noarch.rpm
      # ambari.proxy ?= proxy.http_proxy
      ambari_server.http ?= '/var/www/html'
      ambari_server.repo ?= 'http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.0.0/ambari.repo'
      ambari_server.conf_dir ?= '/etc/ambari-server/conf'
      ambari_server.database_password ?= 'ambari123'
      ambari_server.config ?= {}
      ambari_server.config['ambari-server.user'] ?= 'root'
      ambari_server.config['server.jdbc.user.passwd'] ?= '/etc/ambari-server/conf/password.dat'
      ambari_server.config['server.jdbc.user.name'] ?= 'ambari'
      ambari_server.config['server.jdbc.database'] ?= 'mysql'
      ambari_server.config['server.jdbc.database_name'] ?= 'ambari'
      cluster = ctx.config.cluster ?= {}
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

    # module.exports.push commands: 'check', modules: 'ryba/ambari/server/check'



    module.exports.push commands: 'install', modules: [
      'ryba/ambari/server/install'
      'ryba/ambari/server/start'
      # 'ryba/ambari/server/check'
    ]

    #module.exports.push commands: 'start', modules: 'ryba/ambari/server/start'

    #module.exports.push commands: 'stop', modules: 'ryba/ambari/server/stop'

    #module.exports.push commands: 'status', modules: 'ryba/ambari/server/status'
[Ambari-server]: http://ambari.apache.org
