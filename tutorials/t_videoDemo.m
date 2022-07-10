%% Automatically assemble a country road scene
%
% Dependencies
%   ISET3d, ISETAuto, ISETCam and scitran
%   Prefix:  ia- means isetauto
%            pi- means iset3d-v4
%
%   ISET3d-V4: Takes a PBRT file, parse 3D information including lights,
%   materials, textures and meshes. Modify the properties and render it.
%
%   ISETAuto: Assemble ISET3d OBJECT into a complex driving scene.
%
%   ISETCam: Convert scene radiance or optical irradiance data to RGB
%   image with a physically based sensor model and ISP pipeline.
%
% Zhenyi, 2022

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

% for nScene = 1

%% Road initiation

assetDir = fullfile(iaRootPath,'local','assets');
roadDir  = fullfile(iaRootPath,'local','assets','road','road_001');

% The road data
roadData = roadgen('road directory',roadDir, 'asset directory',assetDir);

%% Place the onroad elements

% The driving lanes
roadData.set('onroad car lanes',{'leftdriving','rightdriving'});

% Cars on the road
roadData.set('onroad car names',{'car_001'});

% How many cars on each driving lane.  
% The vector length of these numbers should be the same as the number
% of driving lanes. 

nCars = [randi(20), randi(20)];
% nCars = [15 7];
disp(['Car ',num2double(nCars)]);
roadData.set('onroad n cars', nCars);

% Now place the animals
roadData.set('onroad animal names',{'deer_001'});
nDeer = randi(10);
% nDeer = 1;
disp(['Deer ',num2double(nDeer)]);

roadData.set('onroad n animals',nDeer);
roadData.set('onroad animal lane',{'rightdriving'});

%% Place the offroad elements.  These are animals and trees.  Not cars.

roadData.set('offroad animal names',{'deer_001'});
roadData.set('offroad n animals',[randi(10),randi(10)]);
roadData.set('offroadanimallane',{'rightshoulder','leftshoulder'});

% What are these units?   Meters?
roadData.set('offroad animal min distance',0);
roadData.set('offroad animal layer width',5);

roadData.set('offroad tree names',{'tree_mid_001','tree_mid_002'});
roadData.set('offroad n trees',[100, 50, 10]/2);
roadData.set('offroad tree lane',{'rightshoulder','leftshoulder'});

%% Set up the rendering skymap

skymapLists     = dir(fullfile(iaRootPath,'data/skymap/*.exr'));
skymapRandIndex = randi(size(skymapLists,1));
% skymapRandIndex = 5;
disp(['Skymap idx ',skymapRandIndex]);

skymapName      = skymapLists(skymapRandIndex).name;
roadData.recipe.set('skymap',skymapName);

% useful Docker cmd for reading or making a skymap.
%{
piDockerImgtool('makeequiarea','infile','/Users/zhenyi/git_repo/dev/iset3d-v4/data/lights/dikhololo_night_4k.exr');
%}

%% Set the recipe parameters

thisR = roadData.recipe;

thisR.set('film render type',{'radiance','depth'});

% render quality
thisR.set('film resolution',[1536 864]/4); % 4
thisR.set('pixel samples',2048);           % 512
thisR.set('max depth',3);                  % 5
thisR.set('sampler subtype','pmj02bn');

imageID = iaImageID();

sceneName = 'nightdrive';
outputFile = fullfile(piRootPath, 'local', sceneName, [num2str(imageID),'.pbrt']);

thisR.set('outputFile',outputFile);

%% Assemble the scene using ISET3d methods

assemble_tic = tic();
roadData.assemble();
fprintf('---> Scene assembled in %.f seconds.\n',toc(assemble_tic));

% sceneData.rrDraw('points',points, 'dir',dirs); % visualization function is to fix

%% Use a camera for this car

% lensfile  = 'wide.40deg.6.0mm.json';    % 30 38 18 10
% fprintf('Using lens: %s\n',lensfile);

% random pick a car, use the camera on it.  This are the types of cameras
% so far:
%
%   front_cam
%   back_cam
%   left_mirror_cam
%   camera_type = 'right_mirror_cam'
camera_type = 'front_cam';

% random pick a car, use the camera on it.
roadData.cameraSet(camera_type); % (camera_type, car_id)

%% Render the scene, and maybe an OI

[scene, res] = piWRS(thisR);

%% If you are satisfied, move the camera and make some more

thisR.set('film resolution',[1536 864]/2); %4
thisR.set('pixel samples',2048); %512

from = thisR.get('from');
steps = (0:0.1:0.5);
fnamebase = 'test';
viewDir = thisR.get('lookat direction');
for ii=1:numel(steps)
    thisR.set('from',from + steps(ii)*viewDir);
    scene = piWRS(thisR);
    rgb = sceneGet(scene,'rgb');
    fname = sprintf('%s-%d.jpg',fnamebase,ii);
    fname = fullfile(isetRootPath,'local',fname);
    imwrite(rgb,fname);
end


%% End