FROM alpine/git AS install

RUN echo "unknown" > /git-version.txt

COPY . /git/

RUN find . -type d -name .git -exec git describe --always --dirty > /git-version.txt \;

FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       gnupg \
    && mkdir -p /usr/share/keyrings \
    && curl -fsSL https://repo.zabbix.com/zabbix-official-repo.key \
       | gpg --dearmor -o /usr/share/keyrings/zabbix.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/zabbix.gpg] https://repo.zabbix.com/zabbix/8.0/debian bookworm main" \
       > /etc/apt/sources.list.d/zabbix.list \
    && curl -fsSL https://download.ceph.com/keys/release.asc \
       | gpg --dearmor -o /usr/share/keyrings/ceph.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/ceph.gpg] https://download.ceph.com/debian-20.2.4 bookworm main" \
       > /etc/apt/sources.list.d/ceph.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       ceph \
       zabbix-agent2 \
       zabbix-agent2-plugin-ceph \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=install /git-version.txt /git-version.txt

EXPOSE 10051/tcp

ENTRYPOINT ["/usr/sbin/zabbix_agent2"]
CMD ["-f", "-c", "/etc/zabbix/zabbix_agent2.conf"]