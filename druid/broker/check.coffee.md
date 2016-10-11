
# Druid Broker Check

Todo: move to a druid client module. Here because the broker service is the latest
service to be started.

    module.exports = header: 'Druid Broker # Check', handler: ->
      {force_check, druid} = @config.ryba
      [overlord] = @contexts 'ryba/druid/overlord'
      @register 'hdfs_upload', 'ryba/lib/hdfs_upload'
      @call
        unless_exec: unless force_check then """
        echo #{druid.krb5_admin.password} | kinit #{druid.krb5_admin.principal} && {
          hdfs dfs -test -f quickstart/#{@config.host}.success
        }
        """
      , ->
        @file.json
          header: 'Enrich Index'
          target: "/opt/druid-#{druid.version}/quickstart/wikiticker-index.json"
          transform: (data) ->
            return data if data['hadoopDependencyCoordinates'] and "org.apache.hadoop:hadoop-client:2.7.3" in data['hadoopDependencyCoordinates']
            data['hadoopDependencyCoordinates'] = ["org.apache.hadoop:hadoop-client:2.7.3"]
            data
          merge: true
          pretty: true
          backup: true
        @execute
          header: 'Decompress'
          cmd: """
          if [ ! -f quickstart/wikiticker-2015-09-12-sampled.json  ]; then
            gunzip quickstart/wikiticker-2015-09-12-sampled.json.gz
          fi
          """
          cwd: "/opt/druid-#{druid.version}"
        @hdfs_upload
          header: 'Upload sample'
          target: "/user/#{druid.user.name}/quickstart/wikiticker-2015-09-12-sampled.json"
          source: "quickstart/wikiticker-2015-09-12-sampled.json"
          cwd: "/opt/druid-#{druid.version}"
          owner: "#{druid.user.name}"
        @execute
          header: 'Index'
          cmd: """
          job=`curl -L -XPOST -H 'Content-Type:application/json' \
            -d @quickstart/wikiticker-index.json \
            #{overlord.config.host}:#{overlord.config.ryba.druid.overlord.runtime['druid.port']}/druid/indexer/v1/task \
            | sed 's/.*"task":"\\(.*\\)".*/\\1/'`
          echo "Current job is $job"
          sleep 5
          while [ "RUNNING" == `curl -L -s http://worker1.ryba:8090/druid/indexer/v1/task/${job}/status | sed 's/.*"status":"\\([^"]*\\)".*/\\1/'` ]; do
            echo -n '.'
            sleep 5
          done
          [ 'SUCCESS' == `curl -L -s http://worker1.ryba:8090/druid/indexer/v1/task/${job}/status | sed 's/.*"status":"\\([^"]*\\)".*/\\1/'` ]
          """
          cwd: "/opt/druid-#{druid.version}"
          trap: true
        @execute
          header: 'Query'
          cmd: """
          count=`curl -L -XPOST -H 'Content-Type:application/json' \
            -d @quickstart/wikiticker-top-pages.json \
            #{@config.host}:#{@config.ryba.druid.broker.runtime['druid.port']}/druid/v2/?pretty \
            2>/dev/null \
            | wc -l`
          if [ $count -lt 50 ]; then exit 1; fi
          echo "Got $count results"
          echo #{druid.krb5_admin.password} | kinit #{druid.krb5_admin.principal} && {
            hdfs dfs -touchz quickstart/#{@config.host}.success
          }
          """
          cwd: "/opt/druid-#{druid.version}"
          trap: true
      # http://worker1.ryba:8090/console.html
      # curl  -L -XPOST -H 'Content-Type:application/json' --data-binary quickstart/wikiticker-top-pages.json http://master3.ryba:8082/druid/v2/?pretty -v
      # Broker
      # http://master1.ryba:8082/druid/v2/datasources
      # Coordinator
      # http://worker2.ryba:8081/#/
      
