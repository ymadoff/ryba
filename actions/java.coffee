
path = require 'path'
semver = require 'semver'
url = require 'url'
proxy = require './proxy'
module.exports = []

module.exports.push (ctx) ->
  proxy.configure ctx
  ctx.config.java ?= {}
  ctx.config.java.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.java is 'undefined'
  throw new Error "Configuration property 'java.location' is required." unless ctx.config.java.location
  throw new Error "Configuration property 'java.version' is required." unless ctx.config.java.version
  # ctx.config.java.version ?= (/\w+-([\w\d]+)-/.exec path.basename ctx.config.java.location)[0]

###
Followed instruction from: http://www.if-not-true-then-false.com/2010/install-sun-oracle-java-jdk-jre-6-on-fedora-centos-red-hat-rhel/
but we didn't use alternative yet
As of sep 2013, jdk7 is supported by Cloudera but not by Hortonworks.
###
module.exports.push (ctx, next) ->
  {proxy, location, version} = ctx.config.java
  @name 'Java # Install'
  @timeout -1
  ctx.log "Check if java is here and which version it is"
  ctx.execute
    cmd: 'ls -d /usr/java/jdk*'
  , (err, executed, stdout) ->
    return next err if err and err.code isnt 2
    stdout = '' if err
    installed_version = stdout.trim().split('\n').pop()
    if installed_version
      installed_version = /jdk(.*)/.exec(installed_version)[1].replace('_', '') 
      version = version.replace('_', '') 
      unless semver.gt version, installed_version
        return next null, ctx.PASS
    action = if url.parse(location).protocol is 'http:' then 'download' else 'upload'
    ctx.log "Java #{action} from #{location}"
    ctx[action]
      source: location
      proxy: proxy
      destination: "/tmp/#{path.basename location}"
      binary: true
    , (err, downloaded) ->
      return next err if err
      ctx.log 'Install jdk in /usr/java'
      # for /*.rpm$/ => "rpm -Uvh /tmp/#{path.basename location}"
      ctx.execute
        cmd: " yes | sh /tmp/#{path.basename location}"
      , (err, executed) ->
        return next err if err
        ctx.remove
          destination: "/tmp/#{path.basename location}"
        , (err, executed) ->
          next err, ctx.OK





