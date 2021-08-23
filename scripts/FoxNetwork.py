import numpy as np
import math
import os

from numpy.matrixlib.defmatrix import matrix

from FoxPacket import *
from Firmware import *

class FoxNetwork():
    def __init__(self, *, networkRows, networkCols, resultNodeCoord, \
            totalMatrixSize, foxNetworkStages, multicastGroupBits, \
            doneFlagBits, resultFlagBits, matrixTypeBits, matrixCoordBits, \
            foxFirmware, resultFirmware, A=None, B=None, \
            useMatrixInitFile=True):

        # Entire network details
        self.networkRows = networkRows
        self.networkCols = networkCols
        self.networkNodes = self.networkRows * self.networkCols
        self.resultNodeCoord = resultNodeCoord

        # Fox algorithm network details
        self.foxNetworkStages = foxNetworkStages
        self.foxNetworkNodes = (self.foxNetworkStages ** 2)

        coordBits = math.ceil(math.log2(max(self.networkRows, self.networkCols)))
        matrixElementBits = 32

        self.packetFormat = FoxPacket(coordBits=coordBits, multicastGroupBits=multicastGroupBits, doneFlagBits=doneFlagBits, \
            resultFlagBits=resultFlagBits, matrixTypeBits=matrixTypeBits, matrixCoordBits=matrixCoordBits, matrixElementBits=matrixElementBits)

        # Matrix details
        self.totalMatrixSize = totalMatrixSize
        self.totalMatrixElements = (self.totalMatrixSize ** 2)

        self.foxMatrixSize = int(self.totalMatrixSize / self.foxNetworkStages)
        self.foxMatrixElements = (self.foxMatrixSize ** 2)

        self.foxFifoDepth = 2 * self.foxMatrixElements
        self.resultFifoDepth = self.totalMatrixElements

        # Do not set A or B by default
        self.A = A
        self.B = B
        self.useMatrixInitFile = useMatrixInitFile

        if A is not None and B is not None:
            assert A.shape[0] == self.totalMatrixSize, "A matrix dimensions do not match totalMatrixSize"
            assert B.shape[0] == self.totalMatrixSize, "B matrix dimensions do not match totalMatrixSize"

            print(self.A)
            print(self.B)

        self.foxFirmware = foxFirmware
        self.resultFirmware = resultFirmware

    '''
    Convert a node's (x, y) coordinates into a node number
    '''
    def node_coord_to_node_number(self, coord):
        nodeNumber = coord['y'] * self.networkRows + coord['x']
        
        return nodeNumber

    '''
    Convert a node's number to (x, y) coordinates
    '''
    def node_number_to_node_coord(self, nodeNumber):
        nodeCoords = {}
        nodeCoords['x'] = nodeNumber % self.networkRows
        nodeCoords['y'] = nodeNumber // self.networkRows

        return nodeCoords

    '''
    Set the A and B matrices that will be multiplied using Fox's algorithm
    '''
    def set_matrices(self, *, A, B):
        assert A.shape[0] == self.totalMatrixSize, "A matrix dimensions do not match totalMatrixSize"
        assert B.shape[0] == self.totalMatrixSize, "B matrix dimensions do not match totalMatrixSize"

        self.A = A
        self.B = B

    '''
    Encode a matrix to packets and write to file
    '''
    def write_matrix_to_file(self, *, matrixFile, nodeCoord, multicastGroup, matrixType, matrix):
        doneFlag = 0
        resultFlag = 0

        packets = self.packetFormat.encode_matrix(destCoord=nodeCoord, multicastGroup=multicastGroup, \
            resultFlag=resultFlag, doneFlag=doneFlag, matrixType=matrixType, matrix=matrix)

        # Append each packet to a file
        file = open(matrixFile, "a")

        for packet in packets:
            file.write(packet)

        file.close()

    '''
    Pad a matrix file with 0 entries
    '''
    def pad_matrix_file(self, *, matrixFile, nodeCoord, paddingRequired):
        padding = []

        for _ in range(paddingRequired):
            padding.append(self.packetFormat.create_matrix_packet(destCoord=nodeCoord, multicastGroup=0, \
                doneFlag=0, resultFlag=0, matrixType=MatrixTypes.A, matrixCoord={'x' : 0, 'y' : 0}, matrixElement=0))

        # Append padding to a file
        file = open(matrixFile, "a")

        for p in padding:
            file.write(p)

        file.close()

    '''
    Create memory initialisation files for each node and each matrix
    '''
    def create_matrix_init_files(self):
        if self.useMatrixInitFile == False:
            print("Matrix init file not used")
            return

        if self.A is None or self.B is None:
            print("Matrices not initialised")
            return

        
        import os
        scriptLocation = os.path.realpath(__file__)
        scriptDirectory = os.path.dirname(scriptLocation)

        # TODO Move save location of mif files
        initFilePrefix = "{directory}/node".format(directory=scriptDirectory)
        initFileSuffix = ".mif"

        # Loop through the nodes
        for nodeNumber in range(self.networkNodes):
            elementsWritten = 0

            # Delete the file before writing to it
            matrixFileName = initFilePrefix + str(nodeNumber) + initFileSuffix
            if os.path.exists(matrixFileName):
                os.remove(matrixFileName)
            else:
                print("The file does not exist")

            nodeCoord = self.node_number_to_node_coord(nodeNumber)

            # Split the matrices
            nodeMatrixXStart = int(nodeCoord['x'] * self.foxMatrixSize)
            nodeMatrixXEnd = int(nodeCoord['x'] * self.foxMatrixSize + self.foxMatrixSize)

            nodeMatrixYStart = int(nodeCoord['y'] * self.foxMatrixSize)
            nodeMatrixYEnd = int(nodeCoord['y'] * self.foxMatrixSize + self.foxMatrixSize)

            # Write A
            nodeA = self.A[nodeMatrixYStart:nodeMatrixYEnd, nodeMatrixXStart:nodeMatrixXEnd]
            multicastGroup = 1
            matrixType = MatrixTypes.A

            # Encode the matrix and write to file
            self.write_matrix_to_file(matrixFile=matrixFileName, nodeCoord=nodeCoord, multicastGroup=multicastGroup, matrixType=matrixType, matrix=nodeA)

            elementsWritten += np.size(nodeA)

            # Write B
            nodeB = self.B[nodeMatrixYStart:nodeMatrixYEnd, nodeMatrixXStart:nodeMatrixXEnd]
            multicastGroup = 0
            matrixType = MatrixTypes.B

            # Encode the matrix and write to file
            self.write_matrix_to_file(matrixFile=matrixFileName, nodeCoord=nodeCoord, multicastGroup=multicastGroup, matrixType=matrixType, matrix=nodeB)

            elementsWritten += np.size(nodeB)

            # If the node is the result node, pad the remainder of the file
            if (nodeNumber == self.node_coord_to_node_number(self.resultNodeCoord)):
                paddingRequired = self.totalMatrixElements - elementsWritten

                self.pad_matrix_file(matrixFile=matrixFileName, nodeCoord=nodeCoord, paddingRequired=paddingRequired)

    '''
    Generate VHDL package containing network parameters
    '''
    def write_header_file(self, fileName="fox_defs.vhd"):
        from jinja2 import Environment, FileSystemLoader
        import os

        scriptLocation = os.path.realpath(__file__)
        scriptDirectory = os.path.dirname(scriptLocation)
        fileLoader = FileSystemLoader('{directory}/templates'.format(directory=scriptDirectory))

        # fileLoader = FileSystemLoader('templates')
        env = Environment(loader=fileLoader, trim_blocks=True, lstrip_blocks=True)

        template = env.get_template('fox_defs.vhd')
        output = template.render(foxNetwork=self)

        # Write output to file
        headerFileName = '{directory}/../hdl/fox_hoplite/src/{fileName}'.format(directory=scriptDirectory, fileName=fileName)
        headerFile = open(headerFileName, 'w')
        headerFile.write(output)
        headerFile.close()

    '''
    Write matrix config files
    '''
    def write_matrix_config_file(self, vhdlFileName="matrix_config.vhd", \
            cFileName="matrix_config.h"):
        from jinja2 import Environment, FileSystemLoader
        import os

        scriptLocation = os.path.realpath(__file__)
        scriptDirectory = os.path.dirname(scriptLocation)
        fileLoader = FileSystemLoader('{directory}/templates'.format(directory=scriptDirectory))

        env = Environment(loader=fileLoader, trim_blocks=True, lstrip_blocks=True)

        vhdlTemplate = env.get_template('matrix_config.vhd')
        vhdlOutput = vhdlTemplate.render(foxNetwork=self)

        # Write output to file
        vhdlHeaderFileName = '{directory}/../hdl/fox_hoplite/src/{fileName}'.format(directory=scriptDirectory, fileName=vhdlFileName)
        vhdlHeaderFile = open(vhdlHeaderFileName, 'w')
        vhdlHeaderFile.write(vhdlOutput)
        vhdlHeaderFile.close()

        cTemplate = env.get_template('matrix_config.h')
        cOutput = cTemplate.render(foxNetwork=self)

        # Write output to file
        cHeaderFileName = '{directory}/../firmware/fox_hoplite/{fileName}'.format(directory=scriptDirectory, fileName=cFileName)
        cHeaderFile = open(cHeaderFileName, 'w')
        cHeaderFile.write(cOutput)
        cHeaderFile.close()

    '''
    Write firmware config files
    '''
    def write_firmware_config_file(self, vhdlFileName="firmware_config.vhd"):
        from jinja2 import Environment, FileSystemLoader
        import os

        scriptLocation = os.path.realpath(__file__)
        scriptDirectory = os.path.dirname(scriptLocation)
        fileLoader = FileSystemLoader('{directory}/templates'.format(directory=scriptDirectory))

        env = Environment(loader=fileLoader, trim_blocks=True, lstrip_blocks=True)

        vhdlTemplate = env.get_template('firmware_config.vhd')
        vhdlOutput = vhdlTemplate.render(foxNetwork=self)

        # Write output to file
        vhdlHeaderFileName = '{directory}/../hdl/fox_hoplite/src/{fileName}'.format(directory=scriptDirectory, fileName=vhdlFileName)
        vhdlHeaderFile = open(vhdlHeaderFileName, 'w')
        vhdlHeaderFile.write(vhdlOutput)
        vhdlHeaderFile.close()
