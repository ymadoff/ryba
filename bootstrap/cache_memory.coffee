
fs = require 'fs'
each = require 'each'
misc = require 'mecano/lib/misc'
mecano = require 'mecano'

module.exports = []

module.exports.push (ctx) ->
  ctx.config.bootstrap ?= {}
  ctx.config.bootstrap.cache ?= {}
  ctx.config.bootstrap.cache.location ?= "#{process.cwd()}/tmp"

module.exports.push name: 'Bootstrap # File Cache', callback: (ctx, next) ->
  ctx.config.bootstrap.cache ?= {}
  {location} = ctx.config.bootstrap.cache
  location = "#{location}/#{ctx.config.host}"
  ctx._cache ?= {}
  mecano.mkdir
    destination: location
  , (err, created) ->
    db = {}
    ctx.cache =
      cached: (key) -> false
      set: (key, value, callback) -> # nothing
        set = (key, value, callback) ->
          db[key] = value
          callback()
        if arguments.length is 2
          [values, calback] = arguments
          # for key, value of values
          #   db[key] = value
          each(Object.keys(values))
          .on 'item', (key, next) ->
            set key, values[key], next
          .on 'both', (err) ->
            calback err
        else
          callback()
      get: (keys, callback) ->
        s = Array.isArray keys
        keys = [keys] unless s
        data = {}
        for k in keys
          data[k] = db[k] if db[k]?
        if s
        then callback null, data
        else callback null, data[keys[0]]
    next null, ctx.PASS
