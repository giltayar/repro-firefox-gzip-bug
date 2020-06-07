FROM golang:latest

# COPY ./tcp-proxy .
# RUN go build -o bin/tcp-proxy ./tcp-proxy/cmd/tcp-proxy
COPY ./tcp-proxy /go/src/github.com/jpillora/go-tcp-proxy
WORKDIR /go/src/github.com/jpillora/go-tcp-proxy
RUN go get ./... && \
    CGO_ENABLED=0 GOOS=linux go build -o /tcp-proxy cmd/tcp-proxy/main.go

FROM ubuntu:bionic
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ARG RANDOM_BUILD_ARG=123444
ENV RANDOM_ENV_TO_FORCE_BUILD=${RANDOM_BUILD_ARG}


# Copied (with permission) from https://github.com/SeleniumHQ/docker-selenium/blob/master/NodeFirefox/Dockerfile
# License: https://github.com/SeleniumHQ/docker-selenium/blob/master/LICENSE.md
RUN apt-get update -y && \
    apt-get install -y wget


#==============================
# Locale and encoding settings
#==============================
# ENV LANG_WHICH en
# ENV LANG_WHERE US
# ENV ENCODING UTF-8
# ENV LANGUAGE ${LANG_WHICH}_${LANG_WHERE}.${ENCODING}
# ENV LANG ${LANGUAGE}
# # Layer size: small: ~9 MB
# # Layer size: small: ~9 MB MB (with --no-install-recommends)
# RUN apt-get -qqy update \
#   && apt-get -qqy --no-install-recommends install \
#     language-pack-en \
#     tzdata \
#     locales \
#   && locale-gen ${LANGUAGE} \
#   && dpkg-reconfigure --frontend noninteractive locales \
#   && apt-get -qyy autoremove \
#   && rm -rf /var/lib/apt/lists/* \
#   && apt-get -qyy clean


ENV FIREFOX_VERSION=latest

# FF
RUN FIREFOX_DOWNLOAD_URL=$(if [ $FIREFOX_VERSION = "latest" ] || [ $FIREFOX_VERSION = "nightly-latest" ] || [ $FIREFOX_VERSION = "devedition-latest" ]; then echo "https://download.mozilla.org/?product=firefox-$FIREFOX_VERSION-ssl&os=linux64&lang=en-US"; else echo "https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2"; fi) \
  && apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install firefox libavcodec-extra \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
  && wget --no-verbose -O /tmp/firefox.tar.bz2 $FIREFOX_DOWNLOAD_URL \
  && apt-get -y purge firefox \
  && rm -rf /opt/firefox \
  && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
  && rm /tmp/firefox.tar.bz2 \
  && mv /opt/firefox /opt/firefox-$FIREFOX_VERSION \
  && ln -fs /opt/firefox-$FIREFOX_VERSION/firefox /usr/bin/firefox

RUN apt-get update -y && \
    apt-get install -y \
    culmus \
    libfontconfig \
    libfreetype6 \
    xfonts-cyrillic \
    xfonts-scalable \
    fonts-liberation \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    ttf-ubuntu-font-family \
    fonts-dejavu \
    fonts-noto \
    fonts-noto-color-emoji

COPY no-mozilla-emoji.conf /etc/fonts/conf.d/70-no-mozilla-emoji.conf
COPY local.conf /etc/fonts/conf.d/99-local.conf
RUN fc-cache -f -v

RUN firefox -CreateProfile "headless /moz-headless"  -headless

COPY headless-firefox/prefs.js /moz-headless/prefs.js

# XVFB
RUN apt-get install -y xvfb
ENV DISPLAY=:99

# The reason we need a tcp proxy fis that marionette listens on 127.0.0.1 (and not on 0.0.0.0), which means
# that it can't be connected through the docker container
COPY --from=0 /tcp-proxy .

# Profile prefs
COPY headless-firefox/profile-prefs.js /moz-headless/prefs.js

# This flag is a workaround for the fact that FF uses shared memory, and the shared memory size
# that K8s gives is 64MB, and is currently unalterable (https://github.com/kubernetes/kubernetes/issues/28272).
# This makes various sites crash FF (or a tab in FF) sporadically. I opened a ticket on it till I figured it out:
# https://bugzilla.mozilla.org/show_bug.cgi?id=1567168#c9. This flag disables FF E10s (Electrolysis), which is the
# FF architecture that puts various elemenets in different processes, and uses Shared memory to communicate between
# them.
# ENV MOZ_FORCE_DISABLE_E10S=true

RUN echo \
    ' ********************************************************\n' \
    '*** The Firefox version is now:' `firefox -version` '***\n' \
    '********************************************************\n'

EXPOSE 2828

#==========
# Relaxing permissions for OpenShift and other non-sudo environments
#==========
# RUN apt-get install -y sudo && sudo chmod -R 777 ${HOME} \
#   && sudo chgrp -R 0 ${HOME} \
#   && sudo chmod -R g=u ${HOME}

CMD ["sh" , "-c", "(./tcp-proxy -l='0.0.0.0:2828' -r='localhost:2829' &) && xvfb-run --server-num=99 --server-args='-screen 0 4096x4096x24' firefox -marionette -foreground -no-remote --profile /moz-headless"]

