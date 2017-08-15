input_list = [5, 6, 2, 10, 25, 7, 300, 15, 9]

def div_by_five(num):
    if num % 5 == 0:
        return True
    else:
        return False
        #print(' is not divisible by 5')

# xyz = [i for i in input_list if div_by_five(i)]

# for i in xyz:
#     print(i)

# [[print(i,ii) for ii in range(5)] for i in range(5)]

xyz = (print(i) for i in range(5))
for i in xyz:
    i
    # print(i)
