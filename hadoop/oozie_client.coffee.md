---
title: 
layout: module
---

# Oozie Client

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'phyla/hadoop/oozie_'
    module.exports.push 'phyla/hadoop/mapred_client'
    module.exports.push 'phyla/hadoop/yarn_client'

    module.exports.push (ctx) ->
      require('./oozie_').configure ctx

    module.exports.push name: 'HDP Oozie Client # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'oozie-client'
      , (err, installed) ->
        next err, if installed then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Oozie Client # Check Client', timeout: -1, callback: (ctx, next) ->
      {oozie_port, oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.hdp
      oozie_server = ctx.host_with_module 'phyla/hadoop/oozie_server'
      ctx.waitIsOpen oozie_server, oozie_port, (err) ->
        ctx.execute
          cmd: """
          if ! echo #{oozie_test_password} | kinit #{oozie_test_principal} >/dev/null; then exit 1; fi
          oozie admin -oozie #{oozie_site['oozie.base.url']} -status
          """
        , (err, executed, stdout) ->
          return next err if err
          return next new Error "Oozie not started, got: #{JSON.stringify stdout}" if stdout.trim() isnt 'System mode: NORMAL'
          return next null, ctx.PASS

    module.exports.push name: 'HDP Oozie Client # Check REST', timeout: -1, callback: (ctx, next) ->
      {oozie_port, oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.hdp
      oozie_server = ctx.host_with_module 'phyla/hadoop/oozie_server'
      ctx.waitIsOpen oozie_server, oozie_port, (err) ->
        return next err if err
        ctx.execute
          cmd: """
          if ! echo #{oozie_test_password} | kinit #{oozie_test_principal} >/dev/null; then exit 1; fi
          curl -s --negotiate -u : #{oozie_site['oozie.base.url']}/v1/admin/status
          """
        , (err, executed, stdout) ->
          return next err if err
          return next new Error "Oozie not started" if stdout.trim() isnt '{"systemMode":"NORMAL"}'
          return next null, ctx.PASS

    module.exports.push name: 'HDP Oozie Client # Workflow', timeout: -1, callback: (ctx, next) ->
      {nameservice, oozie_port, oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.hdp
      rm = ctx.host_with_module 'phyla/hadoop/yarn_rm'
      oozie_server = ctx.hosts_with_module 'phyla/hadoop/oozie_server', 1
      ctx.waitIsOpen oozie_server, oozie_port, (err) ->
        return next err if err
        ctx.execute
          cmd: """
          if ! echo #{oozie_test_password} | kinit #{oozie_test_principal} >/dev/null; then exit 1; fi
          if hdfs dfs -test -f #{ctx.config.host}-oozie-workflow/target; then exit 2; fi
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          return next err, ctx.PASS if err or not executed
          # NameNode adress in HA mode:
          # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-High-Availability-Guide/cdh4hag_topic_2_6.html
          ctx.write [
            content: """
            nameNode=hdfs://#{nameservice}:8020
            jobTracker=#{rm}:8050
            queueName=default
            basedir=${nameNode}/user/#{/^(.*?)[\/@]/.exec(oozie_test_principal)[1]}/#{ctx.config.host}-oozie-workflow
            oozie.wf.application.path=${basedir}
            """
            destination: '/tmp/oozie_job.properties'
          ,
            content: """
            <workflow-app xmlns="uri:oozie:workflow:0.2" name="test-oozie-wf">
              <start to="move"/>
              <action name="move">
                <fs>
                  <move source='${basedir}/source' target='${basedir}/target'/>
                </fs>
                <ok to="end"/>
                <error to="fail"/>
              </action>
              <kill name="fail">
                  <message>Map/Reduce failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
              </kill>
              <end name="end"/>
            </workflow-app>
            """
            destination: '/tmp/oozie_workflow.xml'
          ], (err, written) ->
            return next err if err
            ctx.execute
              cmd: """
              hdfs dfs -mkdir -p #{ctx.config.host}-oozie-workflow
              hdfs dfs -touchz #{ctx.config.host}-oozie-workflow/source
              hdfs dfs -put -f /tmp/oozie_job.properties #{ctx.config.host}-oozie-workflow/job.properties
              hdfs dfs -put -f /tmp/oozie_workflow.xml #{ctx.config.host}-oozie-workflow/workflow.xml
              export OOZIE_URL=http://#{oozie_server}:#{oozie_port}/oozie
              oozie job -run -config /tmp/oozie_job.properties
              hdfs dfs -test -f #{ctx.config.host}-oozie-workflow/target
              """
              code_skipped: 2
            , (err, executed, stdout) ->
              return next err if err
              return next null, ctx.OK



















