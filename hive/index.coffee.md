
# Hive

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/hadoop/hdfs_client'
    module.exports.push 'ryba/hadoop/core' # Hive dependency, need to create user and group for zookeeper

## Configure

*   `hive.user` (object|string)
    The Unix Hive login name or a user object (see Mecano User documentation).
*   `hive.group` (object|string)
    The Unix Hive group name or a group object (see Mecano Group documentation).

Example:

```json
{
  "ryba": {
    "hive": {
      "user": {
        "name": "hive", "system": true, "gid": "hive",
        "comment": "Hive User", "home": "/home/hive"
      },
      "group": {
        "name": "hive", "system": true
      }
    }
  }
}
```

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.hive_configured
      ctx.hive_configured = true
      require('masson/commons/java').configure ctx
      require('../hadoop/core').configure ctx
      {static_host, realm} = ctx.config.ryba
      hive = ctx.config.ryba.hive ?= {}
      hive.conf_dir ?= '/etc/hive/conf'
      # User
      hive.user ?= {}
      hive.user = name: hive.user if typeof hive.user is 'string'
      hive.user.name ?= 'hive'
      hive.user.system ?= true
      hive.user.groups ?= 'hadoop'
      hive.user.comment ?= 'Hive User'
      hive.user.home ?= '/var/lib/hive'
      # Group
      hive.group ?= {}
      hive.group = name: hive.group if typeof hive.group is 'string'
      hive.group.name ?= 'hive'
      hive.group.system ?= true
      hive.user.gid = hive.group.name
      # Configuration
      hive.site ?= {}
      hive.site[' hive.metastore.uris '] = null # Clean up HDP mess
      hive.site[' hive.cluster.delegation.token.store.class '] = null # Clean up HDP mess
      hive.site['hive.metastore.local'] = null
      # To prevent memory leak in unsecure mode, disable [file system caches](https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2)
      # , by setting following params to true
      hive.site['fs.hdfs.impl.disable.cache'] ?= 'false'
      hive.site['fs.file.impl.disable.cache'] ?= 'false'
      # TODO: encryption is only with Kerberos, need to check first
      # http://hortonworks.com/blog/encrypting-communication-between-hadoop-and-your-analytics-tools/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+hortonworks%2Ffeed+%28Hortonworks+on+Hadoop%29
      hive.site['hive.server2.thrift.sasl.qop'] ?= 'auth'
      # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm-chap14-2-3.html#rmp-chap14-2-3-5
      # If true, the metastore thrift interface will be secured with
      # SASL. Clients must authenticate with Kerberos.
      hive.site['hive.metastore.sasl.enabled'] ?= 'true'
      # The path to the Kerberos Keytab file containing the metastore
      # thrift server's service principal.
      hive.site['hive.metastore.kerberos.keytab.file'] ?= '/etc/hive/conf/hive.service.keytab'
      # The service principal for the metastore thrift server. The
      # special string _HOST will be replaced automatically with the correct  hostname.
      hive.site['hive.metastore.kerberos.principal'] ?= "hive/#{static_host}@#{realm}"
      hive.site['hive.metastore.cache.pinobjtypes'] ?= 'Table,Database,Type,FieldSchema,Order'
      hive.site['hive.security.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive.site['hive.security.metastore.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive.site['hive.security.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.ProxyUserAuthenticator'
      # see https://cwiki.apache.org/confluence/display/Hive/WebHCat+InstallWebHCat
      hive.site['hive.security.metastore.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.HadoopDefaultMetastoreAuthenticator'
      hive.site['hive.metastore.pre.event.listeners'] ?= 'org.apache.hadoop.hive.ql.security.authorization.AuthorizationPreEventListener'
      # Unset unvalid properties
      hive.site['hive.optimize.mapjoin.mapreduce'] = null
      hive.site['hive.heapsize'] = null
      hive.site['hive.auto.convert.sortmerge.join.noconditionaltask'] = null # "does not exist"
      hive.site['hive.exec.max.created.files'] ?= '100000' # "expects LONG type value"

## Users & Groups

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep hive
hive:x:493:493:Hive:/var/lib/hive:/sbin/nologin
cat /etc/group | grep hive
hive:x:493:
```

    module.exports.push name: 'Hive & HCat # Users & Groups', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      ctx
      .group hive.group
      .user hive.user
      .then next

## Install

Instructions to [install the Hive and HCatalog RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3/bk_installing_manually_book/content/rpm-chap6-1.html)

    module.exports.push name: 'Hive & HCat # Install', timeout: -1, handler: (ctx, next) ->
      ctx
      .service
        name: 'hive'
      .hdp_select
        name: 'hive-webhcat' # HIVE_AUX_JARS_PATH fix
      .then next

## Environment

Upload the "hive-env.sh" script from the companion file. Note, this file isnt
present on a fresh install.

    module.exports.push name: 'Hive & HCat # Env', timeout: -1, handler: (ctx, next) ->
      {java_home} = ctx.config.java
      {hive} = ctx.config.ryba
      ctx
      .write
        source: "#{__dirname}/../resources/hive/hive-env.sh"
        destination: "#{hive.conf_dir}/hive-env.sh"
        local_source: true
        not_if_exists: true
      .write
        destination: "#{hive.conf_dir}/hive-env.sh"
        write: [
          match: /^export JAVA_HOME=.*$/m
          replace: "export JAVA_HOME=#{java_home}"
        ,
          match: /^export HIVE_AUX_JARS_PATH=.*$/m
          replace: 'export HIVE_AUX_JARS_PATH=${HIVE_AUX_JARS_PATH:-/usr/hdp/current/hive-webhcat/share/hcatalog/hive-hcatalog-core.jar} # RYBA FIX'
        ]
      .then next



