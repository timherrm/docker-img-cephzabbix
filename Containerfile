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
    && curl -O /etc/apt/keyrings/zabbix.asc https://repo.zabbix.com/zabbix-official-repo.key \
    && chmod 0644 /etc/apt/keyrings/zabbix.asc \
    && printf '%s\n' \
    'Components: main' \
    'x-repolib-Name: zabbix-agent2' \
    'Signed-By: /etc/apt/keyrings/zabbix.asc' \
    'Suites: trixie' \
    'Types: deb' \
    'URIs: https://repo.zabbix.com/zabbix/8.0/unstable/debian' \
    > /etc/apt/sources.list.d/zabbix-agent2.sources \
    && apt update \
    && apt install zabbix-agent2 zabbix-agent2-plugin-ceph 

COPY --from=install /git-version.txt /git-version.txt

EXPOSE 10051/tcp

ENTRYPOINT ["/usr/sbin/zabbix_agent2"]
CMD ["-f", "-c", "/etc/zabbix/zabbix_agent2.conf"]