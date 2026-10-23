FROM alpine/git AS install

RUN echo "unknow" > /git-version.txt

# If the --dirty flag is left out, only the .git directory has to be copied
COPY . /git/

RUN find . -type d -name .git -exec git describe --always --dirty > /git-version.txt \;

FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       wget \
    && wget -O /tmp/zabbix-release.deb \
       https://repo.zabbix.com/zabbix/8.0/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_8.0+debian13_all.deb \
    && dpkg -i /tmp/zabbix-release.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       zabbix-agent2 \
       zabbix-agent2-plugin-ceph \
    && rm -f /tmp/zabbix-release.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy git-verion.txt from install step
COPY --from=install /git-version.txt /git-version.txt

EXPOSE 10050/tcp

ENTRYPOINT ["/usr/sbin/zabbix_agent2"]
CMD ["-f", "-c", "/etc/zabbix/zabbix_agent2.conf"]
