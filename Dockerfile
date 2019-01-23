FROM centos

RUN yum -y update; yum clean all
RUN yum install -y which
RUN yum install -y unzip
RUN yum install -y mysql
RUN yum install -y nano

#----- Enables the systemctl on centos
# learn more: https://hub.docker.com/_/centos/

ENV container docker

RUN yum -y install systemd; yum clean all

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
	rm -f /lib/systemd/system/multi-user.target.wants/*;\
	rm -f /etc/systemd/system/*.wants/*;\
	rm -f /lib/systemd/system/local-fs.target.wants/*; \
	rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
	rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
	rm -f /lib/systemd/system/basic.target.wants/*;\
	rm -f /lib/systemd/system/anaconda.target.wants/*;

VOLUME [ “/sys/fs/cgroup” ]

#----- PHP 7.3 installation
# for more info https://computingforgeeks.com/how-to-install-php-7-3-on-centos-7-fedora/

RUN yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm 
RUN yum -y install epel-release yum-utils 
RUN yum-config-manager --disable remi-php54 
RUN yum-config-manager --enable remi-php73 
RUN yum -y install php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-curl php-xml php-pear php-bcmath php-json php-mysql php-soap php-xmlrpc

RUN php -v


#----- Composer installation
# Learn more: https://getcomposer.org/doc/00-intro.md#globally

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === '93b54496392c062774670ac18b134c3b3a95e5a5e5c8f1a9f115f203b75bf9a129d5daa8ba6a13e2cc8a1da0806388a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" 
RUN php composer-setup.php 
RUN php -r "unlink('composer-setup.php');"

#Makes the composer globally accessible

RUN mv /composer.phar /usr/local/bin/composer 
RUN composer -v


#----- Laravel installation

RUN composer global require laravel/installer
RUN export PATH=$PATH:~/.composer/vendor/bin/


#----- Nodejs installation
RUN curl -sL https://rpm.nodesource.com/setup_11.x | bash -
RUN yum -y install nodejs
RUN node -v

#----- Nginx installation

ENV nginxversion="1.14.0-1" \
    os="centos" \
    osversion="7" \
    elversion="7_4"

RUN yum install -y wget openssl sed &&\
    yum -y autoremove &&\
    yum clean all &&\
    wget http://nginx.org/packages/$os/$osversion/x86_64/RPMS/nginx-$nginxversion.el$elversion.ngx.x86_64.rpm &&\
    rpm -iv nginx-$nginxversion.el$elversion.ngx.x86_64.rpm 

#Copies the predefined configs
COPY nginx.conf /etc/nginx/nginx.conf

#Copies and configs entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#----- The server dir structures
RUN mkdir -p /home/typeax.com/
RUN chmod -R 750 /home/typeax.com/
RUN chown -R nginx /home/typeax.com/


#Configures php.ini
RUN sed 's/upload_max_filesize = 2M/upload_max_filesize = 50M/' /etc/php.ini > /etc/php.ini.new
RUN sed 's/post_max_size = 8M/post_max_size = 50M/' /etc/php.ini.new > /etc/php.ini
RUN rm /etc/php.ini.new

#Configures php-fpm 
RUN sed 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf > /etc/php-fpm.d/www.conf.new
RUN sed 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf.new > /etc/php-fpm.d/www.conf
RUN sed 's/;listen.owner = nobody/listen.owner = nginx/' /etc/php-fpm.d/www.conf > /etc/php-fpm.d/www.conf.new
RUN sed 's/;listen.group = nobody/listen.group = nginx/' /etc/php-fpm.d/www.conf.new > /etc/php-fpm.d/www.conf
RUN mkdir -p /run/php-fpm/
RUN touch /run/php-fpm/php-fpm.pid

EXPOSE 80
EXPOSE 443

CMD ["./entrypoint.sh"]


