
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

    module.exports = header: 'HDFS NN Backup', timeout: -1, label_true: 'BACKUPED', handler: ->
      {hdfs} = @config.ryba

      @tools.remove
        header: 'HDFS LS output'
        name: 'ls'
        cmd: 'hdfs dfs -ls -R / '
        target: "/var/backups/nn_#{@config.host}/"
        interval: month: 1
        retention: count: 2

      any_dfs_name_dir = hdfs.nn.site['dfs.namenode.name.dir'].split(',')[0]
      any_dfs_name_dir = any_dfs_name_dir.substr(7) if any_dfs_name_dir.indexOf('file://') is 0
      @tools.remove
        header: 'FSimages & edits'
        name: 'fs'
        source: path.join any_dfs_name_dir, 'current'
        filter: ['fsimage_*','edits_0*']
        target: "/var/backups/nn_#{@config.host}/"
        interval: month: 1
        retention: count: 2

### Restoration procedure

To restore the fsimage as it was at the date of backup with a shell command
with default configuration value:
```bash
cd /var/hdfs/name/current/
rm -rf *
tar -xzf /var/backups/nn_$HOSTNAME/<backup_date>.tar.gz
```

`man tar` for more information if you have changed default options

## Dependencies

    path = require 'path'
