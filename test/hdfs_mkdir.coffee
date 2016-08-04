
mecano = require 'mecano'

describe 'hdfs mkdir', ->
  
  it 'create a dir with default permission and ownership', (next) ->
    mecano require './config.coffee'
    .register 'hdfs_mkdir', require '../lib/hdfs_mkdir'
    .register 'kexecute', require '../lib/kexecute'
    .kexecute cmd: """
      dir='/user/ryba/mecano'
      if hdfs dfs -test -d $dir; then hdfs dfs -rm -r -skipTrash $dir; fi
      """
    .hdfs_mkdir
      # stdout: process.stdout
      # stderr: process.stderr
      target: "/user/ryba/mecano/a/dir"
    .kexecute cmd: """
      hdfs dfs -test -d /user/ryba/mecano/a/dir
      hdfs dfs -stat '%g;%u;%n' /user/ryba/mecano/a/dir
      hdfs dfs -ls /user/ryba/mecano/a/ | grep /user/ryba/mecano/a/dir | sed 's/\\(.*\\)   -.*/\\1/'
      """
    , (err, status, stdout) ->
      string.lines(stdout.trim()).should.eql [
        'ryba;ryba;dir'
        'drwxr-x---'
      ]
    .then next
      
  it.only 'detect status', (next) ->
    mecano require './config.coffee'
    .register 'hdfs_mkdir', require '../lib/hdfs_mkdir'
    .register 'kexecute', require '../lib/kexecute'
    .kexecute cmd: """
      dir='/user/ryba/mecano'
      if hdfs dfs -test -d $dir; then hdfs dfs -rm -r -skipTrash $dir; fi
      """
    .hdfs_mkdir
      target: "/user/ryba/mecano/dir"
    , (err, status) ->
      status.should.be.true() unless err
    .hdfs_mkdir
      target: "/user/ryba/mecano/dir"
    , (err, status) ->
      status.should.be.false() unless err
    .then next
    
string = require 'mecano/lib/misc/string'
