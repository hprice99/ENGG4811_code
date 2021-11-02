import numpy as np

import enum

class MatrixTypes(enum.Enum):
    A = 0
    B = 1

class FoxPacket:
    def __init__(self, *, coordBits, multicastCoordBits, multicastGroupBits, readyFlagBits, resultFlagBits, matrixTypeBits, matrixCoordBits, matrixElementBits):

        self.coordBits = coordBits
        self.multicastCoordBits = multicastCoordBits
        self.multicastGroupBits = multicastGroupBits
        self.readyFlagBits = readyFlagBits
        self.resultFlagBits = resultFlagBits
        self.matrixTypeBits = matrixTypeBits
        self.matrixCoordBits = matrixCoordBits
        self.matrixElementBits = matrixElementBits
        
        self.busWidth =  2 * self.coordBits + 2*self.multicastCoordBits + self.readyFlagBits + self.resultFlagBits + self.matrixTypeBits + 2 * self.matrixCoordBits + self.matrixElementBits

    '''
    Convert a given value to a packet field
    '''
    @staticmethod
    def create_packet_field(value, width):
        field = '{value:0{width}b}'.format(value=value, width=width)

        return field

    '''
    Encode a matrix packet to a string
    '''
    def create_matrix_packet(self, *, destCoord, multicastCoord, readyFlag, resultFlag, matrixType, matrixCoord, matrixElement):

        destXCoordField = FoxPacket.create_packet_field(destCoord['x'], self.coordBits)
        destYCoordField = FoxPacket.create_packet_field(destCoord['y'], self.coordBits)

        multicastXCoordField = FoxPacket.create_packet_field(multicastCoord['x'], self.multicastCoordBits)
        multicastYCoordField = FoxPacket.create_packet_field(multicastCoord['y'], self.multicastCoordBits)

        readyFlagField = FoxPacket.create_packet_field(readyFlag, self.readyFlagBits)
        resultFlagField = FoxPacket.create_packet_field(resultFlag, self.resultFlagBits)

        matrixTypeField = FoxPacket.create_packet_field(matrixType.value, self.matrixTypeBits)

        matrixXCoordField = FoxPacket.create_packet_field(matrixCoord['x'], self.matrixCoordBits)
        matrixYCoordField = FoxPacket.create_packet_field(matrixCoord['y'], self.matrixCoordBits)
        
        matrixElementField = FoxPacket.create_packet_field(matrixElement, self.matrixElementBits)

        # Put the fields together
        packet = matrixElementField + matrixYCoordField + matrixXCoordField + matrixTypeField + resultFlagField + readyFlagField + multicastYCoordField + multicastXCoordField + destYCoordField + destXCoordField + '\n'

        return packet

    '''
    Encode a matrix to a list of packets
    '''
    def encode_matrix(self, *, destCoord, multicastCoord, readyFlag, resultFlag, matrixType, matrix):

        packets = []

        for matrixY in range(matrix.shape[1]):
            for matrixX in range(matrix.shape[0]):
                matrixCoord = {'x' : matrixX, 'y' : matrixY}
                matrixElement = matrix[matrixY, matrixX]

                packet = self.create_matrix_packet(destCoord=destCoord, multicastCoord=multicastCoord, resultFlag=resultFlag, readyFlag=readyFlag, matrixType=matrixType, matrixCoord=matrixCoord, matrixElement=matrixElement)

                packets.append(packet)

        return packets

    '''
    Generate VHDL package containing packet format
    '''
    def write_header_file(self, *, hdlFolder, fileName="packet_defs.vhd"):
        from jinja2 import Environment, FileSystemLoader
        import os

        scriptLocation = os.path.realpath(__file__)
        scriptDirectory = os.path.dirname(scriptLocation)
        fileLoader = FileSystemLoader('{directory}/templates'.format(directory=scriptDirectory))

        # fileLoader = FileSystemLoader('templates')
        env = Environment(loader=fileLoader, trim_blocks=True, lstrip_blocks=True)

        template = env.get_template('packet_defs.vhd')
        output = template.render(packetFormat=self)

        # Write output to file
        headerFileName = '{directory}/../{hdlFolder}/src/{fileName}'.format(directory=scriptDirectory, hdlFolder=hdlFolder, fileName=fileName)
        headerFile = open(headerFileName, 'w')
        headerFile.write(output)
        headerFile.close()
