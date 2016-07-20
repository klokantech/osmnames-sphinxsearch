FROM debian:8

RUN apt-get -qq update && apt-get install -qq -y --no-install-recommends \
    ca-certificates \
    curl \
    libexpat1 \
    libpq5 \
    mysql-client \
    nginx \
    python \
    python-setuptools \
    python-pip \
    python-crypto \
    python-flask \
    python-pil \
    python-mysqldb \
    unixodbc \
    uwsgi \
    uwsgi-plugin-python

RUN curl -s \
    http://sphinxsearch.com/files/sphinxsearch_2.2.10-release-1~jessie_amd64.deb \
    -o /tmp/sphinxsearch.deb \
&& dpkg -i /tmp/sphinxsearch.deb \
&& rm /tmp/sphinxsearch.deb \
&& easy_install -q flask-cache \
&& pip install -q supervisor \
&& mkdir -p /var/log/sphinx \
&& mkdir -p /var/log/supervisord

VOLUME ["/data/"]

RUN apt-get clean \
&& apt-get -qq update \
&& apt-get install -qq -y --no-install-recommends \
    libsnappy-dev \
    autoconf \
    automake \
    libtool \
    pkg-config \
    build-essential \
    python-dev \
    unzip \
&& curl -L -s \
    https://github.com/openvenues/libpostal/archive/master.zip \
    -o /tmp/libpostal.zip \
&& unzip -q /tmp/libpostal.zip -d /usr/local/src \
&& cd /usr/local/src/libpostal-* \
&& ./bootstrap.sh \
&& ./configure --datadir=/data/ \
&& make \
&& make install \
&& ldconfig \
&& pip install postal \
&& apt-get purge -y \
    autoconf \
    automake \
    libtool \
    pkg-config \
    build-essential \
    python-dev \
    unzip \
&& apt-get autoremove -y


COPY conf/sphinx/*.conf /etc/sphinxsearch/
COPY conf/nginx/nginx.conf /etc/nginx/sites-available/default
COPY supervisor/*.conf /etc/supervisor/conf.d/
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY web /usr/local/src/websearch
COPY sample.tsv /
COPY sphinx-reindex.sh /

ENV SPHINX_PORT=9312 \
    SEARCH_MAX_COUNT=100 \
    SEARCH_DEFAULT_COUNT=20

EXPOSE 80
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
