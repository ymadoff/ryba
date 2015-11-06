
# Hadoop HDFS

This module is not intended to be used directly. It is required by other modules to
setup a base installation. Such modules include "ryba/hadoop/hdfs_client",
"ryba/hadoop/hdfs_dn" and "ryba/hadoop/hdfs_nn".

In its current state, we are only supporting the installation of a
[secure cluster with Kerberos][secure].

[secure]: http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SecureMode.html

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/hadoop/core'

## Configure

The properties "hdp.hdfs.site['dfs.namenode.name.dir']" and
"hdp.hdfs.site['dfs.datanode.data.dir']" are required.

*   `ryba.hdfs.hadoop_policy`
*   `ryba.hdfs.hdfs.namenode_timeout`
*   `ryba.hdfs.hdfs.site` (object)
    Properties added to the "hdfs-site.xml" file.
*   `ryba.hdfs.nameservice`
    The Unix MapReduce group name or a group object (see Mecano Group documentation).

Example:

```json
{
  "ryba": {
    "hdfs": {
      site": {
        "dfs.journalnode.edits.dir": "/var/run/hadoop-hdfs/journalnode\_edit\_dir"
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      if ctx.hdfs_configured then return else ctx.hdfs_configured = true
      # return if ctx.hdfs_configured
      # ctx.hdfs_configured = true
      require('./core').configure ctx
      # require('./core_ssl').configure ctx
      {core_site, static_host, realm} = ctx.config.ryba
      throw new Error "Missing value for 'hdfs.krb5_user.password'" unless ctx.config.ryba.hdfs.krb5_user.password?
      throw new Error "Missing value for 'krb5_user.password'" unless ctx.config.ryba.krb5_user.password?
      # Options and configuration
      hdfs = ctx.config.ryba.hdfs ?= {}
      ctx.config.ryba.hdfs.namenode_timeout ?= 20000 # 20s
      # Options for "hdfs-site.xml"
      hdfs.site ?= {}
      hdfs.site['dfs.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # REPLACED by "dfs.namenode.https-address": hdfs.site['dfs.https.port'] ?= '50470' # The https port where NameNode binds
      hdfs.site['fs.permissions.umask-mode'] ?= '027' # 0750

## Configuration for Kerberos

Update the HDFS configuration stored inside the "/etc/hadoop/hdfs-site.xml" file
with Kerberos specific properties.

      # If "true", access tokens are used as capabilities
      # for accessing datanodes. If "false", no access tokens are checked on
      # accessing datanodes.
      hdfs.site['dfs.block.access.token.enable'] ?= 'true'

    module.exports.push header: 'Hadoop HDFS # Install', timeout: -1, handler: ->
      @service
        name: 'hadoop'
      @service
        name: 'hadoop-hdfs'
      @service
        name: 'hadoop-libhdfs'
      @service
        name: 'hadoop-client'
      @service
        name: 'openssl'

## Kerberos User

Create the HDFS user principal. This will be the super administrator for the HDFS
filesystem. Note, we do not create a principal with a keytab to allow HDFS login
from multiple sessions with braking an active session.

    module.exports.push header: 'HDFS # Kerberos User', handler: ->
      {hdfs, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc merge
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , hdfs.krb5_user

## SPNEGO

Create the SPNEGO service principal in the form of "HTTP/{host}@{realm}" and place its
keytab inside "/etc/security/keytabs/spnego.service.keytab" with ownerships set to "hdfs:hadoop"
and permissions set to "0660". We had to give read/write permission to the group because the
same keytab file is for now shared between hdfs and yarn services.

    module.exports.push header: 'HDFS # SPNEGO', handler: module.exports.spnego = ->
      {hdfs, hadoop_group, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: "HTTP/#{@config.host}@#{realm}"
        randkey: true
        keytab: '/etc/security/keytabs/spnego.service.keytab'
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o660 # need rw access for hadoop and mapred users
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @execute # Validate keytab access by the hdfs user
        cmd: "su -l #{hdfs.user.name} -c \"klist -kt /etc/security/keytabs/spnego.service.keytab\""
        if: -> @status -1



## Dependencies

    {merge} = require 'mecano/lib/misc'

[hdfs_secure]: http://hadoop.apache.org/docs/r2.4.1/hadoop-project-dist/hadoop-common/SecureMode.html#DataNode
[hawq]: http://docs.gopivotal.com/pivotalhd/InstallingHAWQ.html
[greenplum]: http://nixustechnologies.com/2014/03/31/install-greenplum-community-edition/
[mapr]: http://doc.mapr.com/display/MapR/Preparing+Each+Node
[hpl]: http://www.slideshare.net/technmsg/improving-hadoop-performancevialinux
[kate]: http://fr.slideshare.net/cloudera/hadoop-troubleshooting-101-kate-ting-cloudera
