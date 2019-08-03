# docker-rsync

A `rsyncd`/`sshd` server in Docker for moving files.


Start a server (both `sshd` and `rsyncd` are supported)

```
$ docker run \
    --name rsync \ # Name it
    -p 8873:873 \ # rsyncd port
    -p 8022:22 \ # sshd port
    -e RSYNC_USERNAME=rsync_user \ # rsync username
    -e RSYNC_PASSWORD=rsync_user_pass \ # rsync/ssh password
    -v /path/to/authorized_keys_or_public_key:/root/.ssh/authorized_keys \ # your public key
    cirepo/rsync
```

#### `rsyncd`

Please note that `/${RSYNC_VOLUME_NAME:-volume}` is the `rsync` volume pointing to `/data`. The data
will be at `/data` in the container. Use the `RSYNC_VOLUME_PATH` parameter to change the
destination path in the container. Even when changing `RSYNC_VOLUME_PATH`, you will still
`rsync` to `/${RSYNC_VOLUME_NAME:-volume}`.

```
$ rsync -av local/directory/ rsync://rsync_user@localhost:8873/volume
Password: rsync_user_pass
sending incremental file list
./
foo/
foo/bar/
foo/bar/hi.txt

sent 166 bytes  received 39 bytes  136.67 bytes/sec
total size is 0  speedup is 0.00
```
e.g. `rsync -av ../docker-redis/ rsync://rsync_user@localhost:8873/volume/docker-redis`


#### `sshd`

Please note that you are connecting as the `root` and not the user specified in
the `RSYNC_USERNAME` variable. If you don't supply a key file you will be prompted
for the `RSYNC_PASSWORD`.

```
$ rsync -av -e "ssh -i /path/to/private_key -p 8022 -l root" local/directory/ localhost:/data
sending incremental file list
./
foo/
foo/bar/
foo/bar/hi.txt

sent 166 bytes  received 31 bytes  131.33 bytes/sec
total size is 0  speedup is 0.00
```


### Advanced Usage

Variable options (on run)

* `RSYNC_USERNAME`    - the `rsync` username. defaults to `rsync_user`
* `RSYNC_PASSWORD`    - the `rsync` password. defaults to `rsync_user_pass`
* `RSYNC_VOLUME_PATH` - the path for `rsync`. defaults to `/data`
* `RSYNC_HOSTS_ALLOW` - space separated list of allowed sources. defaults to `192.168.0.0/16 172.16.0.0/12 127.0.0.1/32`.


##### Simple server on port 873

```
$ docker run -p 873:873 cirepo/rsync
```


##### Use a volume for the default `/data`

```
$ docker run -p 8873:873 -v /path/to/data:/data cirepo/rsync
```

##### Set a username and password

```
$ docker run \
    -p 8873:873 \
    -v /path/to/data:/data \
    -e RSYNC_USERNAME=rsync_user \
    -e RSYNC_PASSWORD=rsync_user_pass \
    cirepo/rsync
```

##### Run on a custom port

```
$ docker run \
    -p 8873:873 \
    -v /path/to/data:/data \
    -e RSYNC_USERNAME=rsync_user \
    -e RSYNC_PASSWORD=rsync_user_pass \
    cirepo/rsync
```

```
$ rsync rsync://rsync_user@localhost:8873
volume            /data directory
```


##### Modify the default volume location

```
$ docker run \
    -p 8873:873 \
    -v /path/to/data:/data \
    -e RSYNC_USERNAME=rsync_user \
    -e RSYNC_PASSWORD=rsync_user_pass \
    -e RSYNC_VOLUME_PATH=/data \
    cirepo/rsync
```

```
$ rsync rsync://admin@localhost:9999
volume            /data directory
```

##### Allow additional client IPs

```
$ docker run \
    -p 8873:873 \
    -v /path/to/data:/data \
    -e RSYNC_USERNAME=rsync_user \
    -e RSYNC_PASSWORD=rsync_user_pass \
    -e RSYNC_VOLUME_PATH=/data \
    -e RSYNC_HOSTS_ALLOW=192.168.0.0/24 192.168.1.0/24 192.168.8.0/24 192.168.24.0/24 172.16.0.0/12 127.0.0.1/32 \
    cirepo/rsync
```


##### Over SSH

If you would like to connect over ssh, you may mount your public key or
`authorized_keys` file to `/root/.ssh/authorized_keys`.

Without setting up an `authorized_keys` file, you will be propted for the
password (which was specified in the `RSYNC_PASSWORD` variable).

Please note that when using `sshd` **you will be specifying the actual folder
destination as you would when using SSH.** On the contrary, when using the
`rsyncd` daemon, you will always be using `/${RSYNC_VOLUME_NAME:-volume}`, which maps to `RSYNC_VOLUME_PATH`
inside of the container.

```
docker run \
    -v /your/folder:/myvolume \
    -e RSYNC_USERNAME=rsync_user \
    -e RSYNC_PASSWORD=rsync_user_pass \
    -e RSYNC_VOLUME_PATH=/data \
    -e RSYNC_HOSTS_ALLOW=192.168.8.0/24 192.168.24.0/24 172.16.0.0/12 127.0.0.1/32 \
    -v /path/to/authorized_keys_or_public_key:/root/.ssh/authorized_keys \
    -p 8022:22 \
    cirepo/rsync
```

```
$ chmod 0400 data/dot_ssh/id_rsa data/dot_ssh/id_rsa-passphrase
$ rsync -av -e "ssh -i /path/to/private_key -p 8022 -l root" local/directory/ localhost:/data
```
e.g. `rsync -av -e "ssh -i ${PWD}/data/dot_ssh/id_rsa -p 8022 -l root" ../docker-redis/ localhost:/data/docker-redis/`
e.g. `scp -i ${PWD}/data/dot_ssh/id_rsa -o StrictHostKeyChecking=no -P 8022 -r ../docker-redis root@localhost:/data/`

### Resources

https://github.com/axiom-data-science/rsync-server
