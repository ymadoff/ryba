---
title: 
layout: module
---

# WebHCat Check

    mkcmd = require '../lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push require('./webhcat').configure

    module.exports.push name: 'WebHCat # Check Status', callback: (ctx, next) ->
      # TODO, maybe we could test hive:
      # curl --negotiate -u : -d execute="show+databases;" -d statusdir="test_webhcat" http://front1.hadoop:50111/templeton/v1/hive
      {webhcat_site} = ctx.config.ryba
      port = webhcat_site['templeton.port']
      ctx.execute
        cmd: mkcmd.test ctx, """
        if hdfs dfs -test -f #{ctx.config.host}-webhcat; then exit 2; fi
        curl -s --negotiate -u : http://#{ctx.config.host}:#{port}/templeton/v1/status
        hdfs dfs -touchz #{ctx.config.host}-webhcat
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        return next err if err
        return next null, false unless executed
        return next new Error "WebHCat not started" if stdout.trim() isnt '{"status":"ok","version":"v1"}'
        return next null, true