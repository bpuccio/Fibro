from os import remove
from os.path import join
import glob

import pandas as pd
from convert_eprime.utils import remove_unicode

from convert_eprime.convert import text_to_csv

path='/Users/ben/Documents/FIBRO_BEHAV_DATA/'
csv_names=glob.glob(path+'*.txt')

for i in csv_names:

    filename = i[:-4]
    outfile=''.join(filename+'.csv')

    with open(i, 'r') as fo:
        raw_data = fo.readlines()[:20]
        raw_data = [l.rstrip() for l in raw_data]

    # Remove unicode characters.
    filtered_data = [remove_unicode(row) for row in raw_data]

    text_to_csv(i, outfile)
