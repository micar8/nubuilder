FROM ubuntu:18.04

#01.10.2020 nuBuilder 4

# parameter 
# Change this values to your preferences
ENV mysqlpassword docker

#Packages
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get -qq update && apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq update && \
    apt-get -y install mysql-server apache2 php php-mysql unzip libapache2-mod-php php-mbstring git

# ADD nuBuilder
# nuBuilder intallation
RUN git clone https://github.com/steven-copley/nubuilder4.git /var/www/html/nubuilder4
RUN cd /var/www/html/nubuilder4 && git checkout -b

# mysql Database
RUN mysql -u root -p &&\
    CREATE DATABASE nubuilder4; &&\
    quit
RUN mysql -u root -p nubuilder4 < ./nubuilder4.sql

RUN service mysql restart

# Expose the mysql port
EXPOSE 3306

# ADD APACHE
# Run the rest of the commands as the ``root`` user
USER root

RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd

# SET Servername to localhost
RUN echo "ServerName localhost" >> /etc/apache2/conf-available/servername.conf
RUN a2enconf servername

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
 
RUN chown -R www-data:www-data /var/www
RUN chmod u+rwx,g+rx,o+rx /var/www
RUN find /var/www -type d -exec chmod u+rwx,g+rx,o+rx {} +
RUN find /var/www -type f -exec chmod u+rw,g+rw,o+r {} +

RUN ufw allow 80
RUN ufw allow 8080

EXPOSE 80
EXPOSE 443

# And add ``listen_addresses`` to ``/etc/postgresql/${postgresversion}/main/postgresql.conf``
RUN sed -ri "$a[client]" "/etc/alternatives/my.cnf"
RUN sed -ri "$aport=3306" "/etc/alternatives/my.cnf"
RUN sed -ri "$asocket=/tmp/mysql.sock" "/etc/alternatives/my.cnf"
RUN sed -ri "$a[mysqld]" "/etc/alternatives/my.cnf"
RUN sed -ri "$aport=3306" "/etc/alternatives/my.cnf"
RUN sed -ri "$asocket=/tmp/mysql.sock" "/etc/alternatives/my.cnf"
RUN sed -ri "$akey_buffer_size=16M" "/etc/alternatives/my.cnf"
RUN sed -ri "$amax_allowed_packet=8M" "/etc/alternatives/my.cnf"
RUN sed -ri "$asql-mode=NO_ENGINE_SUBSTITUTION" "/etc/alternatives/my.cnf"
RUN sed -ri "$a[mysqldump]" "/etc/alternatives/my.cnf"
RUN sed -ri "$aquick" "/etc/alternatives/my.cnf"
 
# Update the default apache site with the config we created.
ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf
 
# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/var/www/html/nubuilder4", "/home"]

# By default, simply start apache.
CMD ["/usr/local/bin/start.sh"]
