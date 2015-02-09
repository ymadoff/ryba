
# Hadoop HDFS NameNode Backup

comprendre les proprietes de sauvegarde des 2 fsimages et trouver la proprietes du laps de temps entre 2 creations.

## HDFS cli

### OIV

can dump content of HDFS fsimages

Use `hdfs oiv` (can run offline)
hdfs oiv -p FileDistribution -i /var/hdfs/name/current/fsimage_0000000000000023497 -o test_fd
hdfs oiv -p Ls -i /var/hdfs/name/current/fsimage_0000000000000023497 -o test_ls

### OEV

can load content of HDFS fsimages dump 

## Curl

Use `curl` to download image and edit logs:
https://<namenode>:50470/getimage?getimage=1&txid=latest
https://<namenode>:50470/getimage?getedit=1&startTxId=X&endTxId=Y

dfsadmin -fetchImage

## Node-backmeup

### Local Backup

    util = require 'util'
    
    module.exports = []
    
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push require('./hdfs_nn').configure
    path = require 'path'

    # isRelative = () ->
    #   filepath = path.join.apply path, arguments
    #   return path.resolve(filepath) isnt filepath.replace(/[\/\\]+$/, ''\

    module.exports.push name: "HDFS NN # Backup HDFS LS output", timeout: -1, label_true: 'BACKUPED', handler: (ctx, next) ->
      ls =
        name: 'ls'
        cmd: 'hdfs dfs -ls -R / '
        destination: "/var/backups/nn_#{ctx.config.host}/"
        interval: month: 1
        retention: count: 2
      ctx.backup ls, next

    module.exports.push name: 'HDFS NN # Backup FSimages & edits', timeout: -1, label_true: 'BACKUPED', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      fs =
        name: 'fs'
        source: path.join hdfs.site['dfs.namenode.name.dir'].split(',').shift(), 'current'
        filter: ['fsimage_*','edits_0*']
        destination: "/var/backups/nn_#{ctx.config.host}/"
        interval: month: 1 
        retention: count: 2
      ctx.backup fs, next

### Restoration procedure

To restore the fsimage as it was at the date of backup with a shell command 
with default configuration value:
```bash
cd /var/hdfs/name/current/
rm -rf *
tar -xzf /var/backups/nn_$HOSTNAME/<backup_date>.tar.gz
```

`man tar` for more information if you have changed default options