% This script defines some of the constant variable names that are used
% throughout the project.
%
% Copyright, Henryk Blasinski 2017.

[ codePath, parentPath ] = nnGenRootPath();

car2directory = {'MercedesCClass',...
                 'Fiat500',...
                 'MercedesSprinter',...
                 'ToyotaCamry',...
                 'DodgeCharger',...
                 'JeepWrangler',...
                 'SubaruXV',...
                 'ToyotaPrius',...
                 'AudiS7',...
                 'MercedesML',...
                 'MercedesSLS',...
                 'Ferarri599'};
             
assetDir = fullfile('/','share','wandell','data','NN_Camera_Generalization','Assets');
lensDir = fullfile(parentPath,'Parameters');
