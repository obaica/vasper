#!/usr/bin/env python
# -*- coding: utf-8 -*-

###############################################################################
# show vasprun log
###############################################################################

### import modules
import os
import numpy as np
import yaml
from yaml import CLoader as Loader

def get_oszicar_data(oszicar):
    """
    get important data from OSZICAR

        Parameters
        ----------
        oszicar : pymatgen.io.vasp.output.Oszicar object
            description

        Returns
        -------
        summary : dict
            summary data
    """
    summary = oszicar.ionic_steps
    for i in range(len(summary)):
        summary[i]['electronic_steps'] = oszicar.electronic_steps[i]
    return summary

def get_vasprun_data(vasprun):
    """
    get important data from vasprun.xml

        Parameters
        ----------
        vasprun : pymatgen.io.vasp.output.Vasprun object

        Returns
        -------
        summary : dict
            summary data
    """
    vasprun_sum = vasprun.as_dict()
    vasprun_ion_steps = vasprun_sum['output']['ionic_steps']
    atom_num = len(vasprun_ion_steps[0]['structure']['sites'])
    steps_summary = []
    for ion_step in vasprun_ion_steps:
        step_sum = {}
        # lst = ['forces', 'stress', 'electronic_steps', 'e_0_energy', 'e_fr_energy', 'e_wo_entrp']
        lst = ['forces', 'stress', 'electronic_steps']
        for key in lst:
            step_sum[key] = ion_step[key]
        step_sum['volume'] = ion_step['structure']['lattice']['volume']
        stress = ion_step['stress']
        step_sum['in_kB'] = (stress[0][0] + stress[1][1] + stress[2][2]) / 3
        step_sum['Pullay_stress'] = (stress[0][1] + stress[0][2] + stress[1][2]) / 3
        # step_sum['e_wo_entrp_per_atom'] = ion_step['e_wo_entrp'] / atom_num
        # step_sum['energy_diffs'] = [0.]
        # for i in range(len(ion_step['electronic_steps'])-1):
        #     step_sum['energy_diffs'].append(
        #             ion_step['electronic_steps'][i+1]['e_wo_entrp'] \
        #                     - ion_step['electronic_steps'][i]['e_wo_entrp'])
        # energy_diffs_per_atom = np.array(step_sum['energy_diffs']) / atom_num
        # step_sum['energy_diffs_per_atom'] = energy_diffs_per_atom.tolist()
        # step_sum['final_energy_diff'] = step_sum['energy_diffs'][-1]
        # step_sum['final_energy_diff_per_atom'] = step_sum['energy_diffs_per_atom'][-1]
        # enery_lst = ['e_fr_energy', 'e_wo_entrp', 'e_0_energy']
        # for key in enery_lst:
        #     step_sum[key] = step_sum['electronic_steps'][-1][key]
        step_sum['e_wo_entrp'] = step_sum['electronic_steps'][-1]['e_wo_entrp']
        steps_summary.append(step_sum)

    all_summary = {}
    all_summary['converged'] = vasprun_sum['has_vasp_completed']
    all_summary['final_energy'] = float(vasprun_sum['output']['final_energy'])
    all_summary['final_energy_per_atom'] = \
            float(vasprun_sum['output']['final_energy_per_atom'])
    all_summary['volume'] = vasprun_sum['output']['crystal']['lattice']['volume']
    kpt = vasprun_sum['input']['kpoints']['kpoints'][0]
    all_summary['total_kpoints'] = kpt[0] * kpt[1] * kpt[2]
    all_summary['kpoints'] = [kpt[0], kpt[1], kpt[2]]
    all_summary['nkpoints'] = vasprun_sum['input']['nkpoints']
    all_summary['encut'] = vasprun_sum['input']['parameters']['ENMAX']
    all_summary['correlation_function'] = vasprun_sum['run_type']
    all_summary['in_kB'] = steps_summary[-1]['in_kB']
    all_summary['Pullay_stress'] = steps_summary[-1]['Pullay_stress']
    all_summary['atom_num'] = atom_num
    all_summary['forces'] = steps_summary[-1]['forces']
    all_summary['stress'] = steps_summary[-1]['stress']
    # for i in range(len(steps_summary)-1):
    #     all_summary['energy_diff_per_steps'].append(
    #             steps_summary[i+1]['e_wo_entrp'] - steps_summary[i]['e_wo_entrp'])
    # energy_diff_per_steps_per_atom = np.array(all_summary['energy_diff_per_steps']) / atom_num
    # all_summary['energy_diff_per_steps_per_atom'] = energy_diff_per_steps_per_atom.tolist()

    summary = {'all_summary' : all_summary, 'steps_summary' : steps_summary}

    return summary

def get_all_data(vasprun='vasprun.xml', oszicar='OSZICAR'):
    """
    get all data from vasp output

        Parameters
        ----------
        vasprun : str, default 'vasprun.xml'
        oszicar : str, default 'OSZICAR'

        Returns
        -------
        summary : dict
            all data
    """
    vasprun_summary = get_vasprun_data(vasprun)
    oszicar_summary = get_oszicar_data(oszicar)
    for i in range(len(vasprun_summary['steps_summary'])):
        vasprun_summary['steps_summary'][i]['e_fr_energy'] = oszicar_summary[i]['F']
        vasprun_summary['steps_summary'][i]['e_0_energy'] = oszicar_summary[i]['E0']
        vasprun_summary['steps_summary'][i]['dE0'] = oszicar_summary[i]['dE']
        for j in range(len(vasprun_summary['steps_summary'][i]['electronic_steps'])):
            vele_steps = vasprun_summary['steps_summary'][i]['electronic_steps'][j]
            vele_steps['dF'] = oszicar_summary[i]['electronic_steps'][j]['dE']
            vele_steps['deps'] = oszicar_summary[i]['electronic_steps'][j]['deps']
            vele_steps['ncg'] = oszicar_summary[i]['electronic_steps'][j]['ncg']
            vele_steps['rms'] = oszicar_summary[i]['electronic_steps'][j]['rms']
    vasprun_summary['all_summary']['dF_final_ion_final_ele_step'] = vasprun_summary['steps_summary'][-1]['electronic_steps'][-1]['dF']
    vasprun_summary['all_summary']['dE0_final_ion_step'] = vasprun_summary['steps_summary'][-1]['dE0']
    return vasprun_summary

def load_yaml(yamlfile):
    """
    load yaml type file

        Parameters
        ----------
        yamlfile : str
            ex. vasper-log.yaml file
    """
    with open(yamlfile, 'r') as f:
        data = yaml.load(f, Loader=Loader)
    return data
