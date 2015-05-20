FROM ubuntu:14.04.2

MAINTAINER ageng "me@ageng.my.id"

# Start

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update
RUN apt-get -y install build-essential python libxml2-dev libxslt-dev git vim nano wget curl autoconf sudo openssh-server bash-completion python-pip

# Supervisor Config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

# Set locale

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LC_ALL C
ENV LC_ALL en_US.UTF-8

# Install Chef and Chef-dk

RUN curl -L https://www.opscode.com/chef/install.sh | bash
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc

RUN cd /tmp ;\
    wget -O chefdk.deb https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chefdk_0.5.1-1_amd64.deb ;\
    dpkg -i chefdk.deb ;\
    rm -f /tmp/chefdk.deb
# Make Chef DK the primary Ruby/Chef development environment.
RUN echo 'eval "$(chef shell-init bash)"' >> ~/.bash_profile

# Provisioning Start

ADD . /chef

RUN cd /chef && berks && berks vendor

RUN chef-solo -c /chef/solo.rb -j /chef/solo.json

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

RUN cp /chef/default /etc/nginx/sites-enabled/

RUN mkdir /var/www/

RUN cp /chef/index.php /var/www/

#RUN echo "daemon off;" >> /etc/nginx/nginx.conf

ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

CMD ["/bin/bash", "/start.sh"]
