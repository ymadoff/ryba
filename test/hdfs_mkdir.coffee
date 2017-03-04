
nikita = require 'nikita'

describe 'hdfs mkdir', ->

  it 'create a dir with default permission and ownership', (next) ->
    nikita require './config.coffee'
    .register 'hdfs_mkdir', require '../lib/hdfs_mkdir'
    .register 'kexecute', require '../lib/kexecute'
    .kexecute cmd: """
      dir='/user/ryba/nikita'
      if hdfs dfs -test -d $dir; then hdfs dfs -rm -r -skipTrash $dir; fi
      """
    .hdfs_mkdir
      # stdout: process.stdout
      # stderr: process.stderr
      target: "/user/ryba/nikita/a/dir"
    .kexecute cmd: """
      hdfs dfs -test -d /user/ryba/nikita/a/dir
      hdfs dfs -stat '%g;%u;%n' /user/ryba/nikita/a/dir
      hdfs dfs -ls /user/ryba/nikita/a/ | grep /user/ryba/nikita/a/dir | sed 's/\\(.*\\)   -.*/\\1/'
      """
    , (err, status, stdout) ->
      string.lines(stdout.trim()).should.eql [
        'ryba;ryba;dir'
        'drwxr-x---'
      ]
    .then next

  it.only 'detect status', (next) ->
    nikita require './config.coffee'
    .register 'hdfs_mkdir', require '../lib/hdfs_mkdir'
    .register 'kexecute', require '../lib/kexecute'
    .kexecute cmd: """
      dir='/user/ryba/nikita'
      if hdfs dfs -test -d $dir; then hdfs dfs -rm -r -skipTrash $dir; fi
      """
    .hdfs_mkdir
      target: "/user/ryba/nikita/dir"
    , (err, status) ->
      status.should.be.true() unless err
    .hdfs_mkdir
      target: "/user/ryba/nikita/dir"
    , (err, status) ->
      status.should.be.false() unless err
    .then next

string = require 'nikita/lib/misc/string'
