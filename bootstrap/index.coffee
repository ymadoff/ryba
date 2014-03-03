###
bootstrap
=========

Bootstrap will initialize an SSH connection accessible 
throught the context object as `ctx.ssh`. The connection is 
initialized with the root user.
###

module.exports = []

# module.exports.push name: 'Bootstrap # WAIT', callback: (ctx, next) ->
#   toto = 'yo'
#   setInterval ->
#     lulu = 'yu'
#   , 10000

# module.exports.push name: 'Bootstrap # Cache', callback: (ctx, next) ->
#   ctx.config.bootstrap.cache ?= {}
#   location = ctx.config.bootstrap.cache.location or './tmp'
#   mecano.mkdir
#     destination: location
#   , (err, created) ->
#     if ctx.shared.cache
#       ctx.cache = ctx.shared.cache
#       return next null, ctx.PASS
#     db = leveldb location
#     ctx.cache = ctx.shared.cache =
#       db: db
#       put: (key, value, callback) ->
#         db.put key, value, callback
#       get: (key, callback) ->
#         db.get key, callback
#     next null, ctx.PASS

module.exports.push 'phyla/bootstrap/cache_file'

module.exports.push 'phyla/bootstrap/log'

module.exports.push 'phyla/bootstrap/utils'

module.exports.push 'phyla/bootstrap/connection'

module.exports.push 'phyla/bootstrap/info'

module.exports.push 'phyla/bootstrap/mecano'












