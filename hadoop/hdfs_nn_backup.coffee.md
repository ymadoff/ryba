
# HDFS NameNode Backup

comprendre les proprietes de sauvegarde des 2 fsimages et trouver la proprietes du laps de temps entre 2 creations.

Use `hdfs oiv` (can run offline)
hdfs oiv -p FileDistribution -i /var/hdfs/name/current/fsimage_0000000000000023497 -o test_fd
hdfs oiv -p Ls -i /var/hdfs/name/current/fsimage_0000000000000023497 -o test_ls

Look at `hdfs oev`

Use `curl` to download image and edit logs:
https://<namenode>:500470/getimage?getimage=1&txid=latest
https://<namenode>:50470/getimage?getedit=1&startTxId=X&endTxId=Y

dfsadmin -fetchImage

Loog at Hortonworks upgrade
http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_installing_manually_book/content/upgrade-2-4-1.html