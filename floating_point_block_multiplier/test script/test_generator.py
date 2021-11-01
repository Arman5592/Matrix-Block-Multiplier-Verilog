import numpy as np
import struct

DEBUG = False
MEM_SIZE = 512


def convert_to_int(mantissa_str):
    power_count = -1
    mantissa_int = 0
    for i in mantissa_str:
        mantissa_int += (int(i) * pow(2, power_count))
        power_count -= 1

    return mantissa_int + 1


def binary_to_float(value: str):
    sign_bit = int(value[0])
    exponent_bias = int(value[1: 9], 2)
    exponent_unbias = exponent_bias - 127
    mantissa_str = value[9:]
    mantissa_int = convert_to_int(mantissa_str)
    return pow(-1, sign_bit) * mantissa_int * pow(2, exponent_unbias)


def binary(number: float):
    return ''.join('{:0>8b}'.format(c) for c in struct.pack('!f', number))


def compare_output_with_expected(m: int = None, n: int = None):
    with open('output.txt', 'r') as file:
        output = file.read()
    with open('expected.txt', 'r') as file:
        expected = file.read()
    output_lines = output.strip().split('\n')
    expected_lines = expected.strip().split('\n')
    if m and n:
        for i in range(m):
            for j in range(n):
                expected_num = binary_to_float(expected_lines[i * n + j])
                output_num = binary_to_float(output_lines[i * n + j])
                print(f'expected entry[{i+1}, {j+1}]:  {expected_lines[i * n + j]}   decimal value = {expected_num}')
                print(f'output entry[{i+1}, {j+1}]:    {output_lines[i * n + j]}   decimal value = {output_num}')
                print(f'difference: {abs(expected_num - output_num)}\n\n')
    else:
        for i in range(len(output_lines)):
            expected_num = binary_to_float(expected_lines[i])
            output_num = binary_to_float(output_lines[i])
            print(f'expected entry:  {expected_lines[i]}   decimal value = {expected_num}')
            print(f'output entry:    {output_lines[i]}   decimal value = {output_num}')
            print(f'difference: {abs(expected_num - output_num)}\n\n')


if __name__ == '__main__':

    dim1 = int(input("enter dimension 1: "))
    dim2 = int(input("enter dimension 2: "))
    dim3 = int(input("enter dimension 3: "))
    mat1 = np.random.randn(dim1, dim2).astype('f')
    mat2 = np.random.randn(dim2, dim3).astype('f')

    multiply = np.matmul(mat1, mat2).astype('f')

    print("First Matrix: \n")
    for i in range(dim1):
        for j in range(dim2):
            print(f"{mat1[i][j]}  |", end='')
        print()

    print("\nSecond Matrix: \n")
    for i in range(dim2):
        for j in range(dim3):
            print(f"{mat2[i][j]}  |", end='')
        print()

    print("\nResult: \n")
    for i in range(dim1):
        for j in range(dim3):
            print(f"{multiply[i][j]}  |", end='')
        print()

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
        print(multiply)
    else:
        with open('input.txt', 'w') as f:
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

        if dim1 % 2 == 1:
            mat1 = np.append(mat1, np.zeros((1, dim2), dtype=np.float32), axis=0)
            dim1 += 1

        if dim2 % 2 == 1:
            mat1 = np.append(mat1, np.zeros((dim1, 1), dtype=np.float32), axis=1)
            mat2 = np.append(mat2, np.zeros((1, dim3), dtype=np.float32), axis=0)
            dim2 += 1

        if dim3 % 2 == 1:
            mat2 = np.append(mat2, np.zeros((dim2, 1), dtype=np.float32), axis=1)
            dim3 += 1

        mul = np.matmul(mat1, mat2).astype('f')

        with open('expected.txt', 'w') as f:
            with open('input.txt', 'r') as inp:
                lines = inp.readlines()
                lines.reverse()
                counter = 0
                for i in range(dim1):
                    for j in range(dim3):
                        lines[counter] = f'{binary(mul[i][j])}\n'
                        counter += 1
                f.writelines(lines)
