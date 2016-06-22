
## Configuration

Look at the file [DFSConfigKeys.java][keys] for an exhaustive list of supported
properties.

*   `ryba.hdfs.nn.site` (object)
    Properties added to the "hdfs-site.xml" file.
*   `ryba.hdfs.namenode_opts` (string)
    NameNode options.

Example:

```json
{
  "ryba": {
    "hdfs": {
      "namenode_opts": "-Xms1024m -Xmx1024m",
      "include": ["in.my.cluster"],
      "exclude": "not.in.my.cluster"
    }
  }
}
```

    module.exports = handler: ->
      require('../core/configure').handler.call @
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      jn_ctxs = @contexts 'ryba/hadoop/hdfs_jn', require('../hdfs_jn/configure').handler
      dn_ctxs = @contexts 'ryba/hadoop/hdfs_dn'
      {ryba} = @config
      ryba.hdfs.nn ?= {}
      ryba.hdfs.nn.conf_dir ?= '/etc/hadoop-hdfs-namenode/conf'
      ryba.hdfs.nn.core_site ?= {}
      #Number of minutes after which the checkpoint gets deleted
      ryba.hdfs.nn.core_site['fs.trash.interval'] ?= '10080'
      ryba.hdfs.nn.site ?= {}
      ryba.hdfs.nn.site['dfs.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # throw Error "Missing \"ryba.zkfc_password\" property" unless ryba.zkfc_password
      # Data
      # Comma separated list of paths. Use the list of directories.
      # For example, /data/1/hdfs/nn,/data/2/hdfs/nn.
      ryba.hdfs.nn.site['dfs.namenode.name.dir'] ?= ['file:///var/hdfs/name']
      ryba.hdfs.nn.site['dfs.namenode.name.dir'] = ryba.hdfs.nn.site['dfs.namenode.name.dir'].join ',' if Array.isArray ryba.hdfs.nn.site['dfs.namenode.name.dir']
      # Network
      ryba.hdfs.nn.site['dfs.hosts'] ?= "#{ryba.hdfs.nn.conf_dir}/dfs.include"
      ryba.hdfs.include ?= @hosts_with_module 'ryba/hadoop/hdfs_dn'
      ryba.hdfs.include = string.lines ryba.hdfs.include if typeof ryba.hdfs.include is 'string'
      ryba.hdfs.nn.site['dfs.hosts.exclude'] ?= "#{ryba.hdfs.nn.conf_dir}/dfs.exclude"
      ryba.hdfs.exclude ?= []
      ryba.hdfs.exclude = string.lines ryba.hdfs.exclude if typeof ryba.hdfs.exclude is 'string'
      ryba.hdfs.nn.heapsize ?= '1024m'
      ryba.hdfs.nn.newsize ?= '200m'
      ryba.hdfs.namenode_opts ?= ''
      ryba.hdfs.nn.site['fs.permissions.umask-mode'] ?= '027' # 0750
      # If "true", access tokens are used as capabilities
      # for accessing datanodes. If "false", no access tokens are checked on
      # accessing datanodes.
      ryba.hdfs.nn.site['dfs.block.access.token.enable'] ?= if ryba.core_site['hadoop.security.authentication'] is 'kerberos' then 'true' else 'false'
      ryba.hdfs.nn.site['dfs.block.local-path-access.user'] ?= ''
      # Kerberos
      ryba.hdfs.nn.site['dfs.namenode.kerberos.principal'] ?= "nn/_HOST@#{ryba.realm}"
      ryba.hdfs.nn.site['dfs.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      ryba.hdfs.nn.site['dfs.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{ryba.realm}"
      ryba.hdfs.nn.site['dfs.namenode.kerberos.https.principal'] = "HTTP/_HOST@#{ryba.realm}"
      ryba.hdfs.nn.site['dfs.web.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{ryba.realm}"
      ryba.hdfs.nn.site['dfs.web.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      # Fix HDP Companion File bug
      ryba.hdfs.nn.site['dfs.https.namenode.https-address'] = null
      # Activate ACLs
      ryba.hdfs.nn.site['dfs.namenode.acls.enabled'] ?= 'true'
      ryba.hdfs.nn.site['dfs.namenode.accesstime.precision'] ?= null

## Configuration for HDFS High Availability (HA)

Add High Availability specific properties to the "hdfs-site.xml" file. The
inserted properties are similar than the ones for a client or slave
configuration with the additionnal "dfs.namenode.shared.edits.dir" property.

The default configuration implement the "sshfence" fencing method. This method
SSHes to the target node and uses fuser to kill the process listening on the
service's TCP port.

      if nn_ctxs.length is 1
        ryba.hdfs.nn.site['dfs.ha.automatic-failover.enabled'] ?= 'false'
        ryba.hdfs.nn.site['dfs.namenode.http-address'] ?= '0.0.0.0:50070'
        ryba.hdfs.nn.site['dfs.namenode.https-address'] ?= '0.0.0.0:50470'
      else
        # HDFS HA configuration
        for nn_ctx in nn_ctxs
          nn_ctx.config.shortname ?= nn_ctx.config.host.split('.')[0]
        for jn_ctx in jn_ctxs
          ryba.hdfs.nn.site['dfs.journalnode.kerberos.principal'] ?= jn_ctx.config.ryba.hdfs.site['dfs.journalnode.kerberos.principal']
        ryba.hdfs.nn.site['dfs.nameservices'] = ryba.nameservice

Since [HDFS-6376](https://issues.apache.org/jira/browse/HDFS-6376), 
Nameservice must be explicitely set as internal to provide other nameservices, 
for distcp purpose.

        ryba.hdfs.nn.site['dfs.internal.nameservices'] ?= ryba.nameservice
        ryba.hdfs.nn.site["dfs.ha.namenodes.#{ryba.nameservice}"] = (for nn_ctx in nn_ctxs then nn_ctx.config.shortname).join ','
        for nn_ctx in nn_ctxs
          ryba.hdfs.nn.site['dfs.namenode.http-address'] = null
          ryba.hdfs.nn.site['dfs.namenode.https-address'] = null
          ryba.hdfs.nn.site["dfs.namenode.rpc-address.#{ryba.nameservice}.#{nn_ctx.config.shortname}"] ?= "#{nn_ctx.config.host}:8020"
          ryba.hdfs.nn.site["dfs.namenode.http-address.#{ryba.nameservice}.#{nn_ctx.config.shortname}"] ?= "#{nn_ctx.config.host}:50070"
          ryba.hdfs.nn.site["dfs.namenode.https-address.#{ryba.nameservice}.#{nn_ctx.config.shortname}"] ?= "#{nn_ctx.config.host}:50470"
        ryba.hdfs.nn.site["dfs.client.failover.proxy.provider.#{ryba.nameservice}"] ?= 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
        ryba.hdfs.nn.site['dfs.ha.automatic-failover.enabled'] ?= 'true'
        ryba.hdfs.nn.site['dfs.namenode.shared.edits.dir'] = (for jn_ctx in jn_ctxs then "#{jn_ctx.config.host}:8485").join ';'
        ryba.hdfs.nn.site['dfs.namenode.shared.edits.dir'] = "qjournal://#{ryba.hdfs.nn.site['dfs.namenode.shared.edits.dir']}/#{ryba.hdfs.nn.site['dfs.nameservices']}"
        # Fencing
        ryba.hdfs.nn.site['dfs.ha.fencing.methods'] ?= "sshfence(#{ryba.hdfs.user.name})"
        ryba.hdfs.nn.site['dfs.ha.fencing.ssh.private-key-files'] ?= "#{ryba.hdfs.user.home}/.ssh/id_rsa"
      hdfs_ctxs = @contexts ['ryba/hadoop/hdfs_dn', 'ryba/hadoop/hdfs_snn', 'ryba/hadoop/httpfs']
      for hdfs_ctx in hdfs_ctxs
        hdfs_ctx.config ?= {}
        hdfs_ctx.config.ryba.hdfs ?= {}
        hdfs_ctx.config.ryba.hdfs.site ?= {}
        hdfs_ctx.config.ryba.hdfs.site['dfs.http.policy'] ?= @config.ryba.hdfs.nn.site['dfs.http.policy']

## Configuration for Log4J

      ryba.hdfs.log4j ?= {}
      ryba.hdfs.log4j[k] ?= v for k, v of @config.log4j
      ryba.hdfs.log4j.extra_appender = "socket_client" if ryba.hdfs.log4j.remote_host? && ryba.hdfs.log4j.remote_port?

## Export configuration

      for dn_ctx in dn_ctxs
        dn_ctx.config ?= {}
        dn_ctx.config.ryba.hdfs ?= {}
        dn_ctx.config.ryba.hdfs.site ?= {}
        dn_ctx.config.ryba.hdfs.site['fs.permissions.umask-mode'] ?= ryba.hdfs.nn.site['fs.permissions.umask-mode']
        dn_ctx.config.ryba.hdfs.site['dfs.block.access.token.enable'] ?= ryba.hdfs.nn.site['dfs.block.access.token.enable']

    module.exports.client_config = (ctx) ->
      {ryba} = @config
      # Import properties from NameNode
      [nn_ctx] = @contexts 'ryba/hadoop/hdfs_nn'
      require('../core/configure').handler.call nn_ctx
      module.exports.handler.call nn_ctx
      properties = [
        'dfs.namenode.kerberos.principal'
        'dfs.namenode.kerberos.internal.spnego.principal'
        'dfs.namenode.kerberos.https.principal'
        'dfs.web.authentication.kerberos.principal'
        'dfs.ha.automatic-failover.enabled'
        'dfs.nameservices'
        'dfs.internal.nameservices'
      ]
      for property in properties
        ryba.hdfs.site[property] ?= nn_ctx.config.ryba.hdfs.nn.site[property]
      for property of nn_ctx.config.ryba.hdfs.nn.site
        ok = false
        ok = true if /^dfs\.namenode\.\w+-address/.test property
        ok = true if property.indexOf('dfs.client.failover.proxy.provider.') is 0
        ok = true if property.indexOf('dfs.ha.namenodes.') is 0
        continue unless ok
        ryba.hdfs.site[property] ?= nn_ctx.config.ryba.hdfs.nn.site[property]

## Dependencies

    string = require 'mecano/lib/misc/string'
