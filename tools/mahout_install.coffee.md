
# Mahout

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require '../lib/hdp_select'

http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm-chap5-1.html

    module.exports.push name: 'Hadoop Mahout # Install', timeout: -1, handler: (ctx, next) ->
      ctx
      .service
        name: 'mahout'
      .hdp_select
        name: 'mahout-client'
        version: 'latest'
      .then next