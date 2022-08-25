#!/bin/python
'''
Script to select valid observations from data downloaded by get_flux.R. 
Intended to be used on data from a single year.
Writes valid observations to a csv called
`SITE/flux_observations/flux_observations_YYYY.csv`
where YYYY is the year.

usage:
python src/select_complete_observations.py --site=TALL --file_path=TALL/filesToStack00200/

or in container:
docker run -ti --rm -v "$PWD":/home/docker -w /home/docker --user $(id -u):$(id -g) quay.io/kulpojke/neon-timeseries:py-shadd689ac python src/select_complete_observations.py --site=TALL --file_path=/home/docker/TALL/filesToStack00200/
'''

import os
import pandas as pd
pd.options.mode.chained_assignment = None
import argparse
from tqdm import tqdm


def parse_arguments():
    '''parses the arguments, returns args Namespace'''

    # init parser
    parser = argparse.ArgumentParser()

    # add args

    parser.add_argument(
        '--site',
        type=str,
        required=True,
        help='NEON site abreviation, e.g. "TEAK"'
    )

    parser.add_argument(
        '--file_path',
        type=str,
        required=True,
        help='Path to `filesToStack00200` directory containing flux data.'
    )

    # parse the args
    args = parser.parse_args()

    return args


def get_valid_observations(site, file_path):
    '''
    Goes through all csvs in file_path returns a df of valid
    observations. Valid means that they exist and have a
    passing final QF flag.

    parameters:
        site      - str - Four letter code of NEON site being considered, e.g. 'TALL' 
        file_path - str - Path to `filesToStack00200` directory containing flux data.
    '''

    # make empty list for dfs
    dfs = []

    # make list of the files for the site
    files = [
            os.path.join(file_path, f)
            for f
            in os.listdir(file_path)
            if ('.h5' in f)
            ]


    for f in tqdm(files):

        # get the day
        day = pd.to_datetime(f.split('nsae.')[1].split('.')[0]).date()

        # open the hdf
        hdf = pd.HDFStore(f)

        try:
            # get the flux quality flags
            qfqm_CO2 = hdf.get(f'{site}/dp04/qfqm/fluxCo2/nsae')
            qfqm_H2O = hdf.get(f'{site}/dp04/qfqm/fluxH2o/nsae')
            qfqm_T = hdf.get(f'{site}/dp04/qfqm/fluxTemp/nsae')
            qfqm_foot = hdf.get(f'{site}/dp04/qfqm/foot/turb')

            # Select observations with no bad flags
            qfqm_CO2  = qfqm_CO2.loc[qfqm_CO2.qfFinl == 0]
            qfqm_H2O  = qfqm_H2O.loc[qfqm_H2O.qfFinl == 0]
            qfqm_T    = qfqm_T.loc[qfqm_T.qfFinl == 0]
            qfqm_foot = qfqm_foot.loc[qfqm_foot.qfFinl == 0]

            # get the footprint input stats
            stat = hdf.get(f'{site}/dp04/data/foot/stat/')

            # get indices of the dfs from above
            istat  = stat.set_index('timeBgn').index
            iqfqmC = qfqm_CO2.set_index('timeBgn').index
            iqfqmH = qfqm_H2O.set_index('timeBgn').index
            iqfqmT = qfqm_T.set_index('timeBgn').index
            iqfqmf = qfqm_foot.set_index('timeBgn').index

            # keep only entries in stat which correspond to good
            # qfqm flags for all variables
            stat = stat[
                (istat.isin(iqfqmC)) &
                (istat.isin(iqfqmH)) &
                (istat.isin(iqfqmT)) &
                (istat.isin(iqfqmf))
            ]

            # get the flux data
            fluxCo2 = hdf.get(f'{site}/dp04/data/fluxCo2/nsae').drop('timeEnd', axis=1)
            fluxH2o = hdf.get(f'{site}/dp04/data/fluxH2o/nsae').drop('timeEnd', axis=1)
            fluxTemp = hdf.get(f'{site}/dp04/data/fluxTemp/nsae').drop('timeEnd', axis=1)

            # now merge dfs onto stat
            stat = stat.merge(fluxCo2, how='left', on='timeBgn', suffixes=('_stat', ''))
            stat = stat.merge(fluxH2o, how='left', on='timeBgn', suffixes=('_CO2', ''))
            stat = stat.merge(fluxTemp, how='left', on='timeBgn', suffixes=('_H20', '_T'))

            dfs.append(stat)

            # close file
            hdf.close()
    
        except KeyError:
            pass

    df = pd.concat(dfs)

    return df


if __name__ == '__main__':

    # parse the args
    args = parse_arguments()

    # make a directory for results, if absent
    parent = os.path.dirname(args.file_path)
    results = os.path.join(parent, 'flux_observations')
    os.makedirs(results, exist_ok=True)

    # print feedback
    print()
    print('Finding valid observations ...')

    # get the valid observations
    df = get_valid_observations(args.site, args.file_path)

    # get year of observations
    year = pd.to_datetime(df.timeBgn).min().year

    # print feedback
    print()
    print(f'Found {len(df)} valid observations for {args.site}-{year}.')

    # write observations to csv within results dir
    csv_path = os.path.join(results, f'flux_observations_{year}.csv')
    df.to_csv(csv_path, index=False)