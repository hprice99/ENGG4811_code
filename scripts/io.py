# %%
from port import *

from jinja2 import Environment, FileSystemLoader
import os
import yaml

scriptLocation = os.path.realpath(__file__)
scriptDirectory = os.path.dirname(scriptLocation)
fileLoader = FileSystemLoader('{directory}/templates'.format(directory=scriptDirectory))

# fileLoader = FileSystemLoader('templates')
env = Environment(loader=fileLoader, trim_blocks=True, lstrip_blocks=True)

# %%
# Generate the IO ports
stream = open("IOConfig.yaml", 'r')
dictionary = yaml.safe_load(stream)

charIo = [Port(name=element["name"], direction=element["direction"], width=element["width"]) for element in dictionary["charIo"]]

peToNetworkIo = [Port(name=element["name"], direction=element["direction"], width=element["width"]) for element in dictionary["peToNetworkIo"]]

ledIo = [Port(name=element["name"], direction=element["direction"], width=element["width"]) for element in dictionary["ledIo"]]

networkToPeIo = [Port(name=element["name"], direction=element["direction"], width=element["width"]) for element in dictionary["networkToPeIo"]]

nodeIo = [Port(name=element["name"], direction=element["direction"], width=element["width"]) for element in dictionary["nodeIo"]]

matrixIo = [Port(name=element["name"], direction=element["direction"], width=element["width"]) for element in dictionary["matrixIo"]]

networkIo = [Port(name=element["name"], direction=element["direction"], width=element["width"]) for element in dictionary["networkIo"]]

# %%
verilogTemplate = env.get_template('io.vh')
verilogOutput = verilogTemplate.render(charIo=charIo, peToNetworkIo=peToNetworkIo, ledIo=ledIo, networkToPeIo=networkToPeIo, nodeIo=nodeIo, matrixIo=matrixIo, networkIo=networkIo)

# Write output to file
verilogHeaderFile = '{directory}/../hdl/fox_hoplite/src/io.vh'.format(directory=scriptDirectory)
verilogHeader = open(verilogHeaderFile, 'w')
verilogHeader.write(verilogOutput)
verilogHeader.close()

# %%
cTemplate = env.get_template('io.h')
cOutput = cTemplate.render(charIo=charIo, peToNetworkIo=peToNetworkIo, ledIo=ledIo, networkToPeIo=networkToPeIo, nodeIo=nodeIo, matrixIo=matrixIo, networkIo=networkIo)

# Write output to file
cHeaderFile = '../firmware/fox_hoplite/io.h'
cHeaderFile = '{directory}/../firmware/fox_hoplite/io.h'.format(directory=scriptDirectory)
cHeader = open(cHeaderFile, 'w')
cHeader.write(cOutput)
cHeader.close()
