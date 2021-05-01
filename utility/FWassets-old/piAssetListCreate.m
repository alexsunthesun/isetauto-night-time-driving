function assetlist = piAssetListCreate(varargin)
% Create an assetList for stationary objects on flywheel
%
% Syntax:
%
% 
% Input:
%  N/A
% Key/val variables
%   class:    session name on flywheel;
%   subclass: acquisition names on flywheel
%   scitran:  
%
% Output:
%   assetList: Assigned assets libList used for stationary objects;
%
%
% Zhenyi
%
% See also

%%
p = inputParser;
p.addParameter('class','');
p.addParameter('subclass','');
p.addParameter('scitran',[]);
p.parse(varargin{:});

st = p.Results.scitran;

if isempty(st)
    st = scitran('stanfordlabs');
end

sessionname      = p.Results.class;
acquisitionname  = p.Results.subclass;

%% Find all the acuisitions
session = st.fw.lookup(sprintf('wandell/Graphics auto/assets/%s',sessionname));
% session = subject.sessions.findOne(sprintf('label=%s',sessionname));
acqs    = session.acquisitions();

%%
nDatabaseAssets = length(acqs);
if isempty(acquisitionname)
    %% No acquisition name. Loop across all of them.
    %
    % We had a variable called thisIdx, but it was undefined.
    % So I replaced it with the loop variable, ii.
    % Causing problems, I fear (BW).
    for ii = 1:nDatabaseAssets
        acqLabel = acqs{ii}.label;
        localFolder = fullfile(piRootPath,'local','AssetLists',acqLabel);
        destName_recipe = fullfile(localFolder,sprintf('%s.json',acqLabel));
        if ~exist(localFolder,'dir')
            mkdir(localFolder)
        end
        
        thisR = piFWRecipeDownload(thisAcq{ii}.files);
        
        
        % Download the recipe and the resources
        thisRecipe   = stFileSelect(acqs{ii}.files,'type','source code');
        thisResource = stFileSelect(acqs{ii}.files,'type','CG Resource');
        thisRecipe{1}.download(destName_recipe);
        
        % Read the recipe and create an entry in the assetlist
        thisR = jsonread(destName_recipe);
        assetlist(ii).name = acqLabel;
        assetlist(ii).material.list = thisR.materials.list;
        assetlist(ii).material.txtLines = thisR.materials.txtLines;
        assetlist(ii).geometry = thisR.assets;
        assetlist(ii).geometryPath = fullfile(localFolder,'scene','PBRT','pbrt-geometry');
        assetlist(ii).fwInfo       = [acqs{ii}.id,' ',thisResource{1}.name];
    end
    
    fprintf('%d files added to the asset list.\n',nDatabaseAssets);
else
    %% We have the name, so just one.  Not sure why we have a loop on dd (BW)
    thisAcq = stSelect(acqs,'label',acquisitionname);
    for dd = 1:length(thisAcq)
        acqLabel = thisAcq{dd}.label;
        localFolder = fullfile(piRootPath,'local','AssetLists',acqLabel);
        
        destName_recipe = fullfile(localFolder,sprintf('%s.json',acqLabel));
        if ~exist(localFolder,'dir')
            mkdir(localFolder)
        end
        thisRecipe = stFileSelect(thisAcq{dd}.files,'type','source code');

        thisR = piFWRecipeDownload(thisAcq{dd}.files);
        
        thisResource = stFileSelect(thisAcq{dd}.files,'type','CG Resource');
        assetlist(dd).name = acqLabel;
        assetlist(dd).material.list     = thisR.materials.list;
        assetlist(dd).material.txtLines = thisR.materials.txtLines;
        assetlist(dd).geometry          = thisR.assets;
        assetlist(dd).geometryPath      = fullfile(localFolder,'scene','PBRT','pbrt-geometry');
        assetlist(dd).fwInfo            = [thisAcq{dd}.id,' ',thisResource{1}.name];
    end
    fprintf('%s added to the list.\n',acqLabel);
end
end