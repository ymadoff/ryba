
# Oozie Client Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./client').configure

    module.exports.push name: 'Oozie Client # Wait Server', timeout: -1, label_true: 'CHECKED', callback: (ctx, next) ->
      {hostname, port} = url.parse ctx.config.ryba.oozie_site['oozie.base.url'] 
      ctx.waitIsOpen hostname, port, (err) -> next err

    module.exports.push name: 'Oozie Client # Check Client', timeout: -1, callback: (ctx, next) ->
      {oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.ryba
      ctx.execute
        cmd: """
        if ! echo #{oozie_test_password} | kinit #{oozie_test_principal} >/dev/null; then exit 1; fi
        oozie admin -oozie #{oozie_site['oozie.base.url']} -status
        """
      , (err, executed, stdout) ->
        return next err if err
        return next new Error "Oozie not ready, got: #{JSON.stringify stdout}" if stdout.trim() isnt 'System mode: NORMAL'
        return next null, true

    module.exports.push name: 'Oozie Client # Check REST', timeout: -1, label_true: 'CHECKED', callback: (ctx, next) ->
      {oozie_test_principal, oozie_test_password, oozie_site} = ctx.config.ryba
      ctx.execute
        cmd: """
        if ! echo #{oozie_test_password} | kinit #{oozie_test_principal} >/dev/null; then exit 1; fi
        curl -s -k --negotiate -u : #{oozie_site['oozie.base.url']}/v1/admin/status
        """
      , (err, executed, stdout) ->
        return next err if err
        return next new Error "Oozie not ready" if stdout.trim() isnt '{"systemMode":"NORMAL"}'
        return next null, true

    module.exports.push name: 'Oozie Client # Check HDFS Workflow', timeout: -1, label_true: 'CHECKED', callback: (ctx, next) ->
      {force_check, test_user, core_site, oozie_site} = ctx.config.ryba
      rm_ctxs = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn').configure
      if rm_ctxs.length > 1
        rm_ctx = ctx.context active_rm_host, require('../hadoop/yarn').configure
        shortname = ".#{rm_ctx.config.shortname}"
      else
        rm_ctx = rm_ctxs[0]
        shortname = ''
      rm_address = rm_ctx.config.ryba.yarn_site["yarn.resourcemanager.address#{shortname}"]
      ctx.write [
        content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}:8050
          queueName=default
          basedir=${nameNode}/user/#{test_user.name}/check-#{ctx.config.shortname}-oozie-fs
          oozie.wf.application.path=${basedir}
        """
        destination: "#{test_user.home}/check_oozie_fs/job.properties"
        uid: test_user.name
        gid: test_user.group
        eof: true
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
        destination: "#{test_user.home}/check_oozie_fs/workflow.xml"
        uid: test_user.name
        gid: test_user.group
        eof: true
      ], (err, written) ->
        return next err if err
        ctx.execute
          cmd: """
          hdfs dfs -rm -r -skipTrash check-#{ctx.config.shortname}-oozie-fs 2>/dev/null
          hdfs dfs -mkdir -p check-#{ctx.config.shortname}-oozie-fs
          hdfs dfs -touchz check-#{ctx.config.shortname}-oozie-fs/source
          hdfs dfs -put -f #{test_user.home}/check_oozie_fs/job.properties check-#{ctx.config.shortname}-oozie-fs
          hdfs dfs -put -f #{test_user.home}/check_oozie_fs/workflow.xml check-#{ctx.config.shortname}-oozie-fs
          export OOZIE_URL=#{oozie_site['oozie.base.url']}
          oozie job -dryrun -config #{test_user.home}/check_oozie_fs/job.properties
          jobid=`oozie job -run -config #{test_user.home}/check_oozie_fs/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          i=0
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          code_skipped: 2
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d check-#{ctx.config.shortname}-oozie-pig/target"
        , (err, executed, stdout) ->
          return next err, true

# Module Dependencies

    url = require 'url'

