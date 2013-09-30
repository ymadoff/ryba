
hdp_zookeeper = require './hdp_zookeeper'
module.exports = []

module.exports.push module.exports.configure = (ctx) ->
  hdp_zookeeper.configure ctx

module.exports.push (ctx, next) ->
  @name 'HDP ZooKeeper # Kerberos'
  {realm} = ctx.config.krb5_client
  ctx.mkprincipals
    principal: "zookeeper/#{ctx.config.host}@#{realm}"
    randkey: true
    keytab: "/etc/security/keytabs/zookeeper.service.keytab"
    uid: 'zookeeper'
    gid: 'hadoop'
    not_if_exists: "/etc/security/keytabs/zookeeper.service.keytab"
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS