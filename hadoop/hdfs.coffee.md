
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
  
*   `hdfs.ha_client_config` (object)   
    Properities added to the "hdfs-site.xml" file specific to the High Availability mode. There
    are defined in a seperate configuration key then "hdp.hdfs.site" to hide them from being 
    visible on a client setup.   
*   `hdfs.hadoop_policy`    
*   `hdfs.hdfs.namenode_timeout`   
*   `hdfs.hdfs.site` (object)   
    Properities added to the "hdfs-site.xml" file.
*   `hdfs.nameservice`   
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

    module.exports.push module.exports.configure = (ctx) ->
      # return if ctx.hdfs_configured
      # ctx.hdfs_configured = true
      require('./core').configure ctx
      # require('./core_ssl').configure ctx
      {nameservice, core_site, static_host, realm} = ctx.config.ryba
      throw new Error "Missing value for 'hdfs.krb5_user.password'" unless ctx.config.ryba.hdfs.krb5_user.password?
      throw new Error "Missing value for 'test_password'" unless ctx.config.ryba.test_password?
      # Options and configuration
      hdfs = ctx.config.ryba.hdfs ?= {}
      ctx.config.ryba.hdfs.namenode_timeout ?= 20000 # 20s
      # Options for "hdfs-site.xml"
      hdfs.site ?= {}
      hdfs.site['dfs.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # REPLACED by "dfs.namenode.https-address": hdfs.site['dfs.https.port'] ?= '50470' # The https port where NameNode binds
      # Comma separated list of paths. Use the list of directories from $DFS_NAME_DIR.
      # For example, /grid/hadoop/hdfs/nn,/grid1/hadoop/hdfs/nn.
      hdfs.site['dfs.namenode.name.dir'] ?= ['/var/hdfs/name']
      hdfs.site['dfs.namenode.name.dir'] = hdfs.site['dfs.namenode.name.dir'].join ',' if Array.isArray hdfs.site['dfs.namenode.name.dir']
      # Comma separated list of paths. Use the list of directories from $DFS_DATA_DIR.  
      # For example, /grid/hadoop/hdfs/dn,/grid1/hadoop/hdfs/dn.
      hdfs.site['dfs.datanode.data.dir'] ?= ['/var/hdfs/data']
      hdfs.site['dfs.datanode.data.dir'] = hdfs.site['dfs.datanode.data.dir'].join ',' if Array.isArray hdfs.site['dfs.datanode.data.dir']
      # ctx.config.ryba.hdfs.site['dfs.datanode.data.dir.perm'] ?= '750'
      hdfs.site['dfs.datanode.data.dir.perm'] ?= '700'
      hdfs.site['fs.permissions.umask-mode'] ?= '027' # 0750
      if core_site['hadoop.security.authentication'] is 'kerberos'
        # Default values are retrieved from the official HDFS page called
        # ["SecureMode"][hdfs_secure].
        # Ports must be below 1024, because this provides part of the security
        # mechanism to make it impossible for a user to run a map task which
        # impersonates a DataNode
        # TODO: Move this to 'ryba/hadoop/hdfs_dn'
        hdfs.site['dfs.datanode.address'] ?= '0.0.0.0:1004'
        hdfs.site['dfs.datanode.ipc.address'] ?= '0.0.0.0:50020'
        hdfs.site['dfs.datanode.http.address'] ?= '0.0.0.0:1006' 
        hdfs.site['dfs.datanode.https.address'] ?= '0.0.0.0:50475'
      else
        hdfs.site['dfs.datanode.address'] ?= '0.0.0.0:50010'
        hdfs.site['dfs.datanode.ipc.address'] ?= '0.0.0.0:50020'
        hdfs.site['dfs.datanode.http.address'] ?= '0.0.0.0:50075' 
        hdfs.site['dfs.datanode.https.address'] ?= '0.0.0.0:50475'
      # Options for "hadoop-policy.xml"
      ctx.config.ryba.hadoop_policy ?= {}
      # HDFS SNN
      if secondary_namenode = ctx.host_with_module 'ryba/hadoop/hdfs_snn'
        hdfs.site['dfs.namenode.secondary.http-address'] ?= "#{secondary_namenode}:50090"
      unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
        hdfs.site['dfs.namenode.http-address'] ?= '0.0.0.0:50070'
        hdfs.site['dfs.namenode.https-address'] ?= '0.0.0.0:50470'
      else
        # HDFS HA configuration
        namenodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
        ctx.config.ryba.shortname ?= ctx.config.shortname
        ctx.config.ryba.ha_client_config = {}
        ctx.config.ryba.ha_client_config['dfs.nameservices'] = nameservice
        ctx.config.ryba.ha_client_config["dfs.ha.namenodes.#{nameservice}"] = (for nn in namenodes then nn.split('.')[0]).join ','
        for nn in namenodes
          hdfs.site['dfs.namenode.http-address'] = null
          hdfs.site['dfs.namenode.https-address'] = null
          hconfig = ctx.hosts[nn].config
          shortname = hconfig.ryba.shortname ?= hconfig.shortname or nn.split('.')[0]
          ctx.config.ryba.ha_client_config["dfs.namenode.rpc-address.#{nameservice}.#{shortname}"] ?= "#{nn}:8020"
          ctx.config.ryba.ha_client_config["dfs.namenode.http-address.#{nameservice}.#{shortname}"] ?= "#{nn}:50070"
          ctx.config.ryba.ha_client_config["dfs.namenode.https-address.#{nameservice}.#{shortname}"] ?= "#{nn}:50470"
        ctx.config.ryba.ha_client_config["dfs.client.failover.proxy.provider.#{nameservice}"] ?= 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
        # Temp fix, ha_client_config should disapear
        for k, v of ctx.config.ryba.ha_client_config
          hdfs.site[k] = v
      # Fix HDP Companion File bug
      hdfs.site['dfs.https.namenode.https-address'] = null

## Configurion for Kerberos

Update the HDFS configuration stored inside the "/etc/hadoop/hdfs-site.xml" file
with Kerberos specific properties.

      # If "true", access tokens are used as capabilities
      # for accessing datanodes. If "false", no access tokens are checked on
      # accessing datanodes.
      hdfs.site['dfs.block.access.token.enable'] ?= 'true'
      # Kerberos principal name for the NameNode
      hdfs.site['dfs.namenode.kerberos.principal'] ?= "nn/#{static_host}@#{realm}"
      # The HTTP Kerberos principal used by Hadoop-Auth in the HTTP 
      # endpoint. The HTTP Kerberos principal MUST start with 'HTTP/' 
      # per Kerberos HTTP SPNEGO specification. 
      hdfs.site['dfs.web.authentication.kerberos.principal'] ?= "HTTP/#{static_host}@#{realm}"
      # The Kerberos keytab file with the credentials for the HTTP 
      # Kerberos principal used by Hadoop-Auth in the HTTP endpoint.
      hdfs.site['dfs.web.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      # The Kerberos principal that the DataNode runs as. "_HOST" is replaced by the real host name.  
      hdfs.site['dfs.datanode.kerberos.principal'] ?= "dn/#{static_host}@#{realm}"
      # Combined keytab file containing the NameNode service and host principals.
      hdfs.site['dfs.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      # The filename of the keytab file for the DataNode.
      hdfs.site['dfs.datanode.keytab.file'] ?= '/etc/security/keytabs/dn.service.keytab'
      # # Default to ${dfs.web.authentication.kerberos.principal}, but documented in hdp 1.3.2 manual install
      hdfs.site['dfs.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/#{static_host}@#{realm}"
      # # Default to ${dfs.web.authentication.kerberos.principal}, but documented in hdp 1.3.2 manual install
      # Documented in http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
      # Only seems to apply if "dfs.https.enable" is enabled
      hdfs.site['dfs.namenode.kerberos.https.principal'] = "HTTP/#{static_host}@#{realm}"

    module.exports.push name: 'Hadoop HDFS # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'hadoop'
      ,
        name: 'hadoop-hdfs'
      ,
        name: 'hadoop-libhdfs'
      ,
        name: 'hadoop-client'
      ,
        name: 'openssl'
      # ,
      #   name: 'bigtop-jsvc'
      ], next

    module.exports.push name: 'HDFS # Hadoop Configuration', timeout: -1, callback: (ctx, next) ->
      {core, hdfs, hadoop_conf_dir} = ctx.config.ryba
      datanodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_dn'
      modified = false
      do_hdfs = ->
        ctx.log 'Configure hdfs-site.xml'
        # Fix: the "dfs.cluster.administrators" value has a space inside
        hdfs.site['dfs.cluster.administrators'] = 'hdfs'
        # NameNode hostname for http access.
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/hdfs-site.xml"
          default: "#{__dirname}/../resources/core_hadoop/hdfs-site.xml"
          local_default: true
          properties: hdfs.site
          merge: true
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_master()
      do_master = ->
        # Accoring to [Yahoo!](http://developer.yahoo.com/hadoop/tutorial/module7.html):
        # The conf/masters file contains the hostname of the
        # SecondaryNameNode. This should be changed from "localhost"
        # to the fully-qualified domain name of the node to run the
        # SecondaryNameNode service. It does not need to contain
        # the hostname of the JobTracker/NameNode machine; 
        # Also some [interesting info about snn](http://blog.cloudera.com/blog/2009/02/multi-host-secondarynamenode-configuration/)
        ctx.log 'Configure masters'
        secondary_namenode = ctx.host_with_module 'ryba/hadoop/hdfs_snn'
        return do_slaves() unless secondary_namenode
        ctx.write
          content: "#{secondary_namenode}"
          destination: "#{hadoop_conf_dir}/masters"
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_slaves()
      do_slaves = ->
        # The conf/slaves file should contain the hostname of every machine
        # in the cluster which should start TaskTracker and DataNode daemons
        ctx.log 'Configure slaves'
        ctx.write
          content: "#{datanodes.join '\n'}"
          destination: "#{hadoop_conf_dir}/slaves"
          eof: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_end()
      do_end = ->
        next null, modified
      do_hdfs()

## Policy

By default the service-level authorization is disabled in hadoop, to enable that
we need to set/configure the hadoop.security.authorization to true in
${HADOOP_CONF_DIR}/core-site.xml

    module.exports.push name: 'HDFS # Policy', callback: (ctx, next) ->
      {core_site, hadoop_conf_dir, hadoop_policy} = ctx.config.ryba
      return next() unless core_site['hadoop.security.authorization'] is 'true'
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hadoop-policy.xml"
        default: "#{__dirname}/../resources/core_hadoop/hadoop-policy.xml"
        local_default: true
        properties: hadoop_policy
        merge: true
        backup: true
      , next

## Kerberos User

Create the HDFS user principal. This will be the super administrator for the HDFS
filesystem. Note, we do not create a principal with a keytab to allow HDFS login
from multiple sessions with braking an active session.

    module.exports.push name: 'HDFS # Kerberos User', callback: (ctx, next) ->
      {hdfs, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "#{hdfs.user.name}@#{realm}"
        password: hdfs.krb5_user.password
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## SPNEGO

Create the SPNEGO service principal in the form of "HTTP/{host}@{realm}" and place its
keytab inside "/etc/security/keytabs/spnego.service.keytab" with ownerships set to "hdfs:hadoop"
and permissions set to "0660". We had to give read/write permission to the group because the 
same keytab file is for now shared between hdfs and yarn services.

    module.exports.push name: 'HDFS # SPNEGO', callback: module.exports.spnego = (ctx, next) ->
      {hdfs, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "HTTP/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: '/etc/security/keytabs/spnego.service.keytab'
        uid: 'hdfs'
        gid: 'hadoop'
        mode: 0o660 # need rw access for hadoop and mapred users
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        return next err if err
        # Validate keytab access by the hdfs user
        ctx.execute
          cmd: "su -l #{hdfs.user.name} -c \"klist -kt /etc/security/keytabs/spnego.service.keytab\""
        , (err) ->
          next err, created

## Ulimit

Increase ulimit following [Kate Ting's recommandations][kate]. This is a cause 
of error if you receive the message: 'Exception in thread "main" java.lang.OutOfMemoryError: unable to create new native thread'.

The HDP package create the following files:

```bash
cat /etc/security/limits.d/hdfs.conf
hdfs   - nofile 32768
hdfs   - nproc  65536
cat /etc/security/limits.d/mapreduce.conf
mapred    - nofile 32768
mapred    - nproc  65536
cat /etc/security/limits.d/yarn.conf
yarn   - nofile 32768
yarn   - nproc  65536
```

Refer to the "masson/core/security" module for instructions on how to add custom
limit rules.

Also worth of interest are the [Pivotal recommandations][hawq] as well as the
[Greenplum recommandation from Nixus Technologies][greenplum] and the 
[MapR documentation][mapr].

Note, a user must re-login for those changes to be taken into account.

    module.exports.push name: 'HDFS # Ulimit', callback: (ctx, next) ->
      ctx.execute cmd: 'ulimit -Hn', (err, _, stdout) ->
        return next err if err
        max_nofile = stdout.trim()
        ctx.write [
          destination: '/etc/security/limits.d/hdfs.conf'
          write: [
            match: /^hdfs.+nofile.+$/mg
            replace: "hdfs    -    nofile   #{max_nofile}"
            append: true
          ,
            match: /^hdfs.+nproc.+$/mg
            replace: "hdfs    -    nproc    65536"
            append: true
          ]
          backup: true
        ,
          destination: '/etc/security/limits.d/mapreduce.conf'
          write: [
            match: /^mapred.+nofile.+$/mg
            replace: "mapred  -    nofile   #{max_nofile}"
            append: true
          ,
            match: /^mapred.+nproc.+$/mg
            replace: "mapred  -    nproc    65536"
            append: true
          ]
          backup: true
        ,
          destination: '/etc/security/limits.d/yarn.conf'
          write: [
            match: /^yarn.+nofile.+$/mg
            replace: "yarn    -    nofile   #{max_nofile}"
            append: true
          ,
            match: /^yarn.+nproc.+$/mg
            replace: "yarn    -    nproc    65536"
            append: true
          ]
          backup: true
        ], next

## Module dependencies

    url = require 'url'

[hdfs_secure]: http://hadoop.apache.org/docs/r2.4.1/hadoop-project-dist/hadoop-common/SecureMode.html#DataNode
[hawq]: http://docs.gopivotal.com/pivotalhd/InstallingHAWQ.html
[greenplum]: http://nixustechnologies.com/2014/03/31/install-greenplum-community-edition/
[mapr]: http://doc.mapr.com/display/MapR/Preparing+Each+Node
[kate]: http://fr.slideshare.net/cloudera/hadoop-troubleshooting-101-kate-ting-cloudera



