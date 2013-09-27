
fs = require 'fs'
properties = require '../lib/properties'
should = require 'should'

describe 'properties', ->

  it 'parse', (next) ->
    fs.readFile "#{__dirname}/resources/core.xml", (err, xml) ->
      result = properties.parse xml
      result.should.eql
        'fs.defaultFS': 'hdfs://namenode:8020'
        'io.file.buffer.size': '65536'
      next()

  it 'stringify', (next) ->
    fs.readFile "#{__dirname}/resources/core.xml", 'utf8', (err, xml) ->
      properties.stringify(
        'fs.defaultFS': 'hdfs://namenode:8020'
        'io.file.buffer.size': '65536'
      ).should.eql xml
      properties.stringify([
        {name: 'fs.defaultFS', value: 'hdfs://namenode:8020'}
        {name: 'io.file.buffer.size', value: '65536'}
      ]).should.eql xml
      next()

  it.only 'stringify and order', (next) ->
    fs.readFile "#{__dirname}/resources/core.xml", 'utf8', (err, xml) ->
      properties.stringify(
        'io.file.buffer.size': '65536'
        'fs.defaultFS': 'hdfs://namenode:8020'
      ).should.eql xml
      properties.stringify([
        {name: 'io.file.buffer.size', value: '65536'}
        {name: 'fs.defaultFS', value: 'hdfs://namenode:8020'}
      ]).should.eql xml
      next()

  it 'read', (next) ->
    properties.read "#{__dirname}/resources/core.xml", (err, result) ->
      should.not.exist err
      result.should.eql
        'fs.defaultFS': 'hdfs://namenode:8020'
        'io.file.buffer.size': '65536'
      next()

  it 'write', (next) ->
    fs.readFile "#{__dirname}/resources/core.xml", 'utf8', (err, expect) ->
      content = 
        'fs.defaultFS': 'hdfs://namenode:8020'
        'io.file.buffer.size': '65536'
      properties.write '/tmp/node-hadoop-properties.xml', content, (err) ->
      fs.readFile '/tmp/node-hadoop-properties.xml', 'utf8', (err, result) ->
        should.not.exist err
        result.should.eql expect
        next()
