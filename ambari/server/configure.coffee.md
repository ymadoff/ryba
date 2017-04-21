
# Ambari Server Configuration

## Minimal Example

```json
{ "ambari_server": {
  "cluster_name": "mycluster",
  "repo": "http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.5.0.3/ambari.repo"
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

## LDAP Example

```json
{ "ambari_server": {
  "cluster_name": "mycluster",
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


    module.exports = ->
      # Dependencies
      [java_ctx] = @contexts('masson/commons/java').filter (ctx) => ctx.config.host is @config.host
      [pg_ctx] = @contexts 'masson/commons/postgres/server'
      [my_ctx] = @contexts 'masson/commons/mysql/server'
      [maria_ctx] = @contexts 'masson/commons/mariadb/server'
      @config.ryba ?= {}
      {db_admin} = @config.ryba
      # Init
      ambari_server = @config.ryba.ambari_server ?= {}
      throw Error "Required Option: ambari_server.cluster_name" unless ambari_server.cluster_name
      throw Error "Required Option: ambari_server.db.password" unless ambari_server.db?.password

## Environnment

      ambari_server.http ?= '/var/www/html'
      ambari_server.repo ?= null
      ambari_server.conf_dir ?= '/etc/ambari-server/conf'
      # ambari_server.database ?= {}
      # ambari_server.database.engine ?= @config.ryba.db_admin.engine
      # ambari_server.database.password ?= null
      ambari_server.sudo ?= false
      ambari_server.java_home ?= java_ctx.config.java.java_home
      ambari_server.admin ?= {}
      ambari_server.current_admin_password ?= 'admin'
      throw Error "Required Option: admin_password" unless ambari_server.admin_password

## Identities

Note, there are no identities created by the Ambari package. Identities are only
used in case the server and its agents run as sudoers.

The non-root user you choose to run the Ambari Server should be part of the 
Hadoop group. The default group name is "hadoop".

      # Group
      ambari_server.group = name: ambari_server.group if typeof ambari_server.group is 'string'
      ambari_server.group ?= {}
      ambari_server.group.name ?= 'ambari'
      ambari_server.group.system ?= true
      # User
      ambari_server.user = name: ambari_server.user if typeof ambari_server.user is 'string'
      ambari_server.user ?= {}
      ambari_server.user.name ?= 'ambari'
      ambari_server.user.system ?= true
      ambari_server.user.comment ?= 'Ambari User'
      ambari_server.user.home ?= "/var/lib/#{ambari_server.user.name}"
      ambari_server.user.groups ?= ['hadoop']
      ambari_server.user.gid = ambari_server.group.name

## Configuration

      ambari_server.config ?= {}
      # ambari_server.config['ambari-server.user'] ?= 'root'
      # ambari_server.config.server ?= {}
      ambari_server.config['server.url_port'] ?= "8440"
      ambari_server.config['server.secured_url_port'] ?= "8441"
      ambari_server.config['client.api.port'] ?= "8080"
      # Be Carefull, collision in HDP 2.5.3 on port 8443 between Ambari and Knox
      ambari_server.config['client.api.ssl.port'] ?= "8443"

## Database

Ambari DB password is stash into "/etc/ambari-server/conf/password.dat".

      ambari_server.supported_db_engines ?= ['mysql', 'mariadb', 'postgres']
      if pg_ctx then ambari_server.db.engine ?= 'postgres'
      else if maria_ctx then ambari_server.db.engine ?= 'mariadb'
      else if my_ctx then ambari_server.db.engine ?= 'mysql'
      else ambari_server.db.engine ?= 'derby'
      Error 'Unsupported database engine' unless ambari_server.db.engine in ambari_server.supported_db_engines
      ambari_server.db[k] ?= v for k, v of db_admin[ambari_server.db.engine]
      ambari_server.db.database ?= 'ambari'
      ambari_server.db.username ?= 'ambari'
      ambari_server.config['server.jdbc.user.name'] = ambari_server.db.username
      ambari_server.config['server.jdbc.database'] = ambari_server.db.engine
      ambari_server.config['server.jdbc.user.passwd'] ?= '/etc/ambari-server/conf/password.dat'
      ambari_server.config['server.jdbc.database_name'] ?= ambari_server.db.database
