
# Oozie Server Doctor

## Upgrade error

Run `yum remove -y oozie oozie-client` before `ryba install` if you see this
error:

```
Running Transaction
  Updating   : oozie-4.0.0.2.1.5.0-695.el6.noarch                                                                                                                                                   1/2
Error unpacking rpm package oozie-4.0.0.2.1.5.0-695.el6.noarch
error: unpacking of archive failed on file /usr/lib/oozie/webapps/oozie/WEB-INF: cpio: rename
  Verifying  : oozie-4.0.0.2.1.5.0-695.el6.noarch                                                                                                                                                   1/2
oozie-4.0.0.2.1.2.0-402.el6.noarch was supposed to be removed but is not!
  Verifying  : oozie-4.0.0.2.1.2.0-402.el6.noarch
```
