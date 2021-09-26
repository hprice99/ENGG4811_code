`ifndef IO_VH
`define IO_VH

{% if charIo != None %}
// Character output
{% for port in charIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h1000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}
{% endif %}

{% if peToNetworkIo != None %}
// PE to network
{% for port in peToNetworkIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h2000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}
{% endif %}

{% if ledIo != None %}
// LEDs
{% for port in ledIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h3000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}
{% endif %}

{% if networkToPeIo != None %}
// Network to PE
{% for port in networkToPeIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h4000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}
{% endif %}

{% if nodeIo != None %}
// Node details
{% for port in nodeIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h5000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}
{% endif %}

{% if matrixIo != None %}
// Matrix
{% for port in matrixIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h6000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}
{% endif %}

{% if networkIo != None %}
// Network details
{% for port in networkIo -%}
`define {{ port.name|upper }}_{{ port.direction|upper }}      32'h7000_{{ '%04d' % (10 * loop.index0) }}
{% endfor %}
{% endif %}

`endif
