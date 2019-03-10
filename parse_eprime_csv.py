# Ben Puccio
# 2018-02-12
#

# parse csv to get stim time info

import glob
import csv
import numpy as np
import pandas as pd

# Set path, get csv file names
path='/Users/ben/Documents/FIBRO_BEHAV_DATA_HC/'
csv_names=glob.glob(path+'*.csv')

# Define variables
params=[]
stim=[]
stim_time=[]
fsl_stimtime=[]
neutral=[]
pain=[]
pa=[]
neu=[]
startcolnum=1000000
finishcolnum=1000000
textcolnum=1000000
scanstartcolnum=1000000
amp=1
start=''
finish=''
scanstart=''
stype=''

for i in csv_names:

    # Get subject numbers and run numbers
    filename = i[:-4]
    sub_run_num = filename[-5:]
    # if sub_run_num[0] =='-':
    #     sub_run_num = sub_run_num[-3:]
    sub = sub_run_num[:-2]
    run = sub_run_num[-1:]

    # Get stim type
    if 'SOC' in filename:
        filetype = 'social'
    if 'PHY' in filename:
        filetype = 'physical'

    # Loop through stim files, get times
    with open(i,'r') as csvfile:
        f = csv.reader(csvfile, delimiter=',')
        rownum = 0
        for row in f:
            colnum=0
            for col in row:
                if rownum ==0:
                    header = row
                    if 'STIM1.OnsetTime' in col:
                        startcolnum = colnum
                    if 'social' in filetype:
                        if 'STIM3.FinishTime' in col:
                            finishcolnum = colnum
                    if 'physical' in filetype:
                        if 'STIM6.FinishTime' in col:
                            finishcolnum = colnum
                    if 'TEXT' in col:
                        textcolnum = colnum
                    if 'StartScan.OnsetTime' in col:
                        scanstartcolnum = colnum
                else:
                    if colnum ==startcolnum:
                        start = col
                    if colnum ==finishcolnum:
                        finish = col
                    if colnum ==textcolnum:
                        if 'social' in filetype:
                            if 'neutralnej' in col:
                                stype = 'neutral'
                            if 'przykre' in col:
                                stype = 'pain'
                        if 'physical' in filetype:
                            if 'enia' in col:
                                stype = 'neutral'
                            if 'bl' in col:
                                stype = 'pain'
                    if colnum ==scanstartcolnum:
                        scanstart = col
                colnum += 1
            params = [start, finish]
            if params !=['','']:
                stime = (float(start))/1000
                ftime = (float(finish))/1000
                duration = ftime - stime
                stim=[stime, duration, amp, stype]
                stim_time.append(stim)
            rownum += 1


    np_stimtime = np.array(stim_time)
    fsl_stimtime = np.delete(np_stimtime,3,1)
    fsl_stimtime = fsl_stimtime.astype(float)

    #subtract scan start time from each timepoint
    scanstarted = (float(scanstart))/1000
    fsl_stimtime[:,0] = np.subtract(fsl_stimtime[:,0],scanstarted)

    #save fsl style stim file
    outfile = ''.join(path+sub+'_'+filetype+'_stimtimes'+'_'+run+'.txt')
    np.savetxt(outfile, fsl_stimtime, fmt="%.3f %.1f %.0f")


    #g = np.vectorize(range(0,len(np_stimtime)))
    for row in range(0,len(np_stimtime)):
        if np_stimtime[row,3] =='neutral':
            neu = fsl_stimtime[row,:]
            neutral.append(neu)
        elif np_stimtime[row,3] =='pain':
            pa = fsl_stimtime[row,:]
            pain.append(pa)

    pain = np.array(pain)
    pain = pain.astype(float)
    outpain = ''.join(path+sub+'_'+filetype+'_'+'pain'+'_'+run+'.txt')
    np.savetxt(outpain, pain, fmt="%.3f %.1f %.0f")
    neutral = np.array(neutral)
    neutral = neutral.astype(float)
    outneutral = ''.join(path+sub+'_'+filetype+'_'+'neutral'+'_'+run+'.txt')
    np.savetxt(outneutral, neutral, fmt="%.3f %.1f %.0f")


    stim = []
    stim_time = []
    neutral = []
    pain = []
    fsl_stimtime = []
