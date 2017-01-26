
# Altas Metadata Server Start

Apache Atlas Needs the following components to be started.
- HBase
- Hive Server2
- Kafka Brokers
- Ranger Admin
- Solr Cloud

    module.exports = header: 'Atlas Start', timeout: -1, label_true: 'STARTED', handler: ->

Wait for Kerberos, HBase, Hive, Kafka and Ranger.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/hbase/regionserver/wait'
      @call once: true, 'ryba/kafka/broker/wait'
      @call once: true, 'ryba/ranger/admin/wait'

      switch @config.ryba.atlas.solr_type
        when 'cloud_docker'
          @wait_connect
            host: @config.ryba.atlas.cluster_config['master']
            port: @config.ryba.atlas.cluster_config['port']

## Start the service
You can start the service with the following commands.
* Centos/REHL 6
```
  service atlas-metadata-server start
```
* Centos/REHL 6
```
  systemctl start atlas-metadata-server
```
      
      @service.start
        name: 'atlas-metadata-server'
        
        




      
