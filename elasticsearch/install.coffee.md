
# ElasticSearch Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/commons/java'
    module.exports.push require('./').configure

    module.exports.push name: 'ES # Users & Groups', handler: (ctx, next) ->
      {elasticsearch} = ctx.config.ryba
      ctx.group elasticsearch.group, (err, gmodified) ->
        return next err if err
        ctx.user elasticsearch.user, (err, umodified) ->
          next err, gmodified or umodified

## Kerberos

    module.exports.push name: 'ES # Kerberos', skip: true, handler: (ctx, next) ->
      {elasticsearch, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "elasticsearch/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: 'etc/security/keytabs/elasticsearch.service.keytab'
        uid: elasticsearch.user.name
        gid: elasticsearch.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## Install

ElasticSearch archive comes with an RPM

    module.exports.push name: 'ES # Install', timeout: -1, handler: (ctx, next) ->
      {elasticsearch, realm} = ctx.config.ryba
      ctx
      .download
        source: elasticsearch.source
        destination: "/root/elasticsearch-#{elasticsearch.version}.noarch.rpm"
        # not_if_exec: "rpm -q --queryformat '%{VERSION}' elasticsearch | grep '#{elasticsearch.version}'"
      .execute
        cmd:"""
        yum localinstall -y --nogpgcheck elasticsearch-#{elasticsearch.version}.noarch.rpm
        chkconfig --add elasticsearch
        """
        not_if_exec: "rpm -q --queryformat '%{VERSION}' elasticsearch | grep '#{elasticsearch.version}'"
      .then (err, modified) ->
        console.log '??', err
        next err

## Env

    module.exports.push name: 'ES # Env', handler: (ctx, next) ->
      {elasticsearch, zookeeper} = ctx.config.ryba
      write = [
        match: /^.*cluster.name: .*/m
        replace: "cluster.name: \"#{elasticsearch.cluster.name}\" # RYBA CONF `elasticsearch.cluster.name`, DON'T OVERWRITE"
      ,
        match: /^.*index.number_of_shards: .*/m
        replace: "index.number_of_shards: #{elasticsearch.number_of_shards} # RYBA CONF `elasticsearch.number_of_shards`, DON'T OVERWRITE"
      ,
        match: /^.*index.number_of_replicas: .*/m
        replace: "index.number_of_replicas: #{elasticsearch.number_of_replicas} # RYBA CONF `elasticsearch.number_of_replicas`, DON'T OVERWRITE"
      ]
      if elasticsearch.node?
        {node} = elasticsearch
        if node.name? then write.push
          match: /^.*node.name: .*/m
          replace: "node.name: \"#{elasticsearch.node.name}\" # RYBA CONF `elasticsearch.node.name`, DON'T OVERWRITE"
        if node.master? then write.push
          match: /^node.master: .*/m
          replace: "node.master: #{elasticsearch.node.master} # RYBA CONF `elasticsearch.node.master`, DON'T OVERWRITE"
          append: true
        if node.data? then write.push
          match: /^node.data: .*/m
          replace: "node.data: #{elasticsearch.node.data} # RYBA CONF `elasticsearch.node.data`, DON'T OVERWRITE"
          append: true
      ctx.write
        destination: '/etc/elasticsearch/elasticsearch.yml'
        write: write
      , next

    module.exports.push name: 'ES # Tuning', handler: (ctx, next) ->
      next null, 'TODO'

## Module Dependencies