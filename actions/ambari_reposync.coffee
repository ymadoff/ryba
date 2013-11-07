
module.exports = []

###
Synchronization
---------------
Upload the synchronization script and synchronize the Ambari repository locally
###
module.exports.push (ctx, next) ->
  @name 'Ambari Server # Synchronization'
  @timeout -1
  ctx.log 'Deploy the "ambari_reposync" synchronization script'
  ctx.render
    source: "#{__dirname}/../lib/ambari_reposync"
    local_source: true
    destination: '/usr/bin/ambari_reposync'
    context: ctx.config
    mode: 0o744
  , (err, rendered) ->
    next err if err
    ctx.log 'Install the "createrepo" package'
    ctx.service [
      name: 'createrepo'
    , 
      name: 'yum-utils'
    ], (err, installed) ->
      return next err if err
      ctx.execute
        cmd: "/usr/bin/ambari_reposync"
      , (err, executed) ->
        next err, if executed then ctx.OK else ctx.PASS