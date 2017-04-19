
# HDFS HttpFS Check

    module.exports = header: 'HDFS HttpFS Check', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {user} = @config.ryba

Wait for HttpFs to be started.

      @call once: true, 'ryba/hadoop/httpfs/wait'

Test the HTTP server with a JMX request.

      protocol = if @config.ryba.httpfs.env.HTTPFS_SSL_ENABLED is 'true' then 'https' else 'http'
      @system.execute
        cmd: mkcmd.test @, """
        curl --fail -k --negotiate -u: \
          #{protocol}://#{@config.host}:#{@config.ryba.httpfs.http_port}/webhdfs/v1/user/#{user.name}?op=GETFILESTATUS
        """
      , (err, _, stdout, stderr) ->
        throw Error "Invalid output" unless JSON.parse(stdout).FileStatus.owner is user.name

# Dependencies

    mkcmd = require '../../lib/mkcmd'
