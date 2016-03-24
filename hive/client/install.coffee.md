
# Hive & HCatalog Client

    module.exports = header: 'Hive Client Install', handler: ->
      {hive, hadoop_group} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir} = @config.ryba
      tmp_location = "/var/tmp/ryba/ssl"

## Service
      
      @service
        name: 'hive'
      @hdp_select
        name: 'hive-webhcat'
      @service
        name: 'hive-hcatalog'

## Configure

See [Hive/HCatalog Configuration Files](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap6-3.html)

      @hconfigure
        header: 'Hive Site'
        destination: "#{hive.conf_dir}/hive-site.xml"
        default: "#{__dirname}/../../resources/hive/hive-site.xml"
        local_default: true
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

      @write
        header: 'Hive Env'
        destination: "#{hive.conf_dir}/hive-env.sh"
        replace: """
        if [ "$SERVICE" = "cli" ]; then
          # export HADOOP_CLIENT_OPTS="-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=130.98.196.54 -Dcom.sun.management.jmxremote.rmi.port=9526 -Dcom.sun.management.jmxremote.port=9526 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false  $HADOOP_CLIENT_OPTS"
          export HADOOP_HEAPSIZE="#{hive.client.heapsize}"
          export HADOOP_CLIENT_OPTS="-Xmx${HADOOP_HEAPSIZE}m #{hive.client.opts} $HADOOP_CLIENT_OPTS"
        fi
        """
        from: '# RYBA HIVE CLIENT START'
        to: '# RYBA HIVE CLIENT END'
        append: true
        eof: true
        backup: true

## SSL

      @call header: 'Client SSL', handler: ->
        @upload
          source: ssl.cacert
          destination: "#{tmp_location}/#{path.basename ssl.cacert}"
          mode: 0o0600
          shy: true
        @java_keystore_add
          keystore: hive.client.truststore_location
          storepass: hive.client.truststore_password
          caname: "hive_root_ca"
          cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
        @remove
          destination: "#{tmp_location}/#{path.basename ssl.cacert}"
          shy: true
      
## Dependencies

    path = require 'path'
  
