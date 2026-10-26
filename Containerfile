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
    && touch /etc/apt/sources.list.d/zabbix.list\
    && echo "Components: main \ X-Repolib-Name: zabbix-agent2 \ Signed-By: /etc/apt/keyrings/zabbix.asc \ Suites: trixie \ Types: deb \ URIs: https://repo.zabbix.com/zabbix/8.0/unstable/debian" >>  /etc/apt/sources.list.d/zabbix.list\
    && apt install zabbix-agent2 zabbix-agent2-plugin-ceph\
    && apt clean

# Copy git-verion.txt from install step
COPY --from=install /git-version.txt /git-version.txt

EXPOSE 10051/tcp

ENTRYPOINT ["/usr/sbin/zabbix_agent2"]
CMD ["-f", "-c", "/etc/zabbix/zabbix_agent2.conf"]
