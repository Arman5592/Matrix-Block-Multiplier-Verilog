import numpy as np
import struct

DEBUG = False
MEM_SIZE = 512


def binary(number: float):
    return ''.join('{:0>8b}'.format(c) for c in struct.pack('!f', number))


dim1 = int(input("enter dimension 1: "))
dim2 = int(input("enter dimension 2: "))
dim3 = int(input("enter dimension 3: "))
mat1 = np.random.randn(dim1, dim2).astype('f')
mat2 = np.random.randn(dim2, dim3).astype('f')
mul = np.matmul(mat1, mat2)

if DEBUG:
    print('Dimensions:')
    print(f'mem[0] = {dim1:08b}{dim2:08b}{dim2:08b}{dim3:08b}')
    print('mem[1] = 00000000000000000000000000000000')

    counter = 2
    print("First Matrix: ")
    for i in range(dim1):
        for j in range(dim2):
            print(f"mem[{counter}] = {binary(mat1[i][j])}")
            counter += 1

    print("Second Matrix: ")
    for j in range(dim3):
        for i in range(dim2):
            print(f"mem[{counter}] = {binary(mat2[i][j])}")
            counter += 1

    print(mat1)
    print(mat2)
    print(mul)
else:
    with open('inputs/input.txt', 'w') as f:
        f.write(f'{dim1:08b}{dim2:08b}{dim2:08b}{dim3:08b}\n')
        f.write('00000000000000000000000000000000\n')

        counter = 2
        for i in range(dim1):
            for j in range(dim2):
                f.write(f'{binary(mat1[i][j])}\n')
                counter += 1

        for j in range(dim3):
            for i in range(dim2):
                f.write(f'{binary(mat2[i][j])}\n')
                counter += 1

        while counter < MEM_SIZE - 1:
            f.write('00000000000000000000000000000000\n')
            counter += 1

        f.write('00000000000000000000000000000000')

