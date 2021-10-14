#ifndef IO_H
#define IO_H

{% macro pointer_type(width) -%} 
{% if width <= 8 %}char{% else %}long{% endif %}
{%- endmacro -%}

{% if charIo != None %}
// Character output
{% for port in charIo -%}
#define {{ port.name|upper }}_{{ port.direction|upper }}      (*(volatile {{ pointer_type(port.width) }}*)0x1000{{ '%04d' % (10 * loop.index0) }})
{% endfor %}
{% endif %}

{% if peToNetworkIo != None %}
// PE to network
{% for port in peToNetworkIo -%}
#define {{ port.name|upper }}_{{ port.direction|upper }}      (*(volatile {{ pointer_type(port.width) }}*)0x2000{{ '%04d' % (10 * loop.index0) }})
{% endfor %}
{% endif %}

{% if ledIo != None %}
// LEDs
{% for port in ledIo -%}
#define {{ port.name|upper }}_{{ port.direction|upper }}      (*(volatile {{ pointer_type(port.width) }}*)0x3000{{ '%04d' % (10 * loop.index0) }})
{% endfor %}
{% endif %}

{% if networkToPeIo != None %}
// Network to PE
{% for port in networkToPeIo -%}
#define {{ port.name|upper }}_{{ port.direction|upper }}      (*(volatile {{ pointer_type(port.width) }}*)0x4000{{ '%04d' % (10 * loop.index0) }})
{% endfor %}
{% endif %}

{% if nodeIo != None %}
// Node details
{% for port in nodeIo -%}
#define {{ port.name|upper }}_{{ port.direction|upper }}      (*(volatile {{ pointer_type(port.width) }}*)0x5000{{ '%04d' % (10 * loop.index0) }})
{% endfor %}
{% endif %}

{% if matrixIo != None %}
// Matrix
{% for port in matrixIo -%}
#define {{ port.name|upper }}_{{ port.direction|upper }}      (*(volatile {{ pointer_type(port.width) }}*)0x6000{{ '%04d' % (10 * loop.index0) }})
{% endfor %}
{% endif %}

{% if networkIo != None %}
// Network details
{% for port in networkIo -%}
#define {{ port.name|upper }}_{{ port.direction|upper }}      (*(volatile {{ pointer_type(port.width) }}*)0x7000{{ '%04d' % (10 * loop.index0) }})
{% endfor %}
{% endif %}

#endif
