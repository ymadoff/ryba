
# `hdfs_execute(options, callback)`

Create an HDFS directory.

Options include:

*   `target`   
*   `krb5_user`   
*   `mode`   
*   `user`   
*   `group`   
*   `parent`   
*   `parent.mode`   
*   `parent.user`   
*   `parent.group`   

## Source Code

    module.exports = (options, callback) ->
      wrap = (cmd) ->
        return cmd unless options.krb5_user
        "echo '#{options.krb5_user.password}' | kinit #{options.krb5_user.principal} >/dev/null && {\n#{cmd}\n}; kdestroy"
      options.cmd = wrap options.cmd
      @system.execute options, callback

    module.exports.register = ->
      ctx.register 'kexecute', module.exports unless ctx.registered 'kexecute'
