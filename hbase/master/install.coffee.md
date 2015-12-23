
# HBase Master Install

TODO: [HBase backup node](http://willddy.github.io/2013/07/02/HBase-Add-Backup-Master-Node.html)

    module.exports =  header: 'HBase Master Install', handler: ->
      {hadoop_group, hbase, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]

## IPTables

| Service             | Port  | Proto | Info                   |
|---------------------|-------|-------|------------------------|
| HBase Master        | 60000 | http  | hbase.master.port      |
| HMaster Info Web UI | 60010 | http  | hbase.master.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'HBase Master # IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.master.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.master.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Service

Install the "hbase-master" service, symlink the rc.d startup script inside
"/etc/init.d" and activate it on startup.

      @call header: 'HBase Master # Service', timeout: -1, handler: ->
        @service
          name: 'hbase-master'
        @hdp_select
          name: 'hbase-client'
        @hdp_select
          name: 'hbase-master'
        @write
          source: "#{__dirname}/../resources/hbase-master"
          local_source: true
          destination: '/etc/init.d/hbase-master'
          mode: 0o0755
          unlink: true
        @service_restart
          name: 'hbase-master'
          if: -> @status -4

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2

      mode = if @has_module 'ryba/hbase/client' then 0o0644 else 0o0600
      @hconfigure
        header: 'HBase Master # Configure'
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        mode: mode # See slide 33 from [Operator's Guide][secop]
        backup: true

# Opts

Environment passed to the Master before it starts.

      @call header: 'HBase Master # Opts', handler: ->
        @write
          destination: "#{hbase.conf_dir}/hbase-env.sh"
          match: /^export HBASE_MASTER_OPTS="(.*)" # RYBA(.*)$/m
          replace: "export HBASE_MASTER_OPTS=\"#{hbase.master_opts} ${HBASE_MASTER_OPTS}\" # RYBA CONF \"ryba.hbase.master_opts\", DONT OVERWRITE"
          before: /^export HBASE_MASTER_OPTS=".*"$/m
          backup: true
        #  match: /^export HBASE_ROOT_LOGGER=.*$/mg
        #  replace: "export HBASE_ROOT_LOGGER=#{hbase.master.log4j.root_logger}"
        #  append: true
        #  match: /^export HBASE_SECURITY_LOGGER=.*$/mg
        #  replace: "export HBASE_SECURITY_LOGGER=#{hbase.master.log4j.security_logger}"
        #  append: true

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

Environment file is enriched by "ryba/hbase" # HBase # Env".

      @call header: 'HBase Master # Zookeeper JAAS', timeout: -1, handler: ->
        @write_jaas
          destination: "#{hbase.conf_dir}/hbase-master.jaas"
          content: Client:
            principal: hbase.site['hbase.master.kerberos.principal'].replace '_HOST', @config.host
            keyTab: hbase.site['hbase.master.keytab.file']
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o700

## Kerberos

https://blogs.apache.org/hbase/entry/hbase_cell_security
https://hbase.apache.org/book/security.html

      @call header: 'HBase Master # Kerberos', handler: ->
        @krb5_addprinc
          principal: hbase.site['hbase.master.kerberos.principal'].replace '_HOST', @config.host
          randkey: true
          keytab: hbase.site['hbase.master.keytab.file']
          uid: hbase.user.name
          gid: hadoop_group.name
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server

      @call header: 'HBase Master # Kerberos Admin', handler: ->
        @krb5_addprinc
          principal: hbase.admin.principal
          password: hbase.admin.password
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server

      @call header: 'HBase Master # Log4J', handler: ->
        @write
          destination: "#{hbase.conf_dir}/log4j.properties"
          source: "#{__dirname}/../resources/log4j.properties"
          local_source: true

## Metrics

Enable stats collection in Ganglia and Graphite

      @call header: 'HBase Master # Metrics', handler: ->
        content = ""
        for k, v of hbase.metrics
          content += "#{k}=#{v}\n" if v?
        @write
          destination: "#{hbase.conf_dir}/hadoop-metrics2-hbase.properties"
          content: content
          backup: true

      # @call header: 'HBase Master # SSL', retry: 0, handler: ->
      #   {ssl, ssl_server, ssl_client, hdfs} = @config.ryba
      #   ssl_client['ssl.client.truststore.location'] = "#{hbase.conf_dir}/truststore"
      #   ssl_server['ssl.server.keystore.location'] = "#{hbase.conf_dir}/keystore"
      #   ssl_server['ssl.server.truststore.location'] = "#{hbase.conf_dir}/truststore"
      #   @hconfigure
      #     destination: "#{hbase.conf_dir}/ssl-server.xml"
      #     properties: ssl_server
      #   @hconfigure
      #     destination: "#{hbase.conf_dir}/ssl-client.xml"
      #     properties: ssl_client
      #   # Client: import certificate to all hosts
      #   @java_keystore_add
      #     keystore: ssl_client['ssl.client.truststore.location']
      #     storepass: ssl_client['ssl.client.truststore.password']
      #     caname: "hadoop_root_ca"
      #     cacert: "#{ssl.cacert}"
      #     local_source: true
      #   # Server: import certificates, private and public keys to hosts with a server
      #   @java_keystore_add
      #     keystore: ssl_server['ssl.server.keystore.location']
      #     storepass: ssl_server['ssl.server.keystore.password']
      #     caname: "hadoop_root_ca"
      #     cacert: "#{ssl.cacert}"
      #     key: "#{ssl.key}"
      #     cert: "#{ssl.cert}"
      #     keypass: ssl_server['ssl.server.keystore.keypassword']
      #     name: @config.shortname
      #     local_source: true
      #   @java_keystore_add
      #     keystore: ssl_server['ssl.server.keystore.location']
      #     storepass: ssl_server['ssl.server.keystore.password']
      #     caname: "hadoop_root_ca"
      #     cacert: "#{ssl.cacert}"
      #     local_source: true

## SPNEGO

Ensure we have read access to the spnego keytab soring the server HTTP
principal.

      @call header: 'HBase RegionServer # SPNEGO', handler: ->
        @execute
          cmd: "su -l #{hbase.user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"

## HBase Cluster Replication

Deploy HBase replication to point slave cluster.
This module can be runned on one node, so it is runned on the first hbase-master.

      @call header: 'HBase Client # Replication', if: @hosts_with_module('ryba/hbase/master')[0] == @config.host, handler: ->
        {hbase} = @config.ryba
        for k, cluster of hbase.replicated_clusters
          peer_key = parseInt(k) + 1
          peer_value = "#{cluster.zookeeper_quorum}:#{cluster.zookeeper_port}:#{cluster.zookeeper_node}"
          if cluster.zookeeper_node != hbase.site['zookeeper.znode.parent']
            msg_err = "Slave Cluster must have same zookeeper hbase node: #{cluster.zookeeper_node} instead of #{hbase.site['zookeeper.znode.parent']}"
            throw new Error msg_err
          else
            @execute
              cmd: mkcmd.hbase @, """
              hbase shell -n 2>/dev/null <<-CMD
                add_peer '#{peer_key}', '#{peer_value}'
              CMD
              """
              unless_exec: mkcmd.hbase @, "hbase shell 2>/dev/null <<< \"list_peers\" | grep '#{peer_key} #{peer_value} ENABLED'"

# Module dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'
