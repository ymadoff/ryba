
path = require 'path'
semver = require 'semver'
url = require 'url'
module.exports = []

module.exports.push module.exports.configure = (ctx) ->
  require('./proxy').configure ctx
  ctx.config.java ?= {}
  ctx.config.java.java_home ?= '/usr/java/default'
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
    ctx.log "Java #{action}"
    ctx[action]
      source: location
      proxy: proxy
      destination: "/tmp/#{path.basename location}"
      binary: true
    , (err, downloaded) ->
      return next err if err
      ctx.log 'Install jdk in /usr/java'
      ctx.execute
        cmd: " yes | sh /tmp/#{path.basename location}"
      , (err, executed) ->
        return next err if err
        ctx.remove
          destination: "/tmp/#{path.basename location}"
        , (err, executed) ->
          next err, ctx.OK

module.exports.push (ctx, next) ->
  @name 'Java # Java JCE'
  {java_home, jce_local_policy, jce_us_export_policy} = ctx.config.java
  return next Error "JCE not configured" unless jce_local_policy or jce_us_export_policy
  @timeout -1
  ctx.log "Download jce-6 Security JARs"
  ctx.upload [
    source: jce_local_policy
    destination: "#{java_home}/jre/lib/security/local_policy.jar"
    binary: true
    sha1: 'c557a5da9075f41ede10829e9ff562b132b3246d'
  ,
    source: jce_us_export_policy
    destination: "#{java_home}/jre/lib/security/US_export_policy.jar"
    binary: true
    sha1: '1b5eb80bd3699de9b668d5f7b1a1d89681a91190'
  ], (err, downloaded) ->
    next err, if downloaded then ctx.OK else ctx.PASS
    # # seems like upload binary is buggy is call the callback to fast
    # setTimeout ->
    #   next err, if downloaded then ctx.OK else ctx.PASS
    # , 10000





