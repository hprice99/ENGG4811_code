import numpy as np
import math
import os

import os

scriptLocation = os.path.realpath(__file__)
scriptDirectory = os.path.dirname(scriptLocation)

# Matrix configuration
matrixSize = 40
matrixFileName = "matrices.npz"

def generate_matrices():
    A = np.random.randint(5, size=(matrixSize, matrixSize))
    B = np.random.randint(5, size=(matrixSize, matrixSize))

    np.savez(matrixFileName, A=A, B=B)

    return (A, B)

if os.path.exists(matrixFileName):
    matrices = np.load(matrixFileName)

    A = matrices['A']
    B = matrices['B']

    if A.shape[0] != matrixSize or B.shape[0] != matrixSize or A.shape[0] != A.shape[1] or B.shape[0] != B.shape[1]:
        (A, B) = generate_matrices()
else:
    (A, B) = generate_matrices()

print(A @ B)
