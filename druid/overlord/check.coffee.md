
# Druid Overlord Install

    module.exports = header: 'Druid Overlord # Check', handler: ->
      @execute
        cmd: """
        if [ ! -f gunzip quickstart/wikiticker-2015-09-12-sampled.json  ]; then
          gunzip gunzip quickstart/wikiticker-2015-09-12-sampled.json.gz
        fi
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
