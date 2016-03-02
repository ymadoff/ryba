

# HBase Install

Install the HBase Packages, create users and groups, and set up commons configuration

    module.exports =  header: 'HBase Install', handler: ->
      {hbase} = @config.ryba
      
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

## Service

Instructions to [install the HBase RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap9-1.html)

      @call header: 'Service', timeout: -1, handler: ->
        @service
          name: 'hbase'
        @hdp_select
          name: 'hbase-client'

## Common Configuration

      @call header: 'Configure', handler: ->
        write = for k, v of hbase.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
        # Fix mapreduce looking for "mapreduce.tar.gz"
        write.push
          match: /^export HBASE_OPTS=".*" # RYBA HDP VERSION$/m
          replace: "export HBASE_OPTS=\"-Dhdp.version=$HDP_VERSION $HBASE_OPTS\" # RYBA HDP VERSION"
          append: true
        @render
          header: 'Env'
          source: "#{__dirname}/../resources/hbase-env.sh"
          destination: "#{hbase.conf_dir}/hbase-env.sh"
          write: write
          local_source: true
          context: @config
          mode: 0o0755
          uid: hbase.user.name
          gid: hbase.group.name
          unlink: true
          backup: true
          eof: true
        @hconfigure
          header: 'Site'
          destination: "#{hbase.conf_dir}/hbase-site.xml"
          default: "#{__dirname}/../resources/hbase-site.xml"
          local_default: true
          properties: hbase.site
          merge: false
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0644 # See slide 33 from [Operator's Guide][secop]
          backup: true
