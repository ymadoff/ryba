
# Routine script top prepare environment

## Source Code


    module.exports = ->
      #mods = ['ryba/zeppelin/prepare']
      mods = ['ryba/huedocker/prepare']
      filename_stdout = 'prepare.stdout.log'
      filename_stderr = 'prepare.stderr.log'
      # log = {}

      # log.stdout = fs.createWriteStream path.resolve './log', filename_stdout
      # log.stderr = fs.createWriteStream path.resolve './log', filename_stderr
      options = 
        log: console.log
        stdout: process.stdout
        stderr: process.stderr
        # stdout : fs.createWriteStream path.resolve './log', filename_stdout
        # stderr : fs.createWriteStream path.resolve './log', filename_stderr
      m = mecano options
      for mod in mods
        resolved = "#{__dirname}/../../../#{mod}"
        todos = require resolved
        todos = [todos] unless Array.isArray todos
        for middleware in todos
          m.call middleware, (err) ->
            #console.log err if err        
      m.then (err, modified) ->
        console.log err or 'SUCCEED'

## Dependencies

    mecano = require 'mecano'
    path = require 'path'
    fs = require 'fs'





