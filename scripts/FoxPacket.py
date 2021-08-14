import numpy as np

import enum

class MatrixTypes(enum.Enum):
    A = 0
    B = 1

class FoxPacket:
    def __init__(self, *, coordBits, multicastGroupBits, doneFlagBits, resultFlagBits, matrixTypeBits, matrixCoordBits, matrixElementBits):

        self.coordBits = coordBits
        self.multicastGroupBits = multicastGroupBits
        self.doneFlagBits = doneFlagBits
        self.resultFlagBits = resultFlagBits
        self.matrixTypeBits = matrixTypeBits
        self.matrixCoordBits = matrixCoordBits
        self.matrixElementBits = matrixElementBits
        
        self.busWidth =  2 * self.coordBits + self.multicastGroupBits + self.doneFlagBits + self.resultFlagBits + self.matrixTypeBits + 2 * self.matrixCoordBits + self.matrixElementBits

    '''
    Convert a given value to a packet field
    '''
    @staticmethod
    def create_packet_field(value, width):
        field = '{value:0{width}b}'.format(value=value, width=width)

        return field

    def create_matrix_packet(self, *, destCoord, multicastGroup, doneFlag, resultFlag, matrixType, matrixCoord, matrixElement):

        destXCoordField = FoxPacket.create_packet_field(destCoord['x'], self.coordBits)
        destYCoordField = FoxPacket.create_packet_field(destCoord['y'], self.coordBits)

        multicastGroupField = FoxPacket.create_packet_field(multicastGroup, self.multicastGroupBits)

        doneFlagField = FoxPacket.create_packet_field(doneFlag, self.doneFlagBits)
        resultFlagField = FoxPacket.create_packet_field(resultFlag, self.resultFlagBits)

        matrixTypeField = FoxPacket.create_packet_field(matrixType.value, self.matrixTypeBits)

        matrixXCoordField = FoxPacket.create_packet_field(matrixCoord['x'], self.matrixCoordBits)
        matrixYCoordField = FoxPacket.create_packet_field(matrixCoord['y'], self.matrixCoordBits)
        
        matrixElementField = FoxPacket.create_packet_field(matrixElement, self.matrixElementBits)

        # Put the fields together
        packet = matrixElementField + matrixYCoordField + matrixXCoordField + matrixTypeField + resultFlagField + doneFlagField + multicastGroupField + destYCoordField + destXCoordField

        return packet
