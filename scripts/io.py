# %%
from Port import *

from jinja2 import Environment, FileSystemLoader
import sys
import yaml
import os

# %%
# Ensure that a command line argument is given (or the project is running in a Jupyter notebook)
try:
    ipy_str = str(type(get_ipython()))
    if 'zmqshell' in ipy_str or 'terminal' in ipy_str:
        # Running in Jupyter or iPython
        projectName = input("Enter project name: ")
except:
    # Running in terminal
    if len(sys.argv) < 2:
        projectName = input("Enter project name: ")
    elif len(sys.argv) > 2:
        raise Exception("Too many command line arguments given")
    else:
        projectName = sys.argv[1]

# Import YAML configuration for project
try:
    scriptLocation = os.path.realpath(__file__)
    scriptDirectory = os.path.dirname(scriptLocation)

    projectStream = open("{scriptDirectory}/{projectName}/ProjectConfig.yaml".format(scriptDirectory=scriptDirectory, projectName=projectName), 'r')
    projectConfig = yaml.safe_load(projectStream)
except:
    raise Exception("Project configuration could not be opened")

firmwareFolder = projectConfig['firmwareFolder']
hdlFolder = projectConfig['hdlFolder']

# %%
scriptLocation = os.path.realpath(__file__)
scriptDirectory = os.path.dirname(scriptLocation)
fileLoader = FileSystemLoader('{directory}/templates'.format(directory=scriptDirectory))

# fileLoader = FileSystemLoader('templates')
env = Environment(loader=fileLoader, trim_blocks=True, lstrip_blocks=True)

# %%
# Generate the IO ports
stream = open("{scriptDirectory}/{projectName}/IOConfig.yaml".format(scriptDirectory=scriptDirectory, projectName=projectName), 'r')
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
verilogHeaderFile = '{directory}/../{hdlFolder}/src/io.vh'.format(directory=scriptDirectory, hdlFolder=hdlFolder)
verilogHeader = open(verilogHeaderFile, 'w')
verilogHeader.write(verilogOutput)
verilogHeader.close()

# %%
cTemplate = env.get_template('io.h')
cOutput = cTemplate.render(charIo=charIo, peToNetworkIo=peToNetworkIo, ledIo=ledIo, networkToPeIo=networkToPeIo, nodeIo=nodeIo, matrixIo=matrixIo, networkIo=networkIo)

# Write output to file
cHeaderFile = '{directory}/../{firmwareFolder}/io.h'.format(directory=scriptDirectory, firmwareFolder=firmwareFolder)
cHeader = open(cHeaderFile, 'w')
cHeader.write(cOutput)
cHeader.close()
