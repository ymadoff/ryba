
module.exports = []
module.exports.push 'phyla/bootstrap'

###
http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm-chap5-1.html
###
module.exports.push name: 'HDP Mahout # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'mahout'
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS