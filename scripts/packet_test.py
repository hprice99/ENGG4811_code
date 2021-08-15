# %%
import numpy as np
from FoxPacket import *

coordBits = 1
multicastGroupBits = 1
doneFlagBits = 1
resultFlagBits = 1
matrixTypeBits = 1
matrixCoordBits = 8
matrixElementBits = 32

foxPacket = FoxPacket(coordBits=coordBits, multicastGroupBits=multicastGroupBits, doneFlagBits=doneFlagBits, resultFlagBits=resultFlagBits, matrixTypeBits=matrixTypeBits, matrixCoordBits=matrixCoordBits, matrixElementBits=matrixElementBits)
# %%
destCoord = {'x' : 0, 'y' : 0}
multicastGroup = 1
resultFlag = 0
doneFlag = 0
matrixType = MatrixTypes.A
matrixCoord = {'x' : 0, 'y' : 0}
matrixElement = 1

matrixPacket = foxPacket.create_matrix_packet(destCoord=destCoord, multicastGroup=multicastGroup, resultFlag=resultFlag, doneFlag=doneFlag, matrixType=matrixType, matrixCoord=matrixCoord, matrixElement=matrixElement)

print(matrixPacket)

# %%
matrix = np.array([[1, 2], [3, 4]])

destCoord = {'x' : 0, 'y' : 0}
multicastGroup = 1
resultFlag = 0
doneFlag = 0
matrixType = MatrixTypes.A

packets = foxPacket.encode_matrix(destCoord=destCoord, multicastGroup=multicastGroup, resultFlag=resultFlag, doneFlag=doneFlag, matrixType=matrixType, matrix=matrix)

for packet in packets:
    print(packet)

# %%
matrix = np.array([[1, 1], [1, 1]])

destCoord = {'x' : 0, 'y' : 0}
multicastGroup = 1
resultFlag = 0
doneFlag = 0
matrixType = MatrixTypes.A

packets = foxPacket.encode_matrix(destCoord=destCoord, multicastGroup=multicastGroup, resultFlag=resultFlag, doneFlag=doneFlag, matrixType=matrixType, matrix=matrix)

for packet in packets:
    print(packet)

# %%
