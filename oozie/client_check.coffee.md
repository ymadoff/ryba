
# Oozie Client Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./client').configure

    module.exports.push name: 'Oozie Client # Wait Server', timeout: -1, handler: (ctx, next) ->
      {hostname, port} = url.parse ctx.config.ryba.oozie.site['oozie.base.url'] 
      ctx.waitIsOpen hostname, port, (err) -> next err

## Check Client

    module.exports.push name: 'Oozie Client # Check Client', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {realm, user, oozie} = ctx.config.ryba
      ctx.execute
        cmd: mkcmd.test ctx, """
        oozie admin -oozie #{oozie.site['oozie.base.url']} -status
        """
      , (err, executed, stdout) ->
        return next err if err
        return next new Error "Oozie not ready, got: #{JSON.stringify stdout}" if stdout.trim() isnt 'System mode: NORMAL'
        return next null, true

## Check REST

    module.exports.push name: 'Oozie Client # Check REST', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {realm, user, oozie} = ctx.config.ryba
      ctx.execute
        cmd: mkcmd.test ctx, """
        curl -s -k --negotiate -u : #{oozie.site['oozie.base.url']}/v1/admin/status
        """
      , (err, executed, stdout) ->
        return next err if err
        return next new Error "Oozie not ready" if stdout.trim() isnt '{"systemMode":"NORMAL"}'
        return next null, true

## Check HDFS Workflow

    module.exports.push name: 'Oozie Client # Check HDFS Workflow', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', handler: (ctx, next) ->
      {force_check, user, core_site, yarn, oozie} = ctx.config.ryba
      rm_ctxs = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn_rm').configure
      if rm_ctxs.length > 1
        rm_ctx = ctx.context yarn.active_rm_host, require('../hadoop/yarn_rm').configure
        shortname = ".#{rm_ctx.config.shortname}"
      else
        rm_ctx = rm_ctxs[0]
        shortname = ''
      rm_address = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address#{shortname}"]
      ctx.write [
        content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}:8050
          queueName=default
          basedir=${nameNode}/user/#{user.name}/check-#{ctx.config.shortname}-oozie-fs
          oozie.wf.application.path=${basedir}
        """
        destination: "#{user.home}/check_oozie_fs/job.properties"
        uid: user.name
        gid: user.group
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
        destination: "#{user.home}/check_oozie_fs/workflow.xml"
        uid: user.name
        gid: user.group
        eof: true
      ], (err, written) ->
        return next err if err
        ctx.execute
          cmd: """
          hdfs dfs -rm -r -skipTrash check-#{ctx.config.shortname}-oozie-fs 2>/dev/null
          hdfs dfs -mkdir -p check-#{ctx.config.shortname}-oozie-fs
          hdfs dfs -touchz check-#{ctx.config.shortname}-oozie-fs/source
          hdfs dfs -put -f #{user.home}/check_oozie_fs/job.properties check-#{ctx.config.shortname}-oozie-fs
          hdfs dfs -put -f #{user.home}/check_oozie_fs/workflow.xml check-#{ctx.config.shortname}-oozie-fs
          export OOZIE_URL=#{oozie.site['oozie.base.url']}
          oozie job -dryrun -config #{user.home}/check_oozie_fs/job.properties
          jobid=`oozie job -run -config #{user.home}/check_oozie_fs/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          i=0
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          code_skipped: 2
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -f check-#{ctx.config.shortname}-oozie-fs/target"
        , next

## Check Pig Workflow

    module.exports.push name: 'Oozie Client # Check Pig Workflow', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', handler: (ctx, next) ->
      {force_check, user, core_site, yarn, oozie} = ctx.config.ryba
      rm_ctxs = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn_rm').configure
      if rm_ctxs.length > 1
        rm_ctx = ctx.context yarn.active_rm_host, require('../hadoop/yarn_rm').configure
        shortname = ".#{rm_ctx.config.shortname}"
      else
        rm_ctx = rm_ctxs[0]
        shortname = ''
      rm_address = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address#{shortname}"]
      # Get the name of the user running the Oozie Server
      os_ctxs = ctx.contexts 'ryba/oozie/server', require('./server').configure
      {oozie} = os_ctxs[0].config.ryba
      ctx.write [
        content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}
          oozie.libpath=/user/#{oozie.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{user.name}/check-#{ctx.config.shortname}-oozie-pig
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
        """
        destination: "#{user.home}/check_oozie_pig/job.properties"
        uid: user.name
        gid: user.group
        eof: true
      ,
        content: """
        <workflow-app name='check-#{ctx.config.shortname}-oozie-pig' xmlns='uri:oozie:workflow:0.4'>
          <start to='test-pig' />
          <action name='test-pig'>
            <pig>
              <job-tracker>${jobTracker}</job-tracker>
              <name-node>${nameNode}</name-node>
              <configuration>
                <property>
                  <name>mapred.compress.map.output</name>
                  <value>true</value>
                </property>
                <property>
                  <name>mapred.job.queue.name</name>
                  <value>${queueName}</value>
                </property>
              </configuration>
              <script>wordcount.pig</script>
              <param>INPUT=/user/${wf:user()}/check-#{ctx.config.shortname}-oozie-pig/input</param>
              <param>OUTPUT=/user/${wf:user()}/check-#{ctx.config.shortname}-oozie-pig/output</param>
            </pig>
            <ok to="end" />
            <error to="fail" />
          </action>
          <kill name="fail">
            <message>Pig failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
          </kill>
          <end name='end' />
        </workflow-app>
        """
        destination: "#{user.home}/check_oozie_pig/workflow.xml"
        uid: user.name
        gid: user.group
        eof: true
      ,
        content: """
        A = load '$INPUT';
        B = foreach A generate flatten(TOKENIZE((chararray)$0)) as word;
        C = group B by word;
        D = foreach C generate COUNT(B), group;
        store D into '$OUTPUT' USING PigStorage();
        """
        destination: "#{user.home}/check_oozie_pig/wordcount.pig"
        uid: user.name
        gid: user.group
        eof: true
      ], (err, written) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          hdfs dfs -rm -r -skipTrash check-#{ctx.config.shortname}-oozie-pig 2>/dev/null
          hdfs dfs -mkdir -p check-#{ctx.config.shortname}-oozie-pig/input
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{ctx.config.shortname}-oozie-pig/input/data
          hdfs dfs -put -f #{user.home}/check_oozie_pig/workflow.xml check-#{ctx.config.shortname}-oozie-pig
          hdfs dfs -put -f #{user.home}/check_oozie_pig/wordcount.pig check-#{ctx.config.shortname}-oozie-pig
          export OOZIE_URL=#{oozie.site['oozie.base.url']}
          oozie job -dryrun -config #{user.home}/check_oozie_pig/job.properties
          jobid=`oozie job -run -config #{user.home}/check_oozie_pig/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          i=0
          echo $jobid
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          trap_on_error: false # or while loop will exit on first run
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d check-#{ctx.config.shortname}-oozie-pig/output"
        , next

# Module Dependencies

    url = require 'url'
    mkcmd = require '../lib/mkcmd'

