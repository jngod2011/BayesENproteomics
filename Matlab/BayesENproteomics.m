function [ProteinOutput,PathwayOutput] = BayesENproteomics(exp_peps,...
    norm_peps,species,groupnum,donors,ptms,norm_method,pepmin,pep_fdr)
%% BayesENproteomics wrapper function called by user.
%%   Output -
%       ProteinOutput - Structure containing protein- and PTM-level
%       quantification
%
%       PathwayOutput - Structure containing Reactome pathway-level
%       quantiifcation
%
%%   Input - 
%       exp_peps - string containing name and extension (e.g. 'name.csv')
%       of file containing quantification and details for peptides to be
%       used in quantification (organised into Progenesis format).
%       
%       norm_peps - string containing name and extension (e.g. 'name.csv')
%       of file containing quantification and details for peptides to be
%       used for normalisation (organised into Progenesis format). Can
%       be same as exp_peps if normalisation is to be performed against
%       entire dataset.
%
%       species - string denoting species used. Currently only 'mouse' or
%       'human' can be entered.
%
%       groupnum - number of experimental conditions.
%
%       donors - numerical row vector containing numbers for each sample 
%       denoting which donor a given sample was derived from. E.g. 8
%       samples from 4 donors, donors = [1,2,3,4,1,2,3,4]; If set to false
%       will assume that each sample comes from a separate unique donor
%       with no pairing between conditions. Enter a vector of ones if donor
%       variability is suspected to be negligible (E.g. for cell lines or
%       100% inbred mouse lines).
%
%       ptms - Optional. Cell array of strings containing PTMs to look for
%       spelt as they are in exp_peps. E.g. {'Phospho', 'Oxidation'}.
%       Defaults to {''}.
%
%       norm_method - Optional. determines how peptide intensities are 
%       normalised prior to model fitting. 'mean','median' or 'sum' 
%       equalises that attribute between all runs. 'MSCMEF' normalises each
%       run in exp_peps to its respective column in norm_peps. Defaults to
%       'median'.
%
%       pepmin - Optional. Minimum number of peptides/proteins required for
%       a protein/pathway to be reported. Defaults to 3.
%
%       pep_fdr - Optional. Scalar number >0 and <=1 denotes peptide false 
%       discovery p-value cutoff. Following Benjamini-Hochberg adjustment,
%       peptides with identification p-values above this threshold will be
%       discarded. Defaults to 0.2.
%
%% Defaults
if isempty(ptms); ptms = {''}; end
if isempty(norm_method); norm_method = 'median'; end
if isempty(pepmin); pepmin = 3; end
if isempty(pep_fdr); pep_fdr = 0.2; end

%% Load peptide lists (must be in working directory when function called)
exp_peps2 = readtable(exp_peps,'FileType','text','Delimiter',',');
exp_peps2 = table2cell(exp_peps2);
norm_peps2 = readtable(norm_peps,'FileType','text','Delimiter',',');
norm_peps2 = table2cell(norm_peps2);

%% Do regression fits for proteins and pathways, if necessary
[ProteinOutput.Abds,...             %Protein-level fold changes
    ProteinOutput.NormedPeps,...    %All peptides used in calculation (normalised log2 intensities)
    ~,...                           
    ProteinOutput.PTMs,...          %PTM-level output
    ProteinOutput.stats,....
    uniprotall]...
    = DataProcessProtein(norm_peps2, exp_peps2,...                          %Necessary
    norm_method,pepmin,donors,false,ptms,species,'BHFDR',...              %Optional (except species and donors)
    'bayes','full',pep_fdr, 1, false,true);                               %Optional

if nargout == 2
    [PathwayOutput.Abds,...
        PathwayOutput.UniProt2Reactome]...
        = DataProcessPathways(ProteinOutput.Abds, species, pepmin,...
        uniprotall, false, groupnum, false);
end
end