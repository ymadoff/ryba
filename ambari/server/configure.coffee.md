
# Ambari Server Configuration

## Minimal Example

```json
{ "config": {
  "admin_password": "MySecret"
  "db": {
    "password": "MySecret"
  }
} }
```

## Database Encryption

```json
{ "config": {
  "master_key": "MySecret",
} }
```

## LDAP Connection

```json
{ "config": {
  "client.security": "ldap",
  "authentication.ldap.useSSL": true,
  "authentication.ldap.primaryUrl": "master3.ryba:636",
  "authentication.ldap.baseDn": "ou=users,dc=ryba",
  "authentication.ldap.bindAnonymously": false,
  "authentication.ldap.managerDn": "cn=admin,ou=users,dc=ryba",
  "authentication.ldap.managerPassword": "XXX",
  "authentication.ldap.usernameAttribute": "cn"
} }
```

    module.exports = ->
      # Dependencies
      [java_ctx] = @contexts('masson/commons/java').filter (ctx) => ctx.config.host is @config.host
      [pg_ctx] = @contexts 'masson/commons/postgres/server'
      [my_ctx] = @contexts 'masson/commons/mysql/server'
      [maria_ctx] = @contexts 'masson/commons/mariadb/server'
      [krb5_ctx] = @contexts 'masson/core/krb5_server'
      [hadoop_ctx] = @contexts 'ryba/hadoop/core'
      @config.ryba ?= {}
      {host, ssl} = @config
      {db_admin} = @config.ryba
      # Init
      options = @config.ryba.ambari_server ?= {}
      # throw Error "Required Option: cluster_name" unless options.cluster_name
      throw Error "Required Option: db.password" unless options.db?.password

## Environnment

      options.host = host
      options.http ?= '/var/www/html'
      options.repo ?= null
      options.conf_dir ?= '/etc/ambari-server/conf'
      # options.database ?= {}
      # options.database.engine ?= @config.ryba.db_admin.engine
      # options.database.password ?= null
      options.sudo ?= false
      options.java_home ?= java_ctx.config.java.java_home
      options.master_key ?= null
      options.admin ?= {}
      options.current_admin_password ?= 'admin'
      throw Error "Required Option: admin_password" unless options.admin_password

## Identities

Note, there are no identities created by the Ambari package. Identities are only
used in case the server and its agents run as sudoers.

The non-root user you choose to run the Ambari Server should be part of the 
Hadoop group. The default group name is "hadoop".

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'ambari'
      options.group.system ?= true
      options.hadoop_group ?= hadoop_ctx?.config.ryba.hadoop_group
      options.hadoop_group = name: options.group if typeof options.group is 'string'
      options.hadoop_group ?= {}
      options.hadoop_group.name ?= 'hadoop'
      options.hadoop_group.system ?= true
      options.hadoop_group.comment ?= 'Hadoop Group'
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'ambari'
      options.user.system ?= true
      options.user.comment ?= 'Ambari User'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.groups ?= ['hadoop']
      options.user.gid = options.group.name

## Ambari TLS and Truststore

      options.ssl ?= ssl
      options.truststore ?= {}
      if options.ssl
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        options.truststore.target ?= "#{options.conf_dir}/truststore"
        throw Error "Required Property: truststore.password" if not options.truststore.password
        options.truststore.caname ?= 'hadoop_root_ca'
        options.truststore.type ?= 'jks'
        throw Error "Invalid Truststore Type: #{truststore.type}" unless options.truststore.type in ['jks', 'jceks', 'pkcs12']

## JAAS

Multiple ambari instance on a same server involve a different principal or the principal must point to the same keytab.

`auth=KERBEROS;proxyuser=ambari`

      options.jaas ?= {}
      options.jaas.enabled ?= false
      if options.jaas.enabled
        options.jaas.realm ?= hadoop_ctx?.config.ryba.realm
        options.jaas.realm ?= options.jaas.principal.split('@')[1] if options.jaas.principal
        throw Error "Require Property: jaas.realm or jaas.principal" unless options.jaas.realm
        # Masson 2 will require some adjustment in the way we discover the kerberos admin information
        krb5 = krb5_ctx.config.krb5.etc_krb5_conf.realms[options.jaas.realm]
        options.jaas.kadmin_principal ?= krb5.kadmin_principal
        throw Error "Require Property: jaas.kadmin_principal" unless options.jaas.kadmin_principal
        options.jaas.kadmin_password ?= krb5.kadmin_password
        throw Error "Require Property: jaas.kadmin_password" unless options.jaas.kadmin_password
        options.jaas.admin_server ?= krb5.admin_server
        throw Error "Require Property: jaas.admin_server" unless options.jaas.admin_server
        options.jaas.keytab ?= '/etc/ambari-server/conf/ambari.service.keytab'
        options.jaas.principal ?= "ambari/_HOST@#{hadoop_ctx?.config.ryba.realm}" if hadoop_ctx?.config.ryba.realm
        options.jaas.principal = options.jaas.principal.replace '_HOST', @config.host

## Configuration

      options.config ?= {}
      options.config['server.url_port'] ?= "8440"
      options.config['server.secured_url_port'] ?= "8441"
      options.config['api.ssl'] ?= unless options.ssl then 'false' else 'true'
      options.config['client.api.port'] ?= "8080"
      # Be Carefull, collision in HDP 2.5.3 on port 8443 between Ambari and Knox
      options.config['client.api.ssl.port'] ?= "8442"

## Database

Ambari DB password is stash into "/etc/ambari-server/conf/password.dat".

      options.supported_db_engines ?= ['mysql', 'mariadb', 'postgres']
      if pg_ctx then options.db.engine ?= 'postgres'
      else if maria_ctx then options.db.engine ?= 'mariadb'
      else if my_ctx then options.db.engine ?= 'mysql'
      else options.db.engine ?= 'derby'
      Error 'Unsupported database engine' unless options.db.engine in options.supported_db_engines
      options.db[k] ?= v for k, v of db_admin[options.db.engine]
      options.db.database ?= 'ambari'
      options.db.username ?= 'ambari'

## Hive provisionning

      options.db_hive ?= false
      options.db_hive = password: options.db_hive if typeof options.db_hive is 'string'
      if options.db_hive
        options.db_hive.engine ?= options.db.engine
        options.db_hive[k] ?= v for k, v of db_admin[options.db_hive.engine]
        options.db_hive.database ?= 'hive'
        options.db_hive.username ?= 'hive'
        throw Error "Required Option: db_hive.password" unless options.db_hive.password

## Oozie provisionning

      options.db_oozie ?= false
      options.db_oozie = password: options.db_oozie if typeof options.db_oozie is 'string'
      if options.db_oozie
        options.db_oozie.engine ?= options.db.engine
        options.db_oozie[k] ?= v for k, v of db_admin[options.db_oozie.engine]
        options.db_oozie.database ?= 'oozie'
        options.db_oozie.username ?= 'oozie'
        throw Error "Required Option: db_oozie.password" unless options.db_oozie.password

## Ranger provisionning

      options.db_ranger ?= false
      options.db_ranger = password: options.db_ranger if typeof options.db_ranger is 'string'
      if options.db_ranger
        options.db_ranger.engine ?= options.db.engine
        options.db_ranger[k] ?= v for k, v of db_admin[options.db_ranger.engine]
        options.db_ranger.database ?= 'ranger'
        options.db_ranger.username ?= 'ranger'
        throw Error "Required Option: db_ranger.password" unless options.db_ranger.password
        
        
