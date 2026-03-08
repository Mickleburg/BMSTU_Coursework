#!/bin/python3

import random
import string

def random_strings(k_strings, len_string):
    if k_strings <= 0 or len_string <= 0:
        raise ValueError("The number of lines and the line length must be natural numbers")
    
    characters = string.ascii_letters + string.digits + string.punctuation
    rez = list()

    for _ in range(k_strings):
        new_string = ''.join(characters[random.randint(0, len(characters) - 1)] for _ in range(len_string))
        rez.append(new_string)
    
    return rez
