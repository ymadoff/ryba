
# Ryba

    module.exports = []

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/core/proxy').configure ctx
      ryba = ctx.config.ryba ?= {}
      # Repository
      ryba.proxy = ctx.config.proxy.http_proxy if typeof ryba.http_proxy is 'undefined'
      ryba.hdp_repo ?= 'http://s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/centos6/2.x/2.1-latest/hdp.repo'
      # Testing
      ryba.force_check ?= false
      ryba.user ?= {}
      ryba.user = name: ryba.user if typeof ryba.user is 'string'
      ryba.user.name ?= 'ryba'
      ryba.user.system ?= true
      ryba.user.gid ?= 'ryba'
      ryba.user.comment ?= 'ryba User'
      ryba.user.home ?= '/home/ryba'

      ryba.krb5_user ?= {}
      ryba.krb5_user = name: ryba.krb5_user if typeof ryba.krb5_user is 'string'
      ryba.krb5_user.name ?= ryba.user.name
      ryba.krb5_user.password ?= ryba.user.password if ryba.user.password?
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
            mysql_conf = ctx.hosts[mysql_host].config.mysql_server
          ryba.db_admin.path ?= 'mysql'
          ryba.db_admin.port ?= '3306'
          ryba.db_admin.username ?= 'root'
          ryba.db_admin.password ?= mysql_conf.password
        else throw new Error "Database engine not supported: #{ryba.engine}"
      # Context
      ctx.hconfigure = (options, callback) ->
        options = [options] unless Array.isArray options
        for opt in options
          opt.ssh = ctx.ssh if typeof opt.ssh is 'undefined'
          opt.log ?= ctx.log
          opt.stdout ?= ctx.stdout
          opt.stderr ?= ctx.stderr
        hconfigure options, callback

## Repository

Declare the HDP repository.

    module.exports.push name: 'Ryba # Repository', timeout: -1, handler: (ctx, next) ->
      {proxy, hdp_repo} = ctx.config.ryba
      # Is there a repo to download and install
      return next() unless hdp_repo
      do_repo = ->
        ctx.log "Download #{hdp_repo} to /etc/yum.repos.d/hdp.repo"
        u = url.parse hdp_repo
        ctx[if u.protocol is 'http:' then 'download' else 'upload']
          source: hdp_repo
          destination: '/etc/yum.repos.d/hdp.repo'
          proxy: proxy
        , (err, downloaded) ->
          return next err if err
          return next null, false unless downloaded
          do_update()
      do_update = ->
          ctx.execute
            cmd: "yum clean metadata; yum update -y"
          , (err, executed) ->
            return next err if err
            do_keys()
      do_keys = ->
        ctx.log 'Upload PGP keys'
        ctx.fs.readFile "/etc/yum.repos.d/hdp.repo", (err, content) ->
          return next err if err
          keys = {}
          reg = /^pgkey=(.*)/gm
          while matches = reg.exec content
            keys[matches[1]] = true
          keys = Object.keys keys
          return next null, true unless keys.length
          each(keys)
          .on 'item', (key, next) ->
            # TODO, should use `ctx.download`
            ctx.execute
              cmd: """
              curl #{key} -o /etc/pki/rpm-gpg/#{path.basename key}
              rpm --import  /etc/pki/rpm-gpg/#{path.basename key}
              """
            , (err, executed) ->
              next err
          .on 'both', (err) ->
            next err, true
      do_repo()


## Module Dependencies

    url = require 'url'
    hconfigure = require '../lib/hconfigure'





