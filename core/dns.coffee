
mecano = require 'mecano'
module.exports = []

ipRegex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/

module.exports.push 'phyla/core/bind_client'

module.exports.push name: 'DNS # Forward lookup', callback: (ctx, next) ->
  ctx.execute
    cmd: "dig #{ctx.config.host}. +short"
    # cmd: "host #{ctx.config.host}"
    code_skipped: 1
  , (err, executed, stdout, stderr) ->
    if err
      next err
    else unless ipRegex.test stdout.trim()
      ctx.log "Invalid IP #{stdout.trim()}"
      next null, ctx.WARN
    else
     next null, ctx.PASS

module.exports.push name: 'DNS # Reverse lookup', callback: (ctx, next) ->
  ctx.execute
    # dig not installed by default on centos
    cmd: "dig -x `dig #{ctx.config.host}. +short` +short"
    # cmd: "host #{ctx.config.ip}"
    code_skipped: 1
  , (err, executed, stdout) ->
    next err, if "#{ctx.config.host}." is stdout.trim() then ctx.PASS else ctx.WARN

