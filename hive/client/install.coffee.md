
# Hive & HCatalog Client

    module.exports = header: 'Hive Client Install', handler: ->
      {hive, hadoop_group} = @config.ryba
      {java_home} =@config.java
      {ssl, ssl_server, ssl_client, hadoop_conf_dir} = @config.ryba
      tmp_location = "/var/tmp/ryba/ssl"

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Users & Groups

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep hive
hive:x:493:493:Hive:/var/lib/hive:/sbin/nologin
cat /etc/group | grep hive
hive:x:493:
```

      @system.group hive.group
      @system.user hive.user

## Service

The phoenix server jar is reference inside the HIVE_AUX_JARS_PATH if phoenix
is installed on the host.

      @service
        name: 'phoenix'
        if: @has_service 'ryba/phoenix/client'
      @service 'hive'
      @service 'hive-webhcat' # Install hcat command
      @hdp_select 'hive-webhcat'
      # @service
      #   name: 'hive-hcatalog'

## Configure

See [Hive/HCatalog Configuration Files](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap6-3.html)

      @hconfigure
        header: 'Hive Site'
        target: "#{hive.conf_dir}/hive-site.xml"
        source: "#{__dirname}/../../resources/hive/hive-site.xml"
        local_source: true
        properties: hive.site
        merge: true
        backup: true
      @execute
        header: 'Permissions'
        cmd: """
        chown -R #{hive.user.name}:#{hadoop_group.name} #{hive.conf_dir}
        chmod -R 755 #{hive.conf_dir}
        """
        shy: true # TODO: indempotence by detecting ownerships and permissions 

## Env

Enrich the "hive-env.sh" file with the value of the configuration properties
"ryba.hive.client.opts" and "ryba.hive.client.heapsize". Internally, the
environmental variables "HADOOP_CLIENT_OPTS" and "HADOOP_HEAPSIZE" are enriched
and they only apply to the Hive HCatalog server.

Using this functionnality, a user may for example raise the heap size of Hive
Client to 4Gb by either setting a "opts" value equal to "-Xmx4096m" or the 
by setting a "heapsize" value equal to "4096".

      @file.render
        header: 'Hive Env'
        source: "#{__dirname}/../resources/hive-env.sh.j2"
        target: "#{hive.conf_dir}/hive-env.sh"
        local_source: true
        context: @config
        eof: true
        backup: true

## SSL

      @java_keystore_add
        header: 'Client SSL'
        keystore: hive.client.truststore_location
        storepass: hive.client.truststore_password
        caname: "hive_root_ca"
        cacert: ssl.cacert
        local_source: true

## Dependencies

    path = require 'path'
