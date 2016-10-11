
# Krb5 User

Create the Unix user and Kerberos principal used for testing.

    module.exports =
      'configure': ->
        ryba = @config.ryba ?= {}
        # Testing
        ryba.force_check ?= false
        ryba.user ?= {}
        ryba.user = name: ryba.user if typeof ryba.user is 'string'
        ryba.user.name ?= 'ryba'
        ryba.user.password ?= 'password'
        ryba.user.system ?= true
        ryba.user.gid ?= 'ryba'
        ryba.user.comment ?= 'ryba User'
        ryba.user.home ?= '/home/ryba'
        ryba.krb5_user ?= {}
        ryba.krb5_user = principal: ryba.krb5_user if typeof ryba.krb5_user is 'string'
        ryba.krb5_user.principal ?= ryba.user.name
        ryba.krb5_user.password ?= ryba.user.password if ryba.user.password?
        ryba.krb5_user.principal = "#{ryba.krb5_user.principal}@#{ryba.realm}" unless /.+@.+/.test ryba.krb5_user.principal
