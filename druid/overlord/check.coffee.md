
# Druid Overlord Install

    module.exports = header: 'Druid Overlord # Check', handler: ->
      @execute
        cmd: """
        if [ ! -f gunzip quickstart/wikiticker-2015-09-12-sampled.json  ]; then
          gunzip gunzip quickstart/wikiticker-2015-09-12-sampled.json.gz
        fi
        """
        unless_exists: "#{}/quickstart/wikiticker-2015-09-12-sampled"
      # Modify wikiticker-index.json
      # add "hadoopDependencyCoordinates": ["org.apache.hadoop:hadoop-client:2.7.1"]
      # see https://github.com/druid-io/druid/blob/master/docs/content/operations/other-hadoop.md
      # todo move this to mecano.file.json
      @call (_, callback) =>
        @fs.readFile "/opt/druid-#{druid.version}/quickstart/wikiticker-2015-09-12-sampled", (err, json) ->
          return callback err if err
          data = JSON.parse json
          return callback() if "org.apache.hadoop:hadoop-client:2.7.1" in data['hadoopDependencyCoordinates']
          data['hadoopDependencyCoordinates'] = ["org.apache.hadoop:hadoop-client:2.7.1"]
          data = JSON.strinfify data
          @fs.writeFile "/opt/druid-#{druid.version}/quickstart/wikiticker-2015-09-12-sampled", (err) ->
            callback err
      @execute
        cmd: """
        echo druid123 | kinit druid
        if ! hdfs dfs -test -f quickstart/wikiticker-2015-09-12-sampled.json; then
          hdfs dfs -mkdir quickstart
          hdfs dfs -put quickstart/wikiticker-2015-09-12-sampled.json quickstart/wikiticker-2015-09-12-sampled.json
        fi
        curl -L -X 'POST' -H 'Content-Type:application/json' \
          -d @quickstart/wikiticker-index.json \
          #{@config.host}:8090/druid/indexer/v1/task
        """
        cwd: '/opt/druid'
        trap: true
      #  http://localhost:8090/console.html
