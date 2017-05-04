
# Hive & HCatalog Client

    module.exports = header: 'Hive Client Install', handler: ->
      {hive, hadoop_group} = @config.ryba
      {java_home} =@config.java
      {ssl, ssl_server, ssl_client, hadoop_conf_dir} = @config.ryba
      tmp_location = "/var/tmp/ryba/ssl"

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Service

      @service
        name: 'hive'
      @hdp_select 'hive-webhcat'

## Configure

See [Hive/HCatalog Configuration Files](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap6-3.html)

      @hconfigure
        header: 'Hive Site'
        target: "#{hive.conf_dir}/hive-site.xml"
        source: "#{__dirname}/../../resources/hive/hive-site.xml"
        local: true
        properties: hive.site
        merge: true
        backup: true
      @system.execute
        header: 'Permissions'
        cmd: """
        chown -R #{hive.user.name}:#{hadoop_group.name} #{hive.conf_dir}
        chmod -R 755 #{hive.conf_dir}
        """
        shy: true # TODO: indempotence by detecting ownerships and permissions

## Env

      @file.render
        header: 'Hive Env'
        source: "#{__dirname}/../resources/hive-env.sh.j2"
        target: "#{hive.conf_dir}/hive-env.sh"
        local: true
        context: @config
        eof: true
        backup: true

## SSL

      @java.keystore_add
        header: 'Client SSL'
        keystore: hive.client.truststore_location
        storepass: hive.client.truststore_password
        caname: "hive_root_ca"
        cacert: ssl.cacert
        local: true

## Dependencies

    path = require 'path'
