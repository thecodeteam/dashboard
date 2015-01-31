############################################################
# Dockerfile to build Python WSGI Application Containers
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM ubuntu

# File Author / Maintainer
MAINTAINER Jonas Rosland

# Add the application resources URL
RUN echo "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) main universe" >> /etc/apt/sources.list

# Update the sources list
RUN apt-get update

# Install basic applications
RUN apt-get install -y tar git curl nano wget dialog net-tools build-essential unzip

# Install Python and Basic Python Tools
RUN apt-get install -y ruby-dev nodejs

# Install the Dashing and Bundler gems
RUN gem install dashing
RUN gem install bundler

# Copy the application folder inside the container
#ADD . /social-dashboard

# Install Dashing into /social-dashboard
RUN dashing new social-dashboard

# Bundle the dashboard
RUN cd /social-dashboard && bundle

# Download widgets
#RUN cd /social-dashboard && wget https://github.com/cmaujean/dashing-github-stats/archive/master.zip
#RUN cd /social-dashboard && unzip master.zip
#RUN cd /social-dashboard && cp -r dashing-github-stats-master/assets/* assets
#RUN cd /social-dashboard && cp -r dashing-github-stats-master/jobs/* jobs
#RUN cd /social-dashboard && cp -r dashing-github-stats-master/widgets/* widgets
#RUN cd /social-dashboard && cp dashing-github-stats-master/github.yml .
#RUN cd /social-dashboard && rm -fr dashing-github-stats-master

#ADD ./github.yml /social-dashboard/github.yml
#ADD ./Gemfile /social-dashboard/Gemfile
#ADD ./sample.erb /social-dashboard/dashboards/sample.erb

# Expose ports
EXPOSE 3030

# Set the default directory where CMD will execute
WORKDIR /social-dashboard

# Set the default command to execute
# when creating a new container
# i.e. using CherryPy to serve the application
CMD dashing start
