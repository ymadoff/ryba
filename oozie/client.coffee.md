---
title: 
layout: module
---

# Oozie Client

    url = require 'url'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/hadoop/yarn_client'

    module.exports.push module.exports.configure = (ctx) ->
      oozie_server = ctx.host_with_module 'ryba/oozie/server'
      # Oozie configuration
      ctx.config.ryba.oozie_site ?= {}
      ctx.config.ryba.oozie_site['oozie.base.url'] = "http://#{oozie_server}:11000/oozie"
      # Internal properties
      oozieurl = url.parse ctx.config.ryba.oozie_site['oozie.base.url']
      ctx.config.ryba.oozie_port ?= oozieurl.port

# Install

Install the oozie client package. This package doesn't create any user and group.

    module.exports.push name: 'Oozie Client # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'oozie-client'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'Oozie Client # Profile', callback: (ctx, next) ->
      {oozie_site} = ctx.config.ryba
      ctx.write
        destination: '/etc/profile.d/oozie.sh'
        content: """
        #!/bin/bash
        export OOZIE_URL=#{oozie_site['oozie.base.url']}
        """
        mode: 0o0755
      , (err, written) ->
        next null, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'Oozie Client # Check Client', timeout: -1, callback: (ctx, next) ->
      {oozie_port, oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.ryba
      oozie_server = ctx.host_with_module 'ryba/oozie/server'
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

    module.exports.push name: 'Oozie Client # Check REST', timeout: -1, callback: (ctx, next) ->
      {oozie_port, oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.ryba
      oozie_server = ctx.host_with_module 'ryba/oozie/server'
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

    module.exports.push name: 'Oozie Client # Workflow', timeout: -1, callback: (ctx, next) ->
      {nameservice, oozie_port, oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.ryba
      rm = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      oozie_server = ctx.hosts_with_module 'ryba/oozie/server', 1
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
                  <message>Error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
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



















