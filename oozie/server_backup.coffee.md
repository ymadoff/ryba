
# Oozie Server Backup

Note: to backup the oozie database in oozie, we must add the "hex-blob" option or 
we get an error while importing data. The mysqldump command does not escape all
charactere and the xml stored inside the database create syntax issues. Here's
an example:

```bash
mysqldump -uroot -ptest123 --hex-blob oozie > /data/1/oozie.sql
```