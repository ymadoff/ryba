
    module.exports = header: 'Ranger Kafka Plugin install', handler: ->
      {ranger, kafka, realm, hadoop_group, core_site} = @config.ryba 
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      version= null
      #https://mail-archives.apache.org/mod_mbox/incubator-ranger-user/201605.mbox/%3C363AE5BD-D796-425B-89C9-D481F6E74BAF@apache.org%3E

# Dependencies

      @call once: true, 'ryba/ranger/admin/wait'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

# Packages

      @call header: 'Packages', handler: ->
        @execute
          header: 'Setup Execution'
          shy:true
          cmd: """
            hdp-select versions | tail -1
          """
         , (err, executed,stdout, stderr) ->
            return  err if err or not executed
            version = stdout.trim() if executed
        @service
          name: "ranger-kafka-plugin"

# Layout

      @system.mkdir
        target: ranger.kafka_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: kafka.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.kafka_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      @system.mkdir
        target: ranger.kafka_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: kafka.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.kafka_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

# HDFS Service Repository creation
Matchs step 1 in [hdfs plugin configuration][hdfs-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        if: @contexts('ryba/kafka/broker')[0].config.host is @config.host 
        header: 'Ranger Kafka Repository'
        handler:  ->
          @execute
            unless_exec: """
              curl --fail -H  \"Content-Type: application/json\"   -k -X GET  \ 
              -u admin:#{password} \"#{ranger.kafka_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{ranger.kafka_plugin.install['REPOSITORY_NAME']}\"
            """
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify ranger.kafka_plugin.service_repo}' \
              -u admin:#{password} \"#{ranger.kafka_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
            """
          @krb5_addprinc krb5,
            if: ranger.kafka_plugin.principal
            header: 'Ranger Kafka Principal'
            principal: ranger.kafka_plugin.principal
            randkey: true
            password: ranger.kafka_plugin.password
          @execute
            header: 'Ranger Audit HDFS Layout'
            cmd: mkcmd.hdfs @, """
              hdfs dfs -mkdir -p #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/kafka
              hdfs dfs -chown -R #{kafka.user.name}:#{kafka.user.name} #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/kafka
              hdfs dfs -chmod 750 #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/kafka
            """

# Plugin Scripts 

      @call ->
        @render
          header: 'Scripts rendering'
          if: -> version?
          source: "#{__dirname}/../../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-kafka-plugin/install.properties"
          local: true
          eof: true
          backup: true
          write: for k, v of ranger.kafka_plugin.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-kafka-plugin/enable-kafka-plugin.sh"
          write: [
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{kafka.broker.conf_dir}"
            ,   
              match: RegExp "^HCOMPONENT_INSTALL_DIR_NAME=.*$", 'mg'
              replace: "HCOMPONENT_INSTALL_DIR_NAME=/usr/hdp/current/kafka-broker"
            ,
              match: RegExp "^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/kafka-broker/libs"
            , 
              match: RegExp "^HCOMPONENT_NAME=.*$", 'mg'
              replace: "HCOMPONENT_NAME=kafka-broker"

          ]
          backup: true
          mode: 0o750
        @file
          header: 'Fix Kafka Broker classpath'
          target: "#{kafka.broker.conf_dir}/kafka-env.sh"
          write: [
            match: RegExp "^export CLASSPATH=\"$CLASSPATH.*", 'm'
            replace: "export CLASSPATH=\"$CLASSPATH:${script_dir}:/usr/hdp/#{version}/ranger-kafka-plugin/lib/ranger-kafka-plugin-impl:#{kafka.broker.conf_dir}:/usr/hdp/current/hadoop-hdfs-client/*:/usr/hdp/current/hadoop-hdfs-client/lib/*:/etc/hadoop/conf\" # RYBA, DONT OVERWRITE"
            append: true
          ]
          backup: true
          eof: true
          mode:0o0750
          uid: kafka.user.name
          gid: kafka.group.name
        @execute
          header: 'Script Execution'
          cmd: """
            if /usr/hdp/#{version}/ranger-kafka-plugin/enable-kafka-plugin.sh ;
            then exit 0 ; 
            else exit 1 ; 
            fi;
          """
        @system.chmod
          header: "Fix Kafka Conf Permission"
          target: kafka.broker.conf_dir
          uid: kafka.user.name
          gid: kafka.group.name
          mode: 0o755
        @system.chmod
          header: "Fix Ranger Repo Permission"
          target: "/etc/ranger/#{ranger.kafka_plugin.install['REPOSITORY_NAME']}"
          uid: kafka.user.name
          gid: kafka.group.name
          mode: 0o750
        @hconfigure
          header: 'Fix ranger-kafka-security conf'
          target: "#{kafka.broker.conf_dir}/ranger-kafka-security.xml"
          merge: true
          properties:
            'ranger.plugin.kafka.policy.rest.ssl.config.file': "#{kafka.broker.conf_dir}/ranger-policymgr-ssl.xml"

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'


[hdfs-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hdfs_plugin)
