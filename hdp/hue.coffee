
# path = require 'path'
# lifecycle = require './lib/lifecycle'
# mkcmd = require './lib/mkcmd'

###


Resources:   
*   [Hortonworks instruction](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue.html)

###
module.exports = []

module.exports.push 'histi/actions/mysql_server'
module.exports.push 'histi/hdp/hdfs'
module.exports.push 'histi/hdp/yarn'
module.exports.push 'histi/hdp/oozie_client'
module.exports.push 'histi/hdp/hive_client'
module.exports.push 'histi/hdp/hbase'

module.exports.push (ctx) ->
  require './webhcat'
  ctx.config.hdp.hue_conf_dir ?= '/etc/hue/conf'
  ctx.config.hdp.hue_ini ?= {}
  ctx.config.hdp.hue_ini['http_host'] ?= '0.0.0.0'
  ctx.config.hdp.hue_ini['http_port'] ?= '8000'
  ctx.config.hdp.hue_ini['secret_key'] ?= 'jFE93j;2[290-eiw.KEiwN2sfer.q[eIW^y#e=+Iei*@Mn<qW5o'

module.exports.push name: 'HDP Hue # Packages', timeout: -1, callback: (ctx, next) ->
  ctx.service [
    name: 'extjs-2.2-1'
  ,
    name: 'hue'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hue # Configure', callback: (ctx, next) ->
  {hue_conf_dir, hue_ini} = ctx.config.hdp
  write = for k, v of hue_ini
    match: new RegExp "^( *)(#{k}.*)$", 'mg'
    replace: "$1#{k}=#{v}"
    append: true
  ctx.write
    destination: "#{hue_conf_dir}/hue.ini"
    write: write
    backup: true
  , (err, written) ->
    next err, if written then ctx.OK else ctx.PASS

###
TODO: install Hue over SSL
http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-1.html
###
# module.exports.push name: 'HDP Hue # SSL', (ctx, next) ->
#   {hue_conf_dir, hue_ini} = ctx.config.hdp
#   ctx.execute
#     destination: "#{hue_conf_dir}/build/env/bin/easy_install"
#     write: write
#     backup: true
#   , (err, written) ->
#     next err, if written then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hue # Core', callback: (ctx, next) ->
  {hadoop_conf_dir, hadoop_user, hadoop_group} = ctx.config.hdp
  properties = 
    'hadoop.proxyuser.hue.hosts': '*'
    'hadoop.proxyuser.hue.groups': '*'
    'hadoop.proxyuser.hcat.groups': '*'
    'hadoop.proxyuser.hcat.hosts': '*'
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/core-site.xml"
    properties: properties
    merge: true
  , (err, configured) ->
    return next err if err
    next err, if configured then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hue # WebHCat', callback: (ctx, next) ->
  {webhcat_conf_dir, webhcat_user, hadoop_group} = ctx.config.hdp
  properties = 
    'webhcat.proxyuser.hue.hosts': '*'
    'webhcat.proxyuser.hue.groups': '*'
  ctx.hconfigure
    destination: "#{webhcat_conf_dir}/webhcat-site.xml"
    properties: properties
    merge: true
  , (err, configured) ->
    return next err if err
    next err, if configured then ctx.OK else ctx.PASS


