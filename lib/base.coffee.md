
# Ryba

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.configure = (ctx) ->
      require('masson/core/proxy').configure ctx
      ryba = ctx.config.ryba ?= {}
      # throw Error "Require configuration 'realm'" unless ryba.realm # TODO: discover default realm
      # Repository
      ryba.proxy = ctx.config.proxy.http_proxy if typeof ryba.http_proxy is 'undefined'
      ryba.hdp_repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.3.2.0/hdp.repo'
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
      # Database administration
      # todo: `require('masson/commons/mysql_server').configure ctx` and use returned values as default values
      ryba.db_admin ?= {}
      ryba.db_admin.engine ?= 'mysql'
      switch ryba.db_admin.engine
        when 'mysql'
          unless ryba.db_admin.host
            mysql_hosts = ctx.hosts_with_module 'masson/commons/mysql_server'
            throw new Error "Expect at least one server with action \"masson/commons/mysql_server\"" if mysql_hosts.length is 0
            mysql_host = ryba.db_admin.host = if mysql_hosts.length is 1 then mysql_hosts[0] else
              i = mysql_hosts.indexOf(ctx.config.host)
              if i isnt -1 then mysql_hosts[i] else throw new Error "Failed to find a Mysql Server"
            mysql_conf = ctx.hosts[mysql_host].config.mysql.server
          ryba.db_admin.path ?= 'mysql'
          ryba.db_admin.port ?= '3306'
          ryba.db_admin.username ?= 'root'
          ryba.db_admin.password ?= mysql_conf.password
        else throw new Error "Database engine not supported: #{ryba.engine}"

## Repository

Declare the HDP repository.

    module.exports.push
      header: 'Ryba # Repository'
      timeout: -1
      if: -> @config.ryba.hdp_repo
      handler: (options) ->
        {proxy, hdp_repo} = @config.ryba
        @download
          source: hdp_repo
          destination: '/etc/yum.repos.d/hdp.repo'
          proxy: proxy
        @execute
          cmd: "yum clean metadata; yum update -y"
          if: -> @status -1
        @call
          if: -> @status -2
          handler: (_, callback) ->
            options.log 'Upload PGP keys'
            @fs.readFile "/etc/yum.repos.d/hdp.repo", (err, content) =>
              return callback err if err
              keys = {}
              reg = /^pgkey=(.*)/gm
              while matches = reg.exec content
                keys[matches[1]] = true
              keys = Object.keys keys
              return callback null, true unless keys.length
              for key in keys
                @execute # TODO, should use `@download`
                  cmd: """
                  curl #{key} -o /etc/pki/rpm-gpg/#{path.basename key}
                  rpm --import  /etc/pki/rpm-gpg/#{path.basename key}
                  """
              @then callback


## Dependencies

    url = require 'url'
    hconfigure = require '../lib/hconfigure'
