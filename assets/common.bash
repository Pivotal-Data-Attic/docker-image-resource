start_docker() {
  mkdir -p /var/log
  mkdir -p /var/run

  # set up cgroups
  mkdir -p /sys/fs/cgroup
  mountpoint -q /sys/fs/cgroup || \
    mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup

  for d in `sed -e '1d;s/\([^\t]\)\t.*$/\1/' /proc/cgroups`; do
    mkdir -p /sys/fs/cgroup/$d
    mountpoint -q /sys/fs/cgroup/$d || \
      mount -n -t cgroup -o $d cgroup /sys/fs/cgroup/$d
  done

  # docker graph dir
  mkdir -p /var/lib/docker
  mount -t tmpfs -o size=10G none /var/lib/docker

  if [ $(jq -r '.source | has("registry")') = "true" ]; then
    local registry=$(jq -r '.source.registry' < $payload)

    docker -d --insecure-registry $registry >/dev/null 2>&1 &
  else
    docker -d > /dev/null 2>&1 &
  fi

  sleep 1

  until docker info >/dev/null 2>&1; do
    echo waiting for docker to come up...
    sleep 1
  done
}

docker_image() {
  docker images --no-trunc "$1" | awk "{if (\$2 == \"$2\") print \$3}"
}
