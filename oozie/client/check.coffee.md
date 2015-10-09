
# Oozie Client Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/oozie/server/wait'
    # module.exports.push require('./index').configure

## Check Client

    module.exports.push name: 'Oozie Client # Check Client', timeout: -1, label_true: 'CHECKED', handler: ->
      {oozie} = @config.ryba
      @execute
        cmd: mkcmd.test @, """
        oozie admin -oozie #{oozie.site['oozie.base.url']} -status
        """
      , (err, executed, stdout) ->
        throw err if err
        throw new Error "Oozie not ready, got: #{JSON.stringify stdout}" if stdout.trim() isnt 'System mode: NORMAL'

## Check REST

    module.exports.push name: 'Oozie Client # Check REST', timeout: -1, label_true: 'CHECKED', handler: ->
      {oozie} = @config.ryba
      @execute
        cmd: mkcmd.test @, """
        curl -s -k --negotiate -u : #{oozie.site['oozie.base.url']}/v1/admin/status
        """
      , (err, executed, stdout) ->
        throw err if err
        throw new Error "Oozie not ready" if stdout.trim() isnt '{"systemMode":"NORMAL"}'

## Check HDFS Workflow

    module.exports.push name: 'Oozie Client # Check HDFS Workflow', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {force_check, user, core_site, yarn, oozie} = @config.ryba
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'#, require('../../hadoop/yarn_rm').configure
      if rm_ctxs.length > 1
        rm_ctx = @context yarn.active_rm_host#, require('../../hadoop/yarn_rm').configure
        shortname = ".#{rm_ctx.config.shortname}"
      else
        rm_ctx = rm_ctxs[0]
        shortname = ''
      rm_address = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address#{shortname}"]
      @write
        content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}
          queueName=default
          basedir=${nameNode}/user/#{user.name}/check-#{@config.shortname}-oozie-fs
          oozie.wf.application.path=${basedir}
        """
        destination: "#{user.home}/check_oozie_fs/job.properties"
        uid: user.name
        gid: user.group
        eof: true
      @write
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
      @execute
        cmd: mkcmd.test @, """
        hdfs dfs -rm -r -skipTrash check-#{@config.shortname}-oozie-fs 2>/dev/null
        hdfs dfs -mkdir -p check-#{@config.shortname}-oozie-fs
        hdfs dfs -touchz check-#{@config.shortname}-oozie-fs/source
        hdfs dfs -put -f #{user.home}/check_oozie_fs/job.properties check-#{@config.shortname}-oozie-fs
        hdfs dfs -put -f #{user.home}/check_oozie_fs/workflow.xml check-#{@config.shortname}-oozie-fs
        export OOZIE_URL=#{oozie.site['oozie.base.url']}
        oozie job -dryrun -config #{user.home}/check_oozie_fs/job.properties
        jobid=`oozie job -run -config #{user.home}/check_oozie_fs/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
        i=0
        while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
        do ((i++)); sleep 1; done
        oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
        """
        code_skipped: 2
        not_if_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.shortname}-oozie-fs/target"

## Check MapReduce Workflow

    module.exports.push name: 'Oozie Client # Check MapReduce', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {force_check, user, core_site, yarn, oozie} = @config.ryba
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'#, require('../../hadoop/yarn_rm').configure
      if rm_ctxs.length > 1
        rm_ctx = @context yarn.active_rm_host#, require('../../hadoop/yarn_rm').configure
        shortname = ".#{rm_ctx.config.shortname}"
      else
        rm_ctx = rm_ctxs[0]
        shortname = ''
      rm_address = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address#{shortname}"]
      # Get the name of the user running the Oozie Server
      os_ctxs = @contexts 'ryba/oozie/server', require('../server').configure
      {oozie} = os_ctxs[0].config.ryba
      @write
        content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}
          oozie.libpath=/user/#{oozie.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{user.name}/check-#{@config.shortname}-oozie-mr
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
        """
        destination: "#{user.home}/check_oozie_mr/job.properties"
        uid: user.name
        gid: user.group
        eof: true
      @write
        content: """
        <workflow-app name='check-#{@config.shortname}-oozie-mr' xmlns='uri:oozie:workflow:0.4'>
          <start to='test-mr' />
          <action name='test-mr'>
            <map-reduce>
              <job-tracker>${jobTracker}</job-tracker>
              <name-node>${nameNode}</name-node>
              <configuration>
                <property>
                  <name>mapred.job.queue.name</name>
                  <value>${queueName}</value>
                </property>
                <property>
                  <name>mapred.mapper.class</name>
                  <value>org.apache.oozie.example.SampleMapper</value>
                </property>
                <property>
                  <name>mapred.reducer.class</name>
                  <value>org.apache.oozie.example.SampleReducer</value>
                </property>
                <property>
                  <name>mapred.map.tasks</name>
                  <value>1</value>
                </property>
                <property>
                  <name>mapred.input.dir</name>
                  <value>/user/${wf:user()}/check-#{@config.shortname}-oozie-mr/input</value>
                </property>
                <property>
                  <name>mapred.output.dir</name>
                  <value>/user/${wf:user()}/check-#{@config.shortname}-oozie-mr/output</value>
                </property>
              </configuration>
            </map-reduce>
            <ok to="end" />
            <error to="fail" />
          </action>
          <kill name="fail">
            <message>MapReduce failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
          </kill>
          <end name='end' />
        </workflow-app>
        """
        destination: "#{user.home}/check_oozie_mr/workflow.xml"
        uid: user.name
        gid: user.group
        eof: true
      @execute
        cmd: mkcmd.test @, """
        # Prepare HDFS
        hdfs dfs -rm -r -skipTrash check-#{@config.shortname}-oozie-mr 2>/dev/null
        hdfs dfs -mkdir -p check-#{@config.shortname}-oozie-mr/input
        echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{@config.shortname}-oozie-mr/input/data
        hdfs dfs -put -f #{user.home}/check_oozie_mr/workflow.xml check-#{@config.shortname}-oozie-mr
        # Extract Examples
        if [ ! -d /var/tmp/oozie-examples ]; then
          mkdir /var/tmp/oozie-examples
          tar xzf /usr/hdp/current/oozie-client/doc/oozie-examples.tar.gz -C /var/tmp/oozie-examples
        fi
        hdfs dfs -put /var/tmp/oozie-examples/examples/apps/map-reduce/lib check-#{@config.shortname}-oozie-mr
        # Run Oozie
        export OOZIE_URL=#{oozie.site['oozie.base.url']}
        oozie job -dryrun -config #{user.home}/check_oozie_mr/job.properties
        jobid=`oozie job -run -config #{user.home}/check_oozie_mr/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
        # Check Job
        i=0
        echo $jobid
        while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
        do ((i++)); sleep 1; done
        oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
        """
        trap_on_error: false # or while loop will exit on first run
        not_if_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.shortname}-oozie-mr/output/_SUCCESS"

## Check Pig Workflow

    module.exports.push name: 'Oozie Client # Check Pig Workflow', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {force_check, user, core_site, yarn, oozie} = @config.ryba
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'#, require('../../hadoop/yarn_rm').configure
      if rm_ctxs.length > 1
        rm_ctx = @context yarn.active_rm_host#, require('../../hadoop/yarn_rm').configure
        shortname = ".#{rm_ctx.config.shortname}"
      else
        rm_ctx = rm_ctxs[0]
        shortname = ''
      rm_address = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address#{shortname}"]
      # Get the name of the user running the Oozie Server
      os_ctxs = @contexts 'ryba/oozie/server', require('../server').configure
      {oozie} = os_ctxs[0].config.ryba
      @write
        content: """
        nameNode=#{core_site['fs.defaultFS']}
        jobTracker=#{rm_address}
        oozie.libpath=/user/#{oozie.user.name}/share/lib
        queueName=default
        basedir=${nameNode}/user/#{user.name}/check-#{@config.shortname}-oozie-pig
        oozie.wf.application.path=${basedir}
        oozie.use.system.libpath=true
        """
        destination: "#{user.home}/check_oozie_pig/job.properties"
        uid: user.name
        gid: user.group
        eof: true
      @write
        content: """
        <workflow-app name='check-#{@config.shortname}-oozie-pig' xmlns='uri:oozie:workflow:0.4'>
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
              <param>INPUT=/user/${wf:user()}/check-#{@config.shortname}-oozie-pig/input</param>
              <param>OUTPUT=/user/${wf:user()}/check-#{@config.shortname}-oozie-pig/output</param>
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
      @write
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
      @execute
        cmd: mkcmd.test @, """
        hdfs dfs -rm -r -skipTrash check-#{@config.shortname}-oozie-pig 2>/dev/null
        hdfs dfs -mkdir -p check-#{@config.shortname}-oozie-pig/input
        echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{@config.shortname}-oozie-pig/input/data
        hdfs dfs -put -f #{user.home}/check_oozie_pig/workflow.xml check-#{@config.shortname}-oozie-pig
        hdfs dfs -put -f #{user.home}/check_oozie_pig/wordcount.pig check-#{@config.shortname}-oozie-pig
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
        not_if_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.shortname}-oozie-pig/output/_SUCCESS"

## Check HCat Workflow

# When Hive metastore is set in HA (High Availability) with Kerberos authentication, Oozie Hive/Pig action needs to be configured with HCat credential with HA mode. The following example demonstrates how to configure Oozie Hive/Pig action to work with Hive metastore HA:

# <workflow-app xmlns="uri:oozie:workflow:0.5" name="pig-wf">
#   <credentials>
#     <credential name='my_auth' type='hcat'>
#       <property>
#         <name>hcat.metastore.uri</name
#         <value>thrift://hdpsecc04.secc.hwxsup.com:9083,thrift://hdpsecc02.secc.hwxsup.com:9083</value>
#       </property>
#       <property>
#         <name>hcat.metastore.principal</name>
#         <value>hive/_HOST@HDPSECC.SUPSECC.COM</value>
#       </property>
#    </credential>
#   </credentials>
#   <start to="pig-node"/>
#   <action name="pig-node" cred="my_auth">
#     <pig>
#       <job-tracker>${jobTracker}</job-tracker>
#       <name-node>${nameNode}</name-node>
#       <job-xml>hive-site.xml</job-xml>
#       <configuration>
#         <property>
#           <name>mapreduce.job.queuename</name>
#           <value>${queueName}</value>
#         </property>
#       </configuration>
#       <script>testscript.pig</script>
#     </pig>
#    <ok to="end"/>
#    <error to="fail"/>
#   </action>
#   <kill name="fail">
#     <message>Pig failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
#   </kill>
#   <end name="end"/>
# </workflow-app>

    module.exports.push skip: true, name: 'Oozie Client # Check HCat Workflow', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {force_check, user, core_site, yarn, oozie} = @config.ryba
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'#, require('../../hadoop/yarn_rm').configure
      if rm_ctxs.length > 1
        rm_ctx = @context yarn.active_rm_host#, require('../../hadoop/yarn_rm').configure
        shortname = ".#{rm_ctx.config.shortname}"
      else
        rm_ctx = rm_ctxs[0]
        shortname = ''
      rm_address = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address#{shortname}"]
      # Get the name of the user running the Oozie Server
      os_ctxs = @contexts 'ryba/oozie/server'#, require('../server').configure
      {oozie} = os_ctxs[0].config.ryba
      # Hive
      hcat_ctxs = @contexts 'ryba/hive/hcatalog'#, require('../../hive/hcatalog').configure
      @write
        content: """
        nameNode=#{core_site['fs.defaultFS']}
        jobTracker=#{rm_address}
        oozie.libpath=/user/#{oozie.user.name}/share/lib
        queueName=default
        basedir=${nameNode}/user/#{user.name}/check-#{@config.shortname}-oozie-pig
        oozie.wf.application.path=${basedir}
        oozie.use.system.libpath=true
        """
        destination: "#{user.home}/check_oozie_pig/job.properties"
        uid: user.name
        gid: user.group
        eof: true
      @write
        content: """
        <workflow-app name='check-#{@config.shortname}-oozie-pig' xmlns='uri:oozie:workflow:0.4'>
          <credentials>
            <credential name='hive_credentials' type='hcat'>
              <property>
                <name>hcat.metastore.uri</name>
                <value>thrift://master3.ryba:9083</value>
              </property>
              <property>
                <name>hcat.metastore.principal</name>
                <value>hive/_HOST@HADOOP.RYBA</value>
              </property>
            </credential>
          </credentials>
          <start to='test-pig' />
          <action name='test-pig' cred="hive_credentials">
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
              <param>INPUT=/user/${wf:user()}/check-#{@config.shortname}-oozie-pig/input</param>
              <param>OUTPUT=/user/${wf:user()}/check-#{@config.shortname}-oozie-pig/output</param>
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
      @write
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
      @execute
        cmd: mkcmd.test @, """
        hdfs dfs -rm -r -skipTrash check-#{@config.shortname}-oozie-pig 2>/dev/null
        hdfs dfs -mkdir -p check-#{@config.shortname}-oozie-pig/input
        echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{@config.shortname}-oozie-pig/input/data
        hdfs dfs -put -f #{user.home}/check_oozie_pig/workflow.xml check-#{@config.shortname}-oozie-pig
        hdfs dfs -put -f #{user.home}/check_oozie_pig/wordcount.pig check-#{@config.shortname}-oozie-pig
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
        not_if_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -d check-#{@config.shortname}-oozie-pig/output"

# Module Dependencies

    url = require 'url'
    mkcmd = require '../../lib/mkcmd'
