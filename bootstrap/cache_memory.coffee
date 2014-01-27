
fs = require 'fs'
each = require 'each'
misc = require 'mecano/lib/misc'
mecano = require 'mecano'

module.exports = []

module.exports.push name: 'Bootstrap # Memory Cache', callback: (ctx, next) ->
  ctx.config.bootstrap.cache ?= {}
  location = ctx.config.bootstrap.cache.location or './tmp'
  location = "#{location}/#{ctx.config.host}"
  ctx._cache ?= {}
  mecano.mkdir
    destination: location
  , (err, created) ->
    ctx.cache =
      cached: (key) ->
        key = misc.string.hash key
        ctx._cache[key]
      set: (key, value, callback) ->
        set = (key, value, callback) ->
          key = misc.string.hash key
          value = JSON.stringify value
          fs.writeFile "#{location}/#{key}", value, callback
        if arguments.length is 2
          [values, calback] = arguments
          each(Object.keys(values))
          .on 'item', (key, next) ->
            set key, values[key], next
          .on 'both', (err) ->
            calback err
        else
          set key, value, callback
      get: (keys, callback) ->
        console.log JSON.stringify keys
        s = Array.isArray keys
        keys = [keys] unless s
        for key in keys
          key = misc.string.hash key
        data = {}
        each(keys)
        .on 'item', (key, next) ->
          if ctx._cache[key]
            data[key] = ctx._cache[key] if ctx._cache[key]
            next()
          fs.readFile "#{location}/#{key}", (err, value) ->
            return next err if err and err.code isnt 'ENOENT'
            value = JSON.parse value if value
            data[key] = if err then null else value
            next()
        .on 'error', (err) ->
          callback err
        .on 'end', ->
          if s
          then callback null, data
          else callback null, data[keys[0]]
    next null, ctx.PASS