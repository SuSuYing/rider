FROM hangoio/envoy-proxy:v0.0.1-b9696c2

RUN apt-get update && apt-get install -y                                                \
    git luarocks                                                                        \
    && sudo apt-get autoremove -y && apt-get clean && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

ARG RIDER_HOME=/usr/local/lib/rider

RUN mkdir -p ${RIDER_HOME}
COPY rider ${RIDER_HOME}/rider
COPY examples ${RIDER_HOME}/examples
COPY rider-1.0.0-1.rockspec ${RIDER_HOME}/rider-1.0.0-1.rockspec

RUN cd $RIDER_HOME && luarocks make
