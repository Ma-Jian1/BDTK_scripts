#!/bin/bash

sdk install java 8.0.302-open
export MAVEN_OPTS="-DsocksProxyHost=child-prc.intel.com -DsocksProxyPort=1080"