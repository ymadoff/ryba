
module.exports = (ctx) ->
  # Options include
  # startup: [true] or false
  # link: [true]
  # write: array
  # version_name
  ctx.write_jaas = (options, callback) ->
    # Quick fix
    # waiting for context registration of mecano actions as well as
    # waiting for uid_gid moved from wrap to their expected location
    options.ssh ?= ctx.ssh
    wrap null, arguments, (options, callback) ->
      jaas = ""
      return callback Error "Required option 'content'" unless options.content
      for k, v of options.content
        jaas += "#{k.charAt(0).toUpperCase()}#{k.slice 1} {"
        if ctx.config.ryba.core_site['hadoop.security.authentication'] is 'kerberos'
          jaas += '\ncom.sun.security.auth.module.Krb5LoginModule required'
          jaas += if v.keytab? then '\n' + [
            "useKeyTab=true"
            "keyTab=\"#{v.keytab}\""
            "storeKey=true"
            "useTicketCache=false"
          ].join '\n'
          else "\nuseKeyTab=false\nuseTicketCache=true"
          jaas += if v.principal? then "\nprincipal=\"#{v.principal}\";" else ';'
        jaas += '\n};\n'
      options.content = jaas
      ctx.write options, callback

wrap = require 'mecano/lib/misc/wrap'
