import numpy as np
import math

# Matix configuration
matrixSize = 16

A = np.random.randint(5, size=(matrixSize, matrixSize))
B = np.random.randint(5, size=(matrixSize, matrixSize))

print(A @ B)