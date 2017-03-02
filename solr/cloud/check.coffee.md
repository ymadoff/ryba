
# Solr Install

    module.exports = header: 'Solr Cloud Check', handler: ->
      {solr, realm, force_check} = @config.ryba
      shards = (@contexts 'ryba/solr/cloud').length
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      protocol = if solr.cloud.ssl.enabled then 'https' else 'http'

      @call 'ryba/zookeeper/server/wait'
      @call 'ryba/solr/cloud/wait'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## Create Collection with HDFS based index
This check is inspired [from HDP][search-hdp].
TODO: April 2016: hadoop connector not taking in count -zk params.
Check if hadoop connector works and re-activate jar execution.

      @call header: 'Create Collection (HDFS)', if: solr.cloud.hdfs?, handler: ->
        collection = check_dir = "ryba-check-solr-hdfs-#{@config.shortname}"
        @system.execute
          if: force_check
          cmd: mkcmd.solr, """
            rm -rf /tmp/#{check_dir} || true
            #{solr.cloud.latest_dir}/bin/solr delete -c #{collection} || true
            hadoop fs -rm  -r /user/#{solr.user.name}/csv || true
            zookeeper-client -server #{solr.cloud.zk_connect} rmr #{solr.cloud.zk_node}/configs/#{collection}
          """
        @call 
          unless_exec:unless force_check then "test -f /tmp/#{check_dir}/checked"
          handler: ->
            @system.execute
              cmd: "cp -R #{solr.cloud.latest_dir}/server/solr/configsets/data_driven_schema_configs /tmp/#{check_dir}"
            @file.render
              header: 'Solrconfig'
              source: "#{__dirname}/../resources/cloud/solrconfig.xml.j2"
              target: "/tmp/#{check_dir}/solrconfig.xml"
              local: true
              context: @config.ryba
              eof: true
            @system.execute
              cmd: """
                #{solr.cloud.latest_dir}/bin/solr create_collection -c #{collection} \
                -d /tmp/#{check_dir} -shards #{shards}
              """
              unless_exec: "#{solr.cloud.latest_dir}/bin/solr healthcheck -c #{collection} -z #{solr.cloud.zk_connect}#{solr.cloud.zk_node} | grep '\"status\":\"healthy\"'"
            @system.execute
              if: false
              cmd: mkcmd.solr, """
                set -e
                hadoop fs -mkdir -p /user/#{solr.user.name}/csv
                hadoop fs -put #{solr.cloud.latest_dir}/example/exampledocs/books.csv /user/#{solr.user.name}/csv/
                hadoop jar #{path.dirname solr.cloud.latest_dir}/job/lucidworks-hadoop-job-2.0.3.jar \
                com.lucidworks.hadoop.ingest.IngestJob \
                -DcsvFieldMapping=0=id,1=cat,2=name,3=price,4=instock,5=author \
                -DcsvFirstLineComment -DidField=id -DcsvDelimiter="," \
                -Dlww.commit.on.close=true -cls com.lucidworks.hadoop.ingest.CSVIngestMapper \
                -c #{collection} -i /user/#{solr.user.name}/csv/* -of com.lucidworks.hadoop.io.LWMapRedOutputFormat -zk #{solr.cloud.zk_connect}#{solr.cloud.zk_node}
              """
            @system.execute
              if: -> @status -2
              cmd: """
                touch /tmp/#{check_dir}/checked
              """



## Create Collection with Local dir based index
This check is inspired [from HDP][search-hdp].

      @call header: 'Create Collection (Local)', handler: ->
        collection = check_dir = "ryba-check-solr-local-#{@config.shortname}"
        solr.cloud.dir_factory = solr.user.home
        solr.cloud.lock_type = 'native'
        @system.execute
          if: force_check
          cmd: mkcmd.solr, """
            rm -rf /tmp/#{check_dir} || true
            #{solr.cloud.latest_dir}/bin/solr delete -c #{collection} || true
            zookeeper-client -server #{solr.cloud.zk_connect} rmr #{solr.cloud.zk_node}/configs/#{collection} 2&>1 || true
          """
        @call 
          unless_exec: unless force_check then "test -f /tmp/#{check_dir}/checked"
          handler: ->
            @system.execute
              cmd: "cp -R #{solr.cloud.latest_dir}/server/solr/configsets/data_driven_schema_configs /tmp/#{check_dir}"
            @file.render
              header: 'Solrconfig'
              source: "#{__dirname}/../resources/cloud/solrconfig.xml.j2"
              target: "/tmp/#{check_dir}/solrconfig.xml"
              local: true
              context: @config.ryba   
              eof: true
            @system.execute
              cmd: """
                #{solr.cloud.latest_dir}/bin/solr create_collection -c #{collection} \
                -d /tmp/#{check_dir} -shards #{shards}
              """
              unless_exec: "#{solr.cloud.latest_dir}/bin/solr healthcheck -c #{collection} -z #{solr.cloud.zk_connect}#{solr.cloud.zk_node} | grep '\"status\":\"healthy\"'"
            @system.execute
              if: -> @status -1
              cmd: """
                touch /tmp/#{check_dir}/checked
              """          

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    path = require 'path'

[search-hdp]:(http://fr.hortonworks.com/hadoop-tutorial/searching-data-solr/)
