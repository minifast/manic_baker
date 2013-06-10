#!/bin/sh

pkgin list | grep ^ruby193-[0-9] ;
if [ $? -gt 0 ]; then
  pkgin -y install ruby193 ;
fi ;

pkgin list | grep ^gmake-[0-9] ;
if [ $? -gt 0 ]; then
  pkgin -y install gmake ;
fi ;

pkgin list | grep ^gcc47-[0-9] ;
if [ $? -gt 0 ]; then
  pkgin -y install gcc47 ;
fi ;

gem list | grep ^chef
if [ $? -gt 0 ]; then
  gem install chef --no-ri -no-rdoc ;
fi

test -h /opt/local/bin/chef-client ;
if [ $? -gt 0 ]; then
  ln -s /opt/local/lib/ruby/gems/1.9.3/gems/*/bin/chef-client /opt/local/bin/chef-client ;
fi

test -h /opt/local/bin/chef-solo ;
if [ $? -gt 0 ]; then
  ln -s /opt/local/lib/ruby/gems/1.9.3/gems/*/bin/chef-solo /opt/local/bin/chef-solo ;
fi
