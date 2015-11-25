
# HDFS HttpFS Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/httpfs/wait'

## Check HTTP
      
    module.exports.push header: 'HDFS HttpFS # Check', timeout: -1, label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {user} = @config.ryba
      protocol = if @config.ryba.httpfs.env.HTTPFS_SSL_ENABLED is 'true' then 'https' else 'http'
      @execute
        cmd: mkcmd.test @, """
        curl --fail -k --negotiate -u: #{protocol}://#{@config.host}:#{@config.ryba.httpfs.http_port}/webhdfs/v1/user/#{user.name}?op=GETFILESTATUS
        """
      , (err, _, stdout, stderr) ->
        throw Error "Invalid output" unless JSON.parse(stdout).FileStatus.owner is user.name

# Dependencies

    mkcmd = require '../../lib/mkcmd'
    
