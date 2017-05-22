
# Oozie Client Check

    module.exports = header: 'Oozie Client Check', timeout: -1, label_true: 'CHECKED', handler: ->
      {force_check, user, core_site, yarn, oozie} = @config.ryba
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'
      hs2_ctxs = @contexts 'ryba/hive/server2'
      [ranger_admin] = @contexts 'ryba/ranger/admin'

## Wait

      @call once: true, 'ryba/oozie/server/wait'

## Check Client

      @system.execute
        timeout: -1
        header: 'Check Client'
        cmd: mkcmd.test @, """
        oozie admin -oozie #{oozie.site['oozie.base.url']} -status
        """
      , (err, executed, stdout) ->
        throw err if err
        throw new Error "Oozie not ready, got: #{JSON.stringify stdout}" if stdout.trim() isnt 'System mode: NORMAL'

## Check REST

      @system.execute
        header: 'Check REST'
        cmd: mkcmd.test @, """
        curl -s -k --negotiate -u : #{oozie.site['oozie.base.url']}/v1/admin/status
        """
      , (err, executed, stdout) ->
        throw err if err
        throw new Error "Oozie not ready" if stdout.trim() isnt '{"systemMode":"NORMAL"}'

## Check HDFS Workflow

      @call header: 'Check HDFS Workflow', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', ->
        if rm_ctxs.length > 1
          rm_ctx = rm_ctxs[0]
          shortname = ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}"
        else
          rm_ctx = rm_ctxs[0]
          shortname = ''
        rm_address = rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.address#{shortname}"]
        @file
          content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}
          queueName=default
          basedir=${nameNode}/user/#{user.name}/check-#{@config.shortname}-oozie-fs
          oozie.wf.application.path=${basedir}
          """
          target: "#{user.home}/check_oozie_fs/job.properties"
          uid: user.name
          gid: user.group
          eof: true
        @file
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
          target: "#{user.home}/check_oozie_fs/workflow.xml"
          uid: user.name
          gid: user.group
          eof: true
        @system.execute
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
          unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.shortname}-oozie-fs/target"

## Check MapReduce Workflow

      @call header: 'Check MapReduce', skip: true, timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', ->
        if rm_ctxs.length > 1
          rm_ctx = rm_ctxs[0]
          # rm_ctx = @context rm_ctxs[0].config.ryba.yarn.active_rm_host#, require('../../hadoop/yarn_rm').configure
          shortname = ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}"
        else
          rm_ctx = rm_ctxs[0]
          shortname = ''
        rm_address = rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.address#{shortname}"]
        # Get the name of the user running the Oozie Server
        os_ctxs = @contexts 'ryba/oozie/server', require('../server/configure').handler
        {oozie} = os_ctxs[0].config.ryba
        @file
          content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}
          oozie.libpath=/user/#{oozie.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{user.name}/check-#{@config.shortname}-oozie-mr
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
          """
          target: "#{user.home}/check_oozie_mr/job.properties"
          uid: user.name
          gid: user.group
          eof: true
        @file
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
          target: "#{user.home}/check_oozie_mr/workflow.xml"
          uid: user.name
          gid: user.group
          eof: true
        @system.execute
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
          trap: false # or while loop will exit on first run
          unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.shortname}-oozie-mr/output/_SUCCESS"

## Check Pig Workflow

      @call header: 'Check Pig Workflow', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', ->
        if rm_ctxs.length > 1
          rm_ctx = rm_ctxs[0]
          # rm_ctx = @context rm_ctxs[0].config.ryba.yarn.active_rm_host#, require('../../hadoop/yarn_rm').configure
          shortname = ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}"
        else
          rm_ctx = rm_ctxs[0]
          shortname = ''
        rm_address = rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.address#{shortname}"]
        # Get the name of the user running the Oozie Server
        os_ctxs = @contexts 'ryba/oozie/server', require('../server/configure').handler
        {oozie} = os_ctxs[0].config.ryba
        @file
          content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}
          oozie.libpath=/user/#{oozie.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{user.name}/check-#{@config.shortname}-oozie-pig
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
          """
          target: "#{user.home}/check_oozie_pig/job.properties"
          uid: user.name
          gid: user.group
          eof: true
        @file
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
          target: "#{user.home}/check_oozie_pig/workflow.xml"
          uid: user.name
          gid: user.group
          eof: true
        @file
          content: """
          A = load '$INPUT';
          B = foreach A generate flatten(TOKENIZE((chararray)$0)) as word;
          C = group B by word;
          D = foreach C generate COUNT(B), group;
          store D into '$OUTPUT' USING PigStorage();
          """
          target: "#{user.home}/check_oozie_pig/wordcount.pig"
          uid: user.name
          gid: user.group
          eof: true
        @system.execute
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
          trap: false # or while loop will exit on first run
          unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.shortname}-oozie-pig/output/_SUCCESS"

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

      @call skip: true, header: 'Check HCat Workflow', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', ->
        if rm_ctxs.length > 1
          rm_ctx = rm_ctxs[0]
          # rm_ctx = @context rm_ctxs[0].config.ryba.yarn.active_rm_host#, require('../../hadoop/yarn_rm').configure
          shortname = ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}"
        else
          rm_ctx = rm_ctxs[0]
          shortname = ''
        rm_address = rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.address#{shortname}"]
        # Get the name of the user running the Oozie Server
        os_ctxs = @contexts 'ryba/oozie/server'#, require('../server').configure
        {oozie} = os_ctxs[0].config.ryba
        # Hive
        hcat_ctxs = @contexts 'ryba/hive/hcatalog'#, require('../../hive/hcatalog').configure
        @file
          content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}
          oozie.libpath=/user/#{oozie.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{user.name}/check-#{@config.shortname}-oozie-pig
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
          """
          target: "#{user.home}/check_oozie_hcat/job.properties"
          uid: user.name
          gid: user.group
          eof: true
        @file
          content: """
          <workflow-app name='check-#{@config.shortname}-oozie-pig' xmlns='uri:oozie:workflow:0.4'>
            <credentials>
              <credential name='hive_credentials' type='hcat'>
                <property>
                  <name>hcat.metastore.uri</name>
                  <value>#{hcat_ctxs[0].config.ryba.hive.hcatalog.site['hive.metastore.uris']}</value>
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
          target: "#{user.home}/check_oozie_hcat/workflow.xml"
          uid: user.name
          gid: user.group
          eof: true
        @file
          content: """
          A = load '$INPUT';
          B = foreach A generate flatten(TOKENIZE((chararray)$0)) as word;
          C = group B by word;
          D = foreach C generate COUNT(B), group;
          store D into '$OUTPUT' USING PigStorage();
          """
          target: "#{user.home}/check_oozie_hcat/wordcount.pig"
          uid: user.name
          gid: user.group
          eof: true
        @system.execute
          cmd: mkcmd.test @, """
          hdfs dfs -rm -r -skipTrash check-#{@config.shortname}-oozie-pig 2>/dev/null
          hdfs dfs -mkdir -p check-#{@config.shortname}-oozie-pig/input
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{@config.shortname}-oozie-pig/input/data
          hdfs dfs -put -f #{user.home}/check_oozie_hcat/workflow.xml check-#{@config.shortname}-oozie-pig
          hdfs dfs -put -f #{user.home}/check_oozie_hcat/wordcount.pig check-#{@config.shortname}-oozie-pig
          export OOZIE_URL=#{oozie.site['oozie.base.url']}
          oozie job -dryrun -config #{user.home}/check_oozie_hcat/job.properties
          jobid=`oozie job -run -config #{user.home}/check_oozie_hcat/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          i=0
          echo $jobid
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          trap: false # or while loop will exit on first run
          unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -d check-#{@config.shortname}-oozie-pig/output"

## Check Hive2 Workflow
From HDP 2.5 Hive action becomes deprecated against hive2 actions. As hive2 action use jdbc connection to communicate
with hiveserver2. It enables Ranger policies to be applied same way whatever the client.

      @call
        header: 'Check Policies (Ranger)'
        if: ranger_admin?
      , ->
        {install} = ranger_admin.config.ryba.ranger.hive_plugin
        dbs = []
        for hs2_ctx in hs2_ctxs
          dbs.push "check_#{@config.shortname}_server2_#{hs2_ctx.config.shortname}"
          dbs.push "check_#{@config.shortname}_oozie_hs2_nozk_#{hs2_ctx.config.shortname}"
        # use v1 policy api (old style) from ranger to have an example
        hive_policy =
          "policyName": "Ranger-Ryba-HIVE-OOZIE-Policy-#{@config.host}"
          "repositoryName": "#{install['REPOSITORY_NAME']}"
          "repositoryType":"hive"
          "description": 'Ryba check hive policy'
          "databases": "#{dbs.join ','}"
          'tables': '*'
          "columns": "*"
          "udfs": ""
          'tableType': 'Inclusion'
          'columnType': 'Inclusion'
          'isEnabled': true
          'isAuditEnabled': true
          "permMapList": [{
            "userList": ["#{user.name}"],
            "permList": ["all"]
          }]
        @wait.execute
          cmd: """
          curl --fail -H \"Content-Type: application/json\"   -k -X GET  \
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{install['REPOSITORY_NAME']}\"
          """
          code_skipped: [1,7,22] #22 is for 404 not found,7 is for not connected to host
        @system.execute
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X POST \
            -d '#{JSON.stringify hive_policy}' \
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/api/policy\"
          """
          unless_exec: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \
            -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/Ranger-Ryba-HIVE-OOZIE-Policy-#{@config.host}\"
          """
          code_skipped: 22

      @call header: 'Check Hive2 Workflow (No ZK)', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', ->
        if rm_ctxs.length > 1
          rm_ctx = rm_ctxs[0]
          # rm_ctx = @context rm_ctxs[0].config.ryba.yarn.active_rm_host#, require('../../hadoop/yarn_rm').configure
          shortname = ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}"
        else
          rm_ctx = rm_ctxs[0]
          shortname = ''
        rm_address = rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.address#{shortname}"]
        # Get the name of the user running the Oozie Server
        os_ctxs = @contexts 'ryba/oozie/server'#, require('../server').configure
        {oozie} = os_ctxs[0].config.ryba
        {hive} = hs2_ctxs[0].config.ryba
        # Constructs Hiveserver2 jdbc url
        for hs2_ctx in hs2_ctxs
          # {hive} = hs2_ctx.config.ryba
          db = "check_#{@config.shortname}_oozie_hs2_nozk_#{hs2_ctx.config.shortname}"
          port = if hs2_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
          then hs2_ctx.config.ryba.hive.server2.site['hive.server2.thrift.http.port']
          else hs2_ctx.config.ryba.hive.server2.site['hive.server2.thrift.port']
          principal = hs2_ctx.config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal']
          url = "jdbc:hive2://#{hs2_ctx.config.host}:#{port}/default"
          if hs2_ctx.config.ryba.hive.server2.site['hive.server2.use.SSL'] is 'true'
            url += ";ssl=true"
            url += ";sslTrustStore=#{@config.ryba.ssl_client['ssl.client.truststore.location']}"
            url += ";trustStorePassword=#{@config.ryba.ssl_client['ssl.client.truststore.password']}"
          if hs2_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
            url += ";transportMode=#{hs2_ctx.config.ryba.hive.server2.site['hive.server2.transport.mode']}"
            url += ";httpPath=#{hs2_ctx.config.ryba.hive.server2.site['hive.server2.thrift.http.path']}"
          workflow_dir = "check-#{@config.shortname}-oozie-hive2-#{hs2_ctx.config.shortname}"
          app_name = "check-#{@config.shortname}-oozie-hive2-#{hs2_ctx.config.shortname}"
          @file
            content: """
            nameNode=#{core_site['fs.defaultFS']}
            jobTracker=#{rm_address}
            oozie.libpath=/user/#{oozie.user.name}/share/lib
            queueName=default
            basedir=${nameNode}/user/#{user.name}/#{workflow_dir}
            oozie.wf.application.path=${basedir}
            oozie.use.system.libpath=true
            jdbcURL=#{url}
            principal=#{principal}
            """
            target: "#{user.home}/#{workflow_dir}/job.properties"
            uid: user.name
            gid: user.group
            eof: true
          @file
            content: """
            <workflow-app name='#{app_name}' xmlns='uri:oozie:workflow:0.4'>
              <credentials>
                <credential name='hive2_credentials' type='hive2'>
                  <property>
                    <name>hive2.jdbc.url</name>
                    <value>${jdbcURL}</value>
                  </property>
                  <property>
                    <name>hive2.server.principal</name>
                    <value>${principal}</value>
                  </property>
                </credential>
              </credentials>
              <start to='test-hive2' />
              <action name='test-hive2' cred="hive2_credentials">
                <hive2 xmlns="uri:oozie:hive2-action:0.1">
                  <job-tracker>${jobTracker}</job-tracker>
                  <name-node>${nameNode}</name-node>
                  <prepare>
                    <delete path="${nameNode}/user/${wf:user()}/#{workflow_dir}/second_table"/>
                  </prepare>
                  <configuration>
                    <property>
                      <name>mapred.job.queue.name</name>
                      <value>${queueName}</value>
                    </property>
                  </configuration>
                  <jdbc-url>${jdbcURL}</jdbc-url>
                  <script>hive.q</script>
                  <param>INPUT=/user/${wf:user()}/#{db}/first_table</param>
                  <param>OUTPUT=/user/${wf:user()}/#{db}/second_table</param>
                  <file>/user/ryba/#{workflow_dir}/truststore#truststore</file>
                </hive2>
                <ok to="end" />
                <error to="fail" />
              </action>
              <kill name="fail">
                <message>Hive2 (Beeline) action failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
              </kill>
              <end name='end' />
            </workflow-app>
            """
            target: "#{user.home}/#{workflow_dir}/workflow.xml"
            uid: user.name
            gid: user.group
            eof: true
          @file
            content: """
            DROP TABLE IF EXISTS #{db}.first_table;
            DROP DATABASE IF EXISTS #{db};
            CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{db}';
            USE #{db};
            CREATE EXTERNAL TABLE first_table (mynumber INT) STORED AS TEXTFILE LOCATION '${INPUT}';
            select SUM(mynumber) from first_table;
            INSERT OVERWRITE DIRECTORY '${OUTPUT}' SELECT * FROM first_table;
            """
            target: "#{user.home}/#{workflow_dir}/hive.q"
            uid: user.name
            gid: user.group
            eof: true
          @system.execute
            cmd: mkcmd.test @, """
            hdfs dfs -rm -r -skipTrash #{workflow_dir} 2>/dev/null
            hdfs dfs -mkdir -p #{workflow_dir}/first_table
            echo -e '1\\n2\\n3' | hdfs dfs -put - #{db}/first_table/data
            hdfs dfs -put -f #{user.home}/#{workflow_dir}/workflow.xml #{workflow_dir}
            hdfs dfs -put -f #{user.home}/#{workflow_dir}/hive.q #{workflow_dir}
            hdfs dfs -put -f /etc/hive/conf/truststore #{workflow_dir}
            echo "Run job"
            export OOZIE_URL=#{oozie.site['oozie.base.url']}
            oozie job -dryrun -config #{user.home}/#{workflow_dir}/job.properties
            jobid=`oozie job -run -config #{user.home}/#{workflow_dir}/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
            i=0
            echo "Job ID: $jobid"
            echo "Wait"
            while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
            do ((i++)); sleep 1; done
            echo "Print Status"
            oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
            """
            trap: false # or while loop will exit on first run
            unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -d /user/#{user.name}/#{db}/first_table"

## Check Spark Workflow

      @call header: 'Check Spark', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', ->
        if rm_ctxs.length > 1
          rm_ctx = rm_ctxs[0]
          # rm_ctx = @context rm_ctxs[0].config.ryba.yarn.active_rm_host#, require('../../hadoop/yarn_rm').configure
          shortname = ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}"
        else
          rm_ctx = rm_ctxs[0]
          shortname = ''
        rm_address = rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.address#{shortname}"]
        # Get the name of the user running the Oozie Server
        os_ctxs = @contexts 'ryba/oozie/server', require('../server/configure').handler
        {oozie} = os_ctxs[0].config.ryba
        @file
          content: """
          nameNode=#{core_site['fs.defaultFS']}
          jobTracker=#{rm_address}
          oozie.libpath=/user/#{oozie.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{user.name}/check-#{@config.shortname}-oozie-spark
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
          master=yarn-cluster
          """
          target: "#{user.home}/check_oozie_spark/job.properties"
          uid: user.name
          gid: user.group
          eof: true
        @file
          content: """
          <workflow-app name='check-#{@config.shortname}-oozie-spark' xmlns='uri:oozie:workflow:0.4'>
            <start to='test-spark' />
            <action name='test-spark'>
              <spark xmlns="uri:oozie:spark-action:0.1">
                <job-tracker>${jobTracker}</job-tracker>
                <name-node>${nameNode}</name-node>
                <prepare>
                  <delete path="${nameNode}/user/${wf:user()}/check-#{@config.shortname}-oozie-spark/output"/>
                </prepare>
                <master>${master}</master>
                <mode>cluster</mode>
                <name>Spark-FileCopy</name>
                <class>org.apache.oozie.example.SparkFileCopy</class>
                <jar>${nameNode}/user/${wf:user()}/check-#{@config.shortname}-oozie-spark/lib/oozie-examples.jar</jar>
                <spark-opts>--conf spark.ui.view.acls=* --executor-memory 512m --num-executors 1 --executor-cores 1 --driver-memory 512m</spark-opts>
                <arg>${nameNode}/user/${wf:user()}/check-#{@config.shortname}-oozie-spark/input/data.txt</arg>
                <arg>${nameNode}/user/${wf:user()}/check-#{@config.shortname}-oozie-spark/output</arg>
              </spark>
              <ok to="end" />
              <error to="fail" />
            </action>
            <kill name="fail">
              <message>Spark failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
            </kill>
            <end name='end' />
          </workflow-app>
          """
          target: "#{user.home}/check_oozie_spark/workflow.xml"
          uid: user.name
          gid: user.group
          eof: true
        @system.execute
          cmd: mkcmd.test @, """
          # Prepare HDFS
          hdfs dfs -rm -r -skipTrash check-#{@config.shortname}-oozie-spark 2>/dev/null
          hdfs dfs -mkdir -p check-#{@config.shortname}-oozie-spark/input
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{@config.shortname}-oozie-spark/input/data.txt
          hdfs dfs -put -f #{user.home}/check_oozie_spark/workflow.xml check-#{@config.shortname}-oozie-spark
          # Extract Examples
          if [ ! -d /var/tmp/oozie-examples ]; then
            mkdir /var/tmp/oozie-examples
            tar xzf /usr/hdp/current/oozie-client/doc/oozie-examples.tar.gz -C /var/tmp/oozie-examples
          fi
          hdfs dfs -put /var/tmp/oozie-examples/examples/apps/spark/lib check-#{@config.shortname}-oozie-spark
          # Run Oozie
          export OOZIE_URL=#{oozie.site['oozie.base.url']}
          oozie job -dryrun -config #{user.home}/check_oozie_spark/job.properties
          jobid=`oozie job -run -config #{user.home}/check_oozie_spark/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          # Check Job
          i=0
          echo $jobid
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          trap: false # or while loop will exit on first run
          unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.shortname}-oozie-spark/output/_SUCCESS"

# Module Dependencies

    url = require 'url'
    mkcmd = require '../../lib/mkcmd'
