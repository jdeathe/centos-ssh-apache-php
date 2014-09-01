# Command Keys

Using command keys to access containers (without sshd).

Access docker containers using docker host SSH public key authentication and nsenter command to start up a bash terminal inside a container. In the following example the container name is "apache-php.app-1.1.1"

## Create a unique public/private key pair for each container

```
$ cd ~/.ssh/ && ssh-keygen -q -t rsa -f id-rsa.apache-php.app-1.1.1
```

## Prefix the public key with the nsenter command

```
$ sed -i '' \
  '1s#^#command="sudo nsenter -m -u -i -n -p -t $(docker inspect --format \\\"{{ .State.Pid }}\\\" apache-php.app-1.1.1) /bin/bash" #' \
  ~/.ssh/id-rsa.apache-php.app-1.1.1.pub
```

## Upload the public key to the docker host VM

The host in this example is core-01.local that has SSH public key authentication enabled using the Vagrant insecure private key.

### Generic Linux Host Example

```
$ cat ~/.ssh/id-rsa.apache-php.app-1.1.1.pub | ssh -i ~/.vagrant.d/insecure_private_key \
  core@core-01.local \
  "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### CoreOS Host Example

```
$ cat ~/.ssh/id-rsa.apache-php.app-1.1.1.pub | ssh -i ~/.vagrant.d/insecure_private_key \
  core@core-01.local \
  update-ssh-keys -a core@apache-php.app-1.1.1
```
