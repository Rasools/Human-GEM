%
% FILE NAME:    fixFormulasWithFULLR.m
%
% DATE CREATED: 2018-10-16
%     MODIFIED: 2018-10-19
%
% PROGRAMMER:   Hao Wang
%               Department of Biology and Biological Engineering
%               Chalmers University of Technology
%
% PURPOSE: This script is to detect and fix the probelmatic formulas found
%          with "FULLR" and derivated characters (e.g. "LLLL", "U")
%
% Note: Given that these problmematic formulas were introduced from array
%       structure metAssocHMR2Recon3.mat and actually originated from
%       Recon3Mets2MNX.mat. These files will be systematically modified/
%       corrected by this script.
%

%% Checking the source of these probablematic formulas

load('Recon3Mets2MNX.mat');  % loads as variable "Recon3D"
Recon3Mets2MNX = Recon3D;    % change to variable "Recon3Mets2MNX"

load('Recon3D_301.mat');     % loads as variable "Recon3D"

% find out the changed formulas
Recon3D.mets = regexprep(Recon3D.mets,'\]$','');
Recon3D.mets = regexprep(Recon3D.mets,'\[','_');
if isequal(Recon3D.mets,Recon3Mets2MNX.mets)  % make sure both structures have the same index
    ind_diffFormula = find(~strcmp(Recon3D.metFormulas, Recon3Mets2MNX.metFormulas));
end
fprintf('A total of %u formulas were modifed in array structure Recon3Mets2MNX.\n\n',length(ind_diffFormula));

% create an intermediate cell array for investigation
changedFormulas = cell(length(ind_diffFormula),3);
changedFormulas(:,1) = Recon3D.mets(ind_diffFormula);               %met id
changedFormulas(:,2) = Recon3D.metFormulas(ind_diffFormula);        %before
changedFormulas(:,3) = Recon3Mets2MNX.metFormulas(ind_diffFormula); %after

% Inspection of the content of changedFormulas cell array indicates:
% 1. A total of 744 formulas in Recon3Mets2MNX are different from the original values
% 2. These changes were generated by running the function alphabetizeMetFormulas.m
% 3. Among these changed formulas, 428 originally contain "FULLR" that
% should be replaced with "R"
% 4. The other formulas are changed with reordered elements, and they
% should be just changed back to the original ones
fprintf('These modified formulas are being corrected in this and other associated files.\n\n');



%% Correct formulas in Recon3Mets2MNX

% regenerate formulas by only removing "FULL"
Recon3Mets2MNX.metFormulas = regexprep(Recon3D.metFormulas,'FULL','');



%% Correct formulas in metAssocHMR2Recon3

load('metAssocHMR2Recon3.mat');
m=metAssocHMR2Recon3;   % assign a new name

% remove compartment abbreviations for re-assigning formulas
Recon3Mets2MNX.metsNoComp = regexprep(Recon3Mets2MNX.mets,'\_\w$','');

% only deal with the formulas whose met ids are uniquely mapped to HMR2
% because the rest formulas had been manually checked
uniqueInd = find(cellfun(@numel,m.metR3DID)==1);
tmp=reformatElements(m.metR3DID,'cell2str');   % parepare the Recon3D IDs
[a, b]=ismember(tmp(uniqueInd),Recon3Mets2MNX.metsNoComp);
I=find(a);
m.metR3DFormulas(uniqueInd(I)) = Recon3Mets2MNX.metFormulas(b(I));
m.metCuratedFormulas(uniqueInd(I)) = Recon3Mets2MNX.metFormulas(b(I));

% here fix four formulas of duplicate mets in HMR2
% their curation was done previously in curateHMR2Mets.m
m.metR3DFormulas{find(strcmp('m00555',m.metHMRID))} = 'C11H14O19P3R2';
m.metR3DFormulas{find(strcmp('m02735',m.metHMRID))} = 'C11H14O19P3R2';
m.metR3DFormulas{find(strcmp('m02487',m.metHMRID))} = 'C6H10N2O2S2R4';
m.metR3DFormulas{find(strcmp('m02990',m.metHMRID))} = 'C6H10N2O2S2R4';
m.metCuratedFormulas{find(strcmp('m00555',m.metHMRID))} = 'C11H14O19P3R2';
m.metCuratedFormulas{find(strcmp('m02735',m.metHMRID))} = 'C11H14O19P3R2';
m.metCuratedFormulas{find(strcmp('m02487',m.metHMRID))} = 'C6H10N2O2S2R4';
m.metCuratedFormulas{find(strcmp('m02990',m.metHMRID))} = 'C6H10N2O2S2R4';



%% Correct formulas in humanGEM

load('humanGEM.mat');  % v0.5.0
metFormulas = ihuman.metFormulas;

% remove compartment abbrevs
metsNoComp = regexprep(ihuman.mets,'\_\w$','');
metsNoComp = regexprep(metsNoComp,'^(m\d+)\w$','$1');
metsNoComp = regexprep(metsNoComp,'^(temp\d+)\w$','$1');

% update metFormulas
[hit2HMR, indHMRID] = ismember(metsNoComp,m.metHMRID);
IHMR=find(hit2HMR);
metFormulas(IHMR)=m.metCuratedFormulas(indHMRID(IHMR));

% track the changed formulas by an intermediate cell array
diffList = find(~strcmp(metFormulas, ihuman.metFormulas));
correctedFormulas = cell(1+length(diffList),3);
correctedFormulas(:,1) = ['metID';ihuman.mets(diffList)];          
correctedFormulas(:,2) = ['incorrectFormula';ihuman.metFormulas(diffList)];
correctedFormulas(:,3) = ['correctedFormula';metFormulas(diffList)];
fprintf('A total of %u formulas are corrected in humanGEM.\n\n',length(diffList));



%% clear intermediate variables and save results

clearvars -except ihuman m Recon3Mets2MNX correctedFormulas metFormulas
metAssocHMR2Recon3 = m;
save('metAssocHMR2Recon3.mat','metAssocHMR2Recon3');
save('Recon3Mets2MNX.mat','Recon3Mets2MNX');
ihuman.metFormulas = metFormulas;
writecell2file(correctedFormulas,'fixFormulasWithFULLR.tsv',0,'','',1);
movefile('fixFormulasWithFULLR.tsv','../../ComplementaryData/modelCuration/');



%% initialize elements in rxnConfidenceScores field with 0 and save model

ihuman.rxnConfidenceScores(:) = 0;
save('../../ModelFiles/mat/humanGEM.mat','ihuman');
