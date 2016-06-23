### Setup Setuptools, Pip & packages

yum install -y centos-release-SCL zlib-devel
yum install -y python27

**All nodes**

```
mkdir ~/tmp; cd ~/tmp
wget https://pypi.python.org/packages/source/s/setuptools/setuptools-18.3.2.tar.gz#md5=d30c969065bd384266e411c446a86623
tar -xf setuptools-18.3.2.tar.gz
cd setuptools-18.3.2
python setup.py install

# pip
rm -rf ~/tmp; mkdir ~/tmp; cd ~/tmp
wget https://pypi.python.org/packages/source/p/pip/pip-7.1.2.tar.gz#md5=3823d2343d9f3aaab21cf9c917710196
tar -xf pip-7.1.2.tar.gz
cd pip-7.1.2
python setup.py install
echo "export PATH=\$PATH:/opt/rh/python27/root/usr/bin" >> ~/.bashrc
source ~/.bashrc

# packages
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ fuzzywuzzy
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ jellyfish
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ six # for dateutil
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ unicodecsv
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ python-dateutil # for pandas
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ pytz # for pandas
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ jinja2
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ pygments
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ numpy
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ scipy
pip install --no-index --trusted-host 172.16.100.3 --find-links=http://172.16.100.3/pypi/ pandas
```
