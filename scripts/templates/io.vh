`ifndef IO_VH
`define IO_VH

// Character output
{% for port in charIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h1000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}

// PE to network
{% for port in peToNetworkIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h2000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}

// LEDs
{% for port in ledIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h3000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}

// Network to PE
{% for port in networkToPeIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h4000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}

// Node details
{% for port in nodeIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h5000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}

// Matrix
{% for port in matrixIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h6000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}

// Network details
{% for port in networkIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h7000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}

`endif