
    module.exports = header: 'Ranger Knox Gateway Plugin install', handler: ->
      {knox, ranger, realm, hadoop_group, core_site} = @config.ryba 
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      version=null

# Knox Dependencies

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
          name: "ranger-knox-plugin"

# Layout

      @system.mkdir
        target: ranger.knox_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: knox.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.knox_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      @system.mkdir
        target: ranger.knox_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: knox.user.name
        gid: hadoop_group.name
        mode: 0o0750
        if: ranger.knox_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'
        

# Knox Service Repository creation
Matchs step 1 in [kafka plugin configuration][kafka-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        if: @contexts('ryba/knox')[0].config.host is @config.host 
        header: 'Ranger Knox Repository'
        handler:  ->
          @execute
            unless_exec: """
              curl --fail -H \"Content-Type: application/json\"   -k -X GET  \ 
              -u admin:#{password} \"#{ranger.knox_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{ranger.knox_plugin.install['REPOSITORY_NAME']}\"
            """
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify ranger.knox_plugin.service_repo}' \
              -u admin:#{password} \"#{ranger.knox_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
            """
          @krb5_addprinc krb5,
            if: ranger.knox_plugin.principal
            header: 'Ranger Knox Principal'
            principal: ranger.knox_plugin.principal
            randkey: true
            password: ranger.knox_plugin.password
          @execute
            header: 'Knox plugin audit to HDFS'
            cmd: mkcmd.hdfs @, """
              hdfs dfs -mkdir -p #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/knox
              hdfs dfs -chown -R #{knox.user.name}:#{knox.user.name} #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/knox
              hdfs dfs -chmod 750 #{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/knox
            """

# Plugin Scripts 

      @call ->
        @file.render
          header: 'Scripts rendering'
          if: -> version?
          source: "#{__dirname}/../../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-knox-plugin/install.properties"
          local: true
          eof: true
          backup: true
          write: for k, v of ranger.knox_plugin.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-knox-plugin/enable-knox-plugin.sh"
          write:[
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{knox.conf_dir}"
          ]
          backup: true
          mode: 0o750
        @execute
          header: 'Script Execution'
          cmd: """
            export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec
             if /usr/hdp/#{version}/ranger-knox-plugin/enable-knox-plugin.sh ;
            then exit 0 ; 
            else exit 1 ; 
            fi;
          """

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'

[kafka-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_yarn_plugin)
