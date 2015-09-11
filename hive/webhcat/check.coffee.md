
# WebHCat Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

    module.exports.push name: 'WebHCat # Check Status', label_true: 'CHECKED', handler: ->
      # TODO, maybe we could test hive:
      # curl --negotiate -u : -d execute="show+databases;" -d statusdir="test_webhcat" http://front1.hadoop:50111/templeton/v1/hive
      {webhcat} = @config.ryba
      port = webhcat.site['templeton.port']
      @execute
        cmd: mkcmd.test @, """
        if hdfs dfs -test -f #{@config.host}-webhcat; then exit 2; fi
        curl -s --negotiate -u : http://#{@config.host}:#{port}/templeton/v1/status
        hdfs dfs -touchz #{@config.host}-webhcat
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        return if err
        throw Error "WebHCat not started" if executed and stdout.trim() isnt '{"status":"ok","version":"v1"}'

# Dependencies

    mkcmd = require '../../lib/mkcmd'
