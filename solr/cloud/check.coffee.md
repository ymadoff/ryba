
# Solr Install

    module.exports = header: 'Solr Cloud Check', handler: ->
      {solr, realm, force_check} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      protocol = if solr.ssl.enabled then 'https' else 'http'
      
      @call 'ryba/zookeeper/server/wait'
      @call 'ryba/solr/cloud/wait'

## Create Collection with HDFS based index
This check is inspired [from HDP][search-hdp].

      @call header: 'Create Collection (HDFS)', if: solr.hdfs? ,handler: ->
        check_dir = "ryba-check-solr-hdfs-#{@config.host}"
        @render
          header: 'Solrconfig'
          source: "#{__dirname}/../resources/solrconfig.xml.j2"
          destination: "/tmp/#{check_dir}/solrconfig.xml"
          local_source: true
          context: @config
          eof: true

## Create Collection with Local dir based index
This check is inspired [from HDP][search-hdp].

      @call header: 'Create Collection (Local)', if: solr.hdfs? ,handler: ->
        check_dir = "ryba-check-solr-local-#{@config.host}"
        @render
          header: 'Solrconfig'
          source: "#{__dirname}/../resources/solrconfig.xml.j2"
          destination: "/tmp/#{check_dir}/solrconfig.xml"
          local_source: true
          context: 
            solr.dir_factory: solr.user.home
            solr.lock_type: 'native'          
          eof: true
        
        
[search-hdp]:(http://fr.hortonworks.com/hadoop-tutorial/searching-data-solr/)
