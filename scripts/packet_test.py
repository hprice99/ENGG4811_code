# %%
from numpy.matrixlib.defmatrix import matrix
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