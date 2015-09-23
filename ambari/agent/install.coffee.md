# Ambari Agent Install

The ambari server must be set in the configuration file.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/ambari/server/wait'
    # module.exports.push require('./index').configure

    # module.exports.push name: '', handler: ->
    #   @mkdir 
    #     destination: "/root/.ssh"
    #     uid: 'root'
    #     gid: null
    #     mode: 0o700 # was "permissions: 16832"
    #   , (err, created) ->
    #     return next err if err
    #     write = for key in user.authorized_keys
    #       match: new RegExp ".*#{misc.regexp.escape key}.*", 'mg'
    #       replace: key
    #       append: true
    #     @write
    #       destination: "#{user.home or '/home/'+user.name}/.ssh/authorized_keys"
    #       write: write
    #       uid: user.name
    #       gid: null
    #       mode: 0o600
    #       eof: true
    #     , (err, written) ->
    #       return next err if err
    #       modified = true if written
    #       next()

    module.exports.push name: 'Ambari Agent # Configure', timeout: -1, handler: ->
      {ambari_agent} = @config.ryba
      # @ini # mecano need to manage multiline values
      #   destination: "#{ambari_agent.conf_dir}/ambari-agent.ini"
      #   content: ambari_agent.config
      #   merge: true
      #   backup: true
      #   if: false

      @write
        destination: "#{ambari_agent.conf_dir}/ambari-agent.ini"
        write: [
          match: /^hostname=(.*)/m
          replace: "hostname=#{ambari_agent.config.server['hostname']}"
        ,
          match: /^url_port=(.*)/m
          replace: "url_port=#{ambari_agent.config.server['url_port']}"
        ,
          match: /^secured_url_port=(.*)/m
          replace: "secured_url_port=#{ambari_agent.config.server['secured_url_port']}"
        ]
 
    module.exports.push name: 'Ambari Agent # Startup', timeout: -1, handler: ->
      @service
        name: 'ambari-agent'
        startup: true
