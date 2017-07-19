% This script reads in the sensor irradiance data generated with RTB4+PBRT,
% simulates the images some camera would produce and arranges images and labels
% in a format that matches that of PASCAL VOC datasets.
%
% Copytight, Henryk Blasinski 2017.

close all;
clear all;
clc;

ieInit;

testFraction = 0.3;
recipe = 'Car-Complete-Pinhole';
validClasses = {'City','Car'};
mode = 'fullResRGB';

dataDir = fullfile('/','share','wandell','data','NN_Camera_Generalization','Renderings',recipe);
renderDir = fullfile('renderings','PBRTCloud');

destDir = fullfile('/','scratch','Datasets',recipe);

% Prepare the directory structure
xVal = {'trainval','test'};
if exist(destDir,'dir') == false
    for i=1:length(xVal)
        mkdir(fullfile(destDir,xVal{i},mode,'Annotations'));
        mkdir(fullfile(destDir,xVal{i},mode,'JPEGImages'));
        mkdir(fullfile(destDir,xVal{i},mode,'ImageSets','Main'));
    end
end

% Prepare files listing which image contains which class
fids = cell(length(xVal),length(validClasses)); 
for x=1:length(xVal)
for v=1:length(validClasses)

    fName = fullfile(destDir,xVal{x},mode,'ImageSets','Main',sprintf('%s_%s.txt',lower(validClasses{v}),xVal{x}));
    fids{x,v} = fopen(fName,'w');
    
end
end

% Create a lable map file
fName = fullfile(destDir,sprintf('%s_label_map.pbtxt',recipe));
fid = fopen(fName,'w');
fprintf(fid,'item {\n   id: 0\n   name: ''none_of_the_above''\n}\n\n');

for i=1:length(validClasses)
    fprintf(fid,'item {\n   id: %i\n   name: ''%s''\n}\n\n',i,lower(validClasses{i}));
end
fclose(fid);

%%

fileNames = dir(fullfile(dataDir,renderDir,'*radiance*.mat'));
nFiles = length(fileNames);

rng(1);
shuffling = randperm(nFiles);


for f=1:nFiles
    
    outputFileName = sprintf('%06i',f);
    outputXmlFileName = sprintf('%s.xml',outputFileName);
    outputJpegFileName = sprintf('%s.jpg',outputFileName);
    
    inputFileName = fileNames(shuffling(f)).name;
    
    [pth, name] = fileparts(inputFileName);
    
    %% Load image radiance data
    radianceDataFileName = fullfile(dataDir,renderDir,inputFileName);
    
    radianceData = load(radianceDataFileName);
    
    % Create an oi
    oiParams.lensType = 'pinhole';
    oiParams.filmDistance = 10;
    oiParams.filmDiag = 20;
    
    
    
    oi = BuildOI(radianceData.multispectralImage, [], oiParams);
    oi = oiSet(oi,'name',name);
    oi = oiAdjustIlluminance(oi,100,'mean');
    
    ieAddObject(oi);
    % oiWindow();
    
    sensor = sensorCreate('bayer (rggb)');
    sensor = sensorSet(sensor,'name',name);
    sensor = sensorSet(sensor,'size',oiGet(oi,'size'));
    sensor = sensorSet(sensor,'pixel widthandheight',[oiGet(oi,'hres'), oiGet(oi,'wres')]);
    expTime = autoExposure(oi,sensor,1);
    sensor = sensorSet(sensor,'exposure time',expTime);
    sensor = sensorSet(sensor,'quantizationmethod','8 bit');
    
    
    sensor = sensorCompute(sensor,oi);
    ieAddObject(sensor);
    % sensorWindow();
    
    
    
    ip = ipCreate();
    ip = ipSet(ip,'name',name);
    ip = ipCompute(ip,sensor);
    ieAddObject(ip);
    % ipWindow();
    
    switch mode
        case 'fullResRGB'
            img = oiGet(oi,'rgb image');
    end
        
    
    %% Labels
    
    meshDataFileName = fullfile(dataDir,renderDir,sprintf('%s.mat',strrep(name,'radiance','mesh')));
    labels = uint8(mergeMetadata(meshDataFileName,validClasses));
    
    [bbox, occluded, truncated] = getBndBox(labels,2);
    
    annotation.folder = mode;
    annotation.filename = outputJpegFileName;
    annotation.source.annotation = inputFileName;
    annotation.source.database = recipe;
    annotation.source.image = outputFileName;
    
    annotation.size.depth = size(img,3);
    annotation.size.height = size(img,1);
    annotation.size.width = size(img,2);
    
    annotation.object{1}.name = 'city';
    annotation.object{1}.bndbox.xmax = size(img,2);
    annotation.object{1}.bndbox.xmin = 0;
    annotation.object{1}.bndbox.ymax = size(img,1);
    annotation.object{1}.bndbox.ymin = 0;
    annotation.object{1}.difficult = 0;
    annotation.object{1}.occluded = 0;
    annotation.object{1}.pose = 'Unspecified';
    annotation.object{1}.truncated = 0;
    
    
    if isempty(bbox) == false
        annotation.object{2}.name = 'car';
        annotation.object{2}.bndbox.xmax = bbox(1);
        annotation.object{2}.bndbox.xmin = bbox(2);
        annotation.object{2}.bndbox.ymax = bbox(3);
        annotation.object{2}.bndbox.ymin = bbox(4);
        annotation.object{2}.difficult = 0;
        annotation.object{2}.occluded = occluded;
        annotation.object{2}.pose = 'Unspecified';
        annotation.object{2}.truncated = truncated;
    end
    
    %% Save data
    if f < nFiles * testFraction
        % Test set
        currentSet = 'test';
    else
        currentSet = 'trainval';
    end
        
    imwrite(img,fullfile(destDir,currentSet,mode,'JPEGImages',outputJpegFileName));
    s.annotation = annotation;
    struct2xml(s,fullfile(destDir,currentSet,mode,'Annotations',outputXmlFileName));
    
    sel = cellfun(@(x) strcmp(x,currentSet),xVal);
    
    for o=1:length(annotation.object)
        for c=1:length(validClasses)
            isPresent = strcmpi(annotation.object{o}.name,validClasses{c})*2-1;
            fprintf(fids{sel,c},'%s %i\n',outputFileName,isPresent);
        end
    end
        
    
     
end

% Close files
for i=1:numel(fids)
    fclose(fids{i});
end




