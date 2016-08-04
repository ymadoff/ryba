# Ranger HBase Plugin Install

    module.exports = header: 'Ranger HBase Plugin install', handler: ->
      {ranger, hdfs, hbase, realm, hadoop_group} = @config.ryba
      {password} = @contexts('ryba/ranger/admin')[0].config.ryba.ranger.admin
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      version=null
      conf_dir = if @contexts('ryba/hbase/master').map( (ctx) -> ctx.config.host)
        .indexOf(@config.host) > -1 then hbase.master.conf_dir else hbase.rs.conf_dir

## Dependencies

      @call once: true, 'ryba/ranger/admin/wait'
      @register 'hconfigure', 'ryba/lib/hconfigure'

## Packages

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
          name: "ranger-hbase-plugin"

## Layout

      @mkdir
        target: '/var/log/hadoop/hbase/audit/solr/'
        uid: hbase.user.name
        gid: hadoop_group.name
        mode: 0o0755

## HBase Service Repository creation
Matchs step 1 in [hdfs plugin configuration][hbase-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 
        if: @contexts('ryba/hbase/master')[0].config.host is @config.host 
        header: 'Ranger HBase Repository'
        handler:  ->
          @execute
            unless_exec: """
              curl --fail -H \"Content-Type: application/json\"   -k -X GET  \ 
              -u admin:#{password} \"#{ranger.hbase_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{ranger.hbase_plugin.install['REPOSITORY_NAME']}\"
            """
            cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify ranger.hbase_plugin.service_repo}' \
              -u admin:#{password} \"#{ranger.hbase_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
            """
          @krb5_addprinc krb5,
            if: ranger.hbase_plugin.principal
            header: 'Ranger HBase Principal'
            principal: ranger.hbase_plugin.principal
            randkey: true
            password: ranger.hbase_plugin.password
          @execute
            header: 'Fix Plugin Audit to HDFS permission'
            cmd: mkcmd.hdfs @, """
              hdfs dfs -mkdir -p /ranger/audit/hbaseMaster
              hdfs dfs -mkdir -p /ranger/audit/hbaseRegional
              hdfs dfs -chown -R hbase:hbase /ranger/audit/hbaseMaster
              hdfs dfs -chown -R hbase:hbase /ranger/audit/hbaseRegional
              hdfs dfs -chmod -R 755 /ranger/audit/hbaseMaster
              hdfs dfs -chmod -R 755 /ranger/audit/hbaseRegional
            """

## Plugin Scripts 

      @call ->
        @render
          header: 'Scripts rendering'
          if: -> version?
          source: "#{__dirname}/../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-hbase-plugin/install.properties"
          local_source: true
          eof: true
          backup: true
          write: for k, v of ranger.hbase_plugin.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @write
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-hbase-plugin/enable-hbase-plugin.sh"
          write:[
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{conf_dir}"
            ,
              match: RegExp "\\^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hbase-client/lib"
          ]
          backup: true
        @execute
          header: 'Script Execution'
          cmd: " /usr/hdp/#{version}/ranger-hbase-plugin/enable-hbase-plugin.sh"
        @execute
          header: "Fix Plugin repository permission"
          cmd: "chown -R #{hbase.user.name}:#{hadoop_group.name} /etc/ranger/#{ranger.hbase_plugin.install['REPOSITORY_NAME']}"
        @hconfigure
          header: 'Fix Plugin security conf'
          target: "#{conf_dir}/ranger-hbase-security.xml"
          merge: true
          properties:
            'ranger.plugin.hbase.policy.rest.ssl.config.file': "#{conf_dir}/ranger-policymgr-ssl.xml"


## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../lib/mkcmd'

[hbase-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hbase_plugin)
[perms-fix]https://community.hortonworks.com/questions/23717/ranger-solr-on-hdp-234-unable-to-refresh-policies.html
