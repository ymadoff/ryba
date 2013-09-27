
###
Ambari Server
###
util = require 'util'
misc = require 'mecano/lib/misc'
each = require 'each'
ini = require 'ini'
url = require 'url'
builder = require 'xmlbuilder'

module.exports = []

###
Dependency: proxy, pdsh
See the documentation about [Software Requirements][sr].

[sr]: http://incubator.apache.org/ambari/1.2.0/installing-hadoop-using-ambari/content/ambari-chap1-2.html#ambari-chap1-2-2
###
module.exports.push 'histi/actions/proxy'
module.exports.push 'histi/actions/httpd'
module.exports.push 'histi/actions/yum'
module.exports.push 'histi/actions/netcat'

###
Configuration
-------------

###
module.exports.push (ctx) ->
  ctx.config.ambari ?= {}
  # Install 1.2.0 with rpm (http://incubator.apache.org/ambari/1.2.0/installing-hadoop-using-ambari/content/ambari-chap2-1.html)
  # http://public-repo-1.hortonworks.com/AMBARI-1.x/repos/centos6/AMBARI-1.x-1.el6.noarch.rpm
  # Upgrading from 1.2 to 1.2.1 by replacing repo file (http://incubator.apache.org/ambari/1.2.1/installing-hadoop-using-ambari/content/ambari-chap7.html)
  # http://public-repo-1.hortonworks.com/ambari/centos6/1.x/GA/ambari.repo
  # Install 1.2.1 with rpm (http://incubator.apache.org/ambari/1.2.1/installing-hadoop-using-ambari/content/ambari-chap2-1.html)
  # http://public-repo-1.hortonworks.com/ambari/centos6/1.x/GA/ambari-1.2.0.1-1.el6.noarch.rpm
  ctx.config.ambari.proxy ?= ctx.config.proxy.http_proxy
  ctx.config.ambari.http ?= '/var/www/html'
  ctx.config.ambari.repo ?= 'http://public-repo-1.hortonworks.com/ambari/centos6/1.x/GA/ambari.repo'
  ctx.config.ambari.config ?= {}
  ctx.config.ambari.config_path ?= '/etc/ambari-server/conf/ambari.properties'
  # ctx.config.ambari.java ?= null
  ctx.config.ambari.java ?= 'http://public-repo-1.hortonworks.com/ARTIFACTS/jdk-6u31-linux-x64.bin'
  ctx.config.ambari.local ?= 
    '1.2.0':
      'centos6,redhat6,oraclelinux6': [
        baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/GA/1.2.0'
        repoid: 'HDP-1.3.0'
        reponame: 'HDP'
      ,
        baseurl: 'HDP-epel'
        repoid: 'HDP-epel'
        reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch]]>'
      ]
      'centos6,redhat5,oraclelinux5': [
        baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos5/1.x/GA/1.2.0'
        repoid: 'HDP-1.3.0'
        reponame: 'HDP'
      ,
        baseurl: 'HDP-epel'
        repoid: 'HDP-epel'
        reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-5&arch=$basearch]]>'
      ]
      'suse11,sles11': [
        baseurl: 'http://public-repo-1.hortonworks.com/HDP/suse11/1.x/GA/1.2.0'
        repoid: 'HDP-1.3.0'
        reponame: 'HDP'
      ]
    '1.2.1':
      'centos6,redhat6,oraclelinux6': [
        baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/GA/1.2.1'
        repoid: 'HDP-1.3.0'
        reponame: 'HDP'
      ,
        baseurl: 'HDP-epel'
        repoid: 'HDP-epel'
        reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch]]>'
      ]
      'centos6,redhat5,oraclelinux5': [
        baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos5/1.x/GA/1.2.1'
        repoid: 'HDP-1.3.0'
        reponame: 'HDP'
      ,
        baseurl: 'HDP-epel'
        repoid: 'HDP-epel'
        reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-5&arch=$basearch]]>'
      ]
      'suse11,sles11': [
        baseurl: 'http://public-repo-1.hortonworks.com/HDP/suse11/1.x/GA/1.2.1'
        repoid: 'HDP-1.3.0'
        reponame: 'HDP'
      ]
    '1.3.0':
      'centos6,redhat6,oraclelinux6': [
        baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/GA/1.3.0.0'
        repoid: 'HDP-1.3.0'
        reponame: 'HDP'
      ,
        baseurl: 'HDP-epel'
        repoid: 'HDP-epel'
        reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch]]>'
      ]
      'centos6,redhat5,oraclelinux5': [
        baseurl: 'http://public-repo-1.hortonworks.com/HDP/centos5/1.x/GA/1.3.0.0'
        repoid: 'HDP-1.3.0'
        reponame: 'HDP'
      ,
        baseurl: 'HDP-epel'
        repoid: 'HDP-epel'
        reponame: '<![CDATA[http://mirrors.fedoraproject.org/mirrorlist?repo=epel-5&arch=$basearch]]>'
      ]
      'suse11,sles11': [
        baseurl: 'http://public-repo-1.hortonworks.com/HDP/suse11/1.x/GA/1.3.0.0'
        repoid: 'HDP-1.3.0'
        reponame: 'HDP'
      ]

###
Local repo
----------

Update the repository declaration files used by Ambari in local 
mode. Those files location match the pattern "/var/lib/ambari-server/resources/stacks/HDPLocal/{version}/repos/repoinfo.xml".

We choose to regenerate all the metainfo.xml files base 
on internal configuration. This action may be skipped if the configuration
property "ambari.local" is set to `false`.
###
module.exports.push (ctx, next) ->
  {local} = ctx.config.ambari
  return next() unless local
  @name 'Ambari Server # Local repo'
  writes = []
  for version of local
    markup = builder.create 'reposinfo', version: '1.0', encoding: 'UTF-8'
    for platforms, config of local[version]
      for platform in platforms.split ','
        os = markup.ele 'os', type: platform
        for conf in config
          repo = os.ele 'repo'
          for k, v of conf
            repo.ele k, null, v
    writes.push
      content: markup.end pretty: true
      destination: "/var/lib/ambari-server/resources/stacks/HDPLocal/#{version}/repos/repoinfo.xml"
  ctx.write writes, (err, written) ->
    next err, if written then ctx.OK else ctx.PASS


###
Repository
----------
Declare the Ambari custom repository.
###
module.exports.push (ctx, next) ->
  {proxy, repo} = ctx.config.ambari
  # Is there a repo to download and install
  return next() unless repo
  @name 'Ambari Server # Repo'
  @timeout -1
  ctx.log "Download #{repo} to /etc/yum.repos.d/ambari.repo"
  u = url.parse repo
  ctx[if u.protocol is 'http:' then 'download' else 'upload']
    source: repo
    # local_source: true
    proxy: proxy
    destination: '/etc/yum.repos.d/ambari.repo'
  , (err, downloaded) ->
    return next err if err
    return next null, ctx.PASS unless downloaded
    ctx.log 'Clean up metadata and update'
    ctx.execute
      cmd: "yum clean metadata; yum update -y"
    , (err, executed) ->
      next err, ctx.OK

###
Package
-------
Install Ambari server package.
###
module.exports.push (ctx, next) ->
  @name 'Ambari Server # Package'
  @timeout -1
  ctx.service
    name: 'ambari-server'
    startup: true
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

###
Configuration
-----
Merge used defined configuration. This could be used to set up 
LDAP or Active Directory Authentication.
###
module.exports.push (ctx, next) ->
  @name 'Ambari Server # Config'
  @timeout -1
  {config, config_path} = ctx.config.ambari
  misc.file.readFile ctx.ssh, config_path, (err, properties) ->
    return next err if err
    properties = ini.parse properties
    properties = misc.merge {}, properties, config
    ctx.write
      destination: config_path
      content: ini.stringify properties
      backup: true
    , (err, written) ->
      next err, if written then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {proxy, java} = ctx.config.ambari
  # return next() if not proxy and not java
  return next() unless java
  @name 'Ambari Server # Java'
  @timeout -1
  action = if url.parse(java).protocol is 'http:' then 'download' else 'upload'
  ctx.log "Java #{action} from #{java}"
  ctx[action]
    source: java
    proxy: proxy
    destination: '/var/lib/ambari-server/resources/jdk-6u31-linux-x64.bin'
    not_if_exists: true # was not uploading, so i manually placed the jdk file and added this option 
  , (err, downloaded) ->
    next err, if downloaded then ctx.OK else ctx.PASS

###
Install
-------
Install and configure the Ambari server.
###
module.exports.push (ctx, next) ->
  @name 'Ambari Server # Install'
  @timeout -1
  {username, password} = ctx.config.ambari
  username = (username or '') + '\n'
  password = (password or '') + '\n'
  ctx.execute
    cmd: 'nc 127.0.0.1 8080 </dev/null'
    code: 1
    code_skipped: 0
  , (err, executed) ->
    # 1 means no server answering
    return next null, ctx.PASS if err?.code is 0
    return next err if err
    ctx.ssh.shell (err, stream) ->
      stream.write 'ambari-server setup\n'
      stream.on 'data', (data) ->
        ctx.log.out.write data
        if /OK to continue \[y\/n\]/.test data
          stream.write 'y\n'
        if /database configuration \[y\/n\]/.test data
          stream.write 'y\n'
        if /Select database/.test data
          stream.write '1\n'
        if /Database Name/.test data
          stream.write '\n'
        if /Username/.test data # ambari-server
          stream.write username
        if /Password/.test data # bigdata
          stream.write password
        if /Re-enter password/.test data # bigdata
          stream.write password
        if /Oracle Binary Code License Agreement \[y\/n\]/.test data
          stream.write 'y\n'
        if /download the JDK \[y\/n\]/.test data
          stream.write 'n\n'
        if /finished successfully/.test data
          next null, ctx.OK
        if /ERROR/.test data
          next new Error data

###
Start
-----
Start the Ambari server.
###
module.exports.push (ctx, next) ->
  @name 'Ambari Server # Start'
  @timeout -1
  ctx.execute
    cmd: 'ambari-server start'
  , (err, executed, stdout) ->
    next err, unless /already running/.test stdout then ctx.OK else ctx.PASS

