#!/usr/bin/ruby

system "thin start -R config.ru"

# test speed with ab -c 20 -n 40 "http://localhost:3000/"
