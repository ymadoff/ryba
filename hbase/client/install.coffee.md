
# HBase Client Install

Install the HBase client package and configure it with secured access.

    module.exports =  header: 'HBase Client Install', handler: ->
      {hbase} = @config.ryba

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'
      @register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Users & Groups

By default, the "hbase" package create the following entries:

```bash
cat /etc/passwd | grep hbase
hbase:x:492:492:HBase:/var/run/hbase:/bin/bash
cat /etc/group | grep hbase
hbase:x:492:
``` 

      @group hbase.group
      @user hbase.user

## Packages

      @service
        name: 'hbase'
      @hdp_select
        name: 'hbase-client'

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

      @file.jaas
        timeout: -1
        header: 'Zookeeper JAAS'
        target: "#{hbase.conf_dir}/hbase-client.jaas"
        content: Client:
          useTicketCache: 'true'
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o644

## Configure

Note, we left the permission mode as default, Master and RegionServer need to

      @hconfigure
        header: 'HBase Client Site'
        target: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase-site.xml"
        local_default: true
        properties: hbase.site
        mode: 0o0644
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true

# Opts

Environment passed to the Master before it starts.

      @render
        header: 'HBase Client Env'
        target: "#{hbase.conf_dir}/hbase-env.sh"
        source: "#{__dirname}/../resources/hbase-env.sh.j2"
        context: @config
        uid: hbase.user.name
        gid: hbase.group.name
        local_source: true
        eof: true
        # Fix mapreduce looking for "mapreduce.tar.gz"
        write: [
          match: /^export HBASE_OPTS=\"(.*)\$\{HBASE_OPTS\} -Djava.security.auth.login.config(.*)$/m
          replace: "export HBASE_OPTS=\"${HBASE_OPTS} -Dhdp.version=$HDP_VERSION -Djava.security.auth.login.config=#{hbase.conf_dir}/hbase-client.jaas\" # HDP VERSION FIX RYBA, HBASE CLIENT ONLY"
          append: true
        ]
