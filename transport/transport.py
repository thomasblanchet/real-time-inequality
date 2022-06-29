import ot
import numpy as np
import scipy as sp
import pandas as pd
import sys
import datetime

# ---------------------------------------------------------------------------- #
# Datasets and variables to match
# ---------------------------------------------------------------------------- #

# DINA year from command line argument
year = int(sys.argv[1])

# File to match
dina_file = f'dina/usdina{min(year, 2019)}.csv'
cps_file = f'cps/cps{year}.csv'
if year >= 1989:
    scf_file = f'scf/scf{min(year, 2019)}.csv'
else:
    scf_file = None

# Match by these cells
cells = ['married', 'old', 'employed']

# Variables to match within datasets
matching_cps = {
    'dina_wage':  'cps_wage',
    'dina_pens':  'cps_pens',
    'dina_bus':   'cps_bus',
    'dina_int':   'cps_int',
    'dina_drt':   'cps_drt',
    'dina_gov':   'cps_gov',
    'dina_ss':    'cps_ss',
    'dina_welfr': 'cps_welfr'
}
matching_scf = {
    'dina_wage':     'scf_wage',
    'dina_pens_ss':  'scf_pens_ss',
    'dina_bus':      'scf_bus',
    'dina_intdivrt': 'scf_intdivrt',
    'dina_kg':       'scf_kg',
    'dina_wfinbus':  'scf_wfinbus',
    'dina_whou':     'scf_whou',
    'dina_wdeb':     'scf_wdeb'
}

# ---------------------------------------------------------------------------- #
# Perform the matches
# ---------------------------------------------------------------------------- #

# DINA, CPS and SCF data
print(f"* Importing CSVs [{datetime.datetime.now().time()}]")
dina_data = pd.read_csv(dina_file)
cps_data = pd.read_csv(cps_file)
if scf_file is not None:
    scf_data = pd.read_csv(scf_file)

# Split data frames by group
print(f"* Split data by cell [{datetime.datetime.now().time()}]")
dina_groups = dina_data.groupby(cells).groups
cps_groups = cps_data.groupby(cells).groups
if scf_file is not None:
    scf_groups = scf_data.groupby(cells).groups

# Perform transport by cell
matches = []
for group in dina_groups:
    print(f"* Processing cell {group} [{datetime.datetime.now().time()}]")
    dina_subset = dina_data.iloc[dina_groups[group], :]
    cps_subset = cps_data.iloc[cps_groups[group], :]
    if scf_file is not None:
        scf_subset = scf_data.iloc[scf_groups[group], :]

    # For testing only: keep 100 obs in each dataset
    #dina_subset = dina_subset.sample(n=100, random_state=19920902)
    #cps_subset = cps_subset.sample(n=100, random_state=19890324)
    #if scf_file is not None:
    #    scf_subset = scf_subset.sample(n=10, random_state=19560925)

    # Calculate pairwise distance between observations in DINA and CPS
    print(f"    * Calculate cost matrix between DINA and CPS [{datetime.datetime.now().time()}]")
    dina_cols = list(matching_cps.keys())
    cps_cols = [matching_cps[col] for col in dina_cols]

    cost_cps = sp.spatial.distance.cdist(
        dina_subset.loc[:, dina_cols].to_numpy(),
        cps_subset.loc[:, cps_cols].to_numpy(),
        'cityblock'
    )
    cost_cps = cost_cps.astype(np.float64)
    print(f"    * Size of matrix: {sys.getsizeof(cost_cps)/1e9}GB")
    dina_weights = dina_subset['weight'].to_numpy().astype(np.float64)
    cps_weights = cps_subset['weight'].to_numpy().astype(np.float64)

    # Make sum of weights equal to one
    dina_mass = dina_weights.sum()
    cps_mass = cps_weights.sum()
    dina_weights /= dina_mass
    cps_weights /= cps_mass

    # Find optimal transport map
    print(f"    * Find optimal transport map [{datetime.datetime.now().time()}]")
    ot_map = ot.emd(dina_weights, cps_weights, cost_cps, numItermax=1e9)
    del cost_cps

    if scf_file is None:
        print(f"    * No SCF to match, saving transport map for cell [{datetime.datetime.now().time()}]")
        # If no SCF to match, save directly
        nonzero_entries = np.nonzero(ot_map)
        group_matches = pd.DataFrame(
            columns = ('dina_id', 'cps_id', 'weight'),
            index = range(np.count_nonzero(ot_map))
        )
        i = 0
        for entry in np.nditer(nonzero_entries):
            group_matches['dina_id'].iat[i] = dina_subset['id'].iat[int(entry[0])]
            group_matches['cps_id'].iat[i] = cps_subset['id'].iat[int(entry[1])]
            group_matches['weight'].iat[i] = dina_mass*ot_map[entry]
            i += 1
    else:
        print(f"    * Prepare data to match with SCF [{datetime.datetime.now().time()}]")
        # If there is an SCF to match, first create the matched DINA-CPS
        # dataset with required variables
        dina_cols = list(matching_scf.keys())
        scf_cols = [matching_scf[col] for col in dina_cols]
        nonzero_entries = np.nonzero(ot_map)
        dina_cps_subset = pd.DataFrame(
            columns = ['dina_id', 'cps_id', 'weight'] + dina_cols,
            index = range(np.count_nonzero(ot_map))
        )
        i = 0
        for entry in np.nditer(nonzero_entries):
            dina_cps_subset['dina_id'].iat[i] = dina_subset['id'].iat[int(entry[0])]
            dina_cps_subset['cps_id'].iat[i] = cps_subset['id'].iat[int(entry[1])]
            dina_cps_subset['weight'].iat[i] = dina_mass*ot_map[entry]
            for c in dina_cols:
                dina_cps_subset[c].iat[i] = dina_subset[c].iat[int(entry[0])]
            i += 1

        # Do the second transport
        print(f"    * Calculate cost matrix between DINA/CPS and SCF [{datetime.datetime.now().time()}]")
        cost_scf = sp.spatial.distance.cdist(
            dina_cps_subset.loc[:, dina_cols].to_numpy(),
            scf_subset.loc[:, scf_cols].to_numpy(),
            'cityblock'
        )
        cost_scf = cost_scf.astype(np.float64)
        print(f"    * Size of matrix: {sys.getsizeof(cost_scf)/1e9}GB")
        dina_cps_weights = dina_cps_subset['weight'].to_numpy().astype(np.float64)
        scf_weights = scf_subset['weight'].to_numpy().astype(np.float64)

        # Make sum of weights equal to one
        dina_cps_mass = dina_cps_weights.sum()
        scf_mass = scf_weights.sum()
        dina_cps_weights /= dina_cps_mass
        scf_weights /= scf_mass

        # Find optimal transport map
        print(f"    * Find optimal transport map [{datetime.datetime.now().time()}]")
        ot_map = ot.emd(dina_cps_weights, scf_weights, cost_scf, numItermax=1e9)
        del cost_scf

        # Save the double match
        print(f"    * Saving transport map for cell [{datetime.datetime.now().time()}]")
        nonzero_entries = np.nonzero(ot_map)
        group_matches = pd.DataFrame(
            columns = ('dina_id', 'cps_id', 'scf_id', 'weight'),
            index = range(np.count_nonzero(ot_map))
        )
        i = 0
        for entry in np.nditer(nonzero_entries):
            group_matches['dina_id'].iat[i] = dina_cps_subset['dina_id'].iat[int(entry[0])]
            group_matches['cps_id'].iat[i] = dina_cps_subset['cps_id'].iat[int(entry[0])]
            group_matches['scf_id'].iat[i] = scf_subset['id'].iat[int(entry[1])]
            group_matches['weight'].iat[i] = dina_cps_mass*ot_map[entry]
            i += 1

    matches.append(group_matches)

# Concatenate and save results
print(f"* Saving transport maps as CSV [{datetime.datetime.now().time()}]")
matches = pd.concat(matches)
matches.to_csv(f'match/match-{year}.csv', index=False)
