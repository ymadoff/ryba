
# Druid Overlord Install

    module.exports = header: 'Druid Overlord # Check', handler: ->
      @extract
        target: "wikiticker-2015-09-12-sampled.json"
      @execute
        cmd: """
        curl -X 'POST' -H 'Content-Type:application/json' \
          -d @quickstart/wikiticker-index.json \
          #{@config.host}:8090/druid/indexer/v1/task
        """
      #  http://localhost:8090/console.html
