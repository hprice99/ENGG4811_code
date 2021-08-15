# %%
from port import *

from jinja2 import Environment, FileSystemLoader

fileLoader = FileSystemLoader('templates')
env = Environment(loader=fileLoader, trim_blocks=False, lstrip_blocks=False)

# %%
# Generate the IO ports
charIo =    [
                Port(name='char', direction='output', width=8), 
                Port(name='char_output_ready', direction='input', width=8)
            ]

peToNetworkIo =     [
                        Port(name='message_out_ready', direction='input', width=8),
                        Port(name='x_coord', direction='output', width=8),
                        Port(name='y_coord', direction='output', width=8),
                        Port(name='multicast_group', direction='output', width=8),
                        Port(name='done_flag', direction='output', width=8),
                        Port(name='result_flag', direction='output', width=8),
                        Port(name='matrix_type', direction='output', width=8),
                        Port(name='matrix_x_coord', direction='output', width=8),
                        Port(name='matrix_y_coord', direction='output', width=8),
                        Port(name='matrix_element', direction='output', width=32),
                        Port(name='packet_complete', direction='output', width=8)
                    ]

ledIo = [Port(name='led', direction='output', width=8)]

networkToPeIo =     [
                        Port(name='message_valid', direction='input', width=8),
                        Port(name='message_in_available', direction='input', width=8),
                        Port(name='multicast_group', direction='input', width=8),
                        Port(name='done_flag', direction='input', width=8),
                        Port(name='result_flag', direction='input', width=8),
                        Port(name='matrix_type', direction='input', width=8),
                        Port(name='matrix_x_coord', direction='input', width=8),
                        Port(name='matrix_y_coord', direction='input', width=8),
                        Port(name='matrix_element', direction='input', width=32),
                        Port(name='message_read', direction='output', width=8)
                    ]

nodeIo =    [
                Port(name='x_coord', direction='input', width=8),
                Port(name='y_coord', direction='input', width=8),
                Port(name='node_number', direction='input', width=8),
                Port(name='matrix_x_offset', direction='input', width=8),
                Port(name='matrix_y_offset', direction='input', width=8),
                Port(name='matrix_init_from_file', direction='input', width=8)
            ]

matrixIo =  [
                Port(name='matrix', direction='output', width=32),
                Port(name='matrix_end_row', direction='output', width=8),
                Port(name='matrix_end', direction='output', width=8),
                Port(name='fox_matrix_size', direction='input', width=32)
            ]

networkIo = [
                Port(name='fox_network_stages', direction='input', width=8),
                Port(name='result_x_coord', direction='input', width=8),
                Port(name='result_y_coord', direction='input', width=8)
            ]

# %%
verilogTemplate = env.get_template('io.vh')
verilogOutput = verilogTemplate.render(charIo=charIo, peToNetworkIo=peToNetworkIo, ledIo=ledIo, networkToPeIo=networkToPeIo, nodeIo=nodeIo, matrixIo=matrixIo, networkIo=networkIo)

# Write output to file
verilogHeaderFile = 'io.vh'
verilogHeader = open(verilogHeaderFile, 'w')
verilogHeader.write(verilogOutput)
verilogHeader.close()

verilogHeaderFile = '../hdl/fox_hoplite/src/io.vh'
verilogHeader = open(verilogHeaderFile, 'w')
verilogHeader.write(verilogOutput)
verilogHeader.close()

# %%
cTemplate = env.get_template('io.h')
cOutput = cTemplate.render(charIo=charIo, peToNetworkIo=peToNetworkIo, ledIo=ledIo, networkToPeIo=networkToPeIo, nodeIo=nodeIo, matrixIo=matrixIo, networkIo=networkIo)

# Write output to file
cHeaderFile = 'io.h'
cHeader = open(cHeaderFile, 'w')
cHeader.write(cOutput)
cHeader.close()

cHeaderFile = '../firmware/fox_hoplite/io.h'
cHeader = open(cHeaderFile, 'w')
cHeader.write(cOutput)
cHeader.close()