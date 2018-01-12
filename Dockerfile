FROM ubuntu:16.04

RUN echo "Install additional packages ..." \
  && apt-get update \
  && apt-get install -q -y apt-transport-https ca-certificates curl software-properties-common

RUN echo "Set UTF locale..." \
  && DEBIAN_FRONTEND=noninteractive apt-get -q -y install language-pack-en \
  && DEBIAN_FRONTEND=noninteractive locale-gen en_US.UTF-8 \
  && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
  && update-locale LANG=en_US.UTF-8

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN echo "Install docker ..." \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
  && apt-key fingerprint 0EBFCD88 \
  && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  && apt-get update \
  && apt-get install -q -y docker-ce

ENV RUBY_VERSION 2.5.0

RUN echo "Install ruby ..." \
  && gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
  && curl -sSL https://get.rvm.io | bash -s stable \
  && /bin/bash -l -c 'source /etc/profile.d/rvm.sh' \
  && /bin/bash -l -c 'rvm requirements' \
  && /bin/bash -l -c 'rvm install $RUBY_VERSION' \
  && /bin/bash -l -c 'rvm use $RUBY_VERSION --default' \
  && /bin/bash -l -c 'rvm rubygems current' \
  && /bin/bash -l -c 'gem install bundle'

RUN mkdir -p app

COPY . /app
WORKDIR /app

RUN echo "Setup bobi ..." \
  && /bin/bash -l -c 'bundle install'

CMD /bin/bash -l -c 'bundle exec rackup -p 5000 -o 0.0.0.0'
