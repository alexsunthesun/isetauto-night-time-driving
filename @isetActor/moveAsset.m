function assetBranch = moveAsset(obj, scenario, actorDS)
% Place an asset in a driving simulation
%
%   D.Cardinal, Stanford, May, 2023
%

%% For Matlab scenes, we get a scenario along with our object

obj.printPosition(obj, scenario);

assetBranchName = [obj.name '_B'];

ourRecipe = scenario.roadData.recipe;

% Adjust for x-axis being towards the car in Ford scenes
% But not in Matlab SDS Scenes!

%% For vehicles from Matlab's DSD we need to do this differently
% Time constant and coordinate reversal
multiplier = scenario.coordinateMapping * scenario.SampleTime;
aMove = actorDS.Velocity .* multiplier;
assetBranch = piAssetTranslate(ourRecipe,assetBranchName,aMove);

%% SUPPORT FOR rotating assets to a new direction
deltaYaw = (obj.yaw * scenario.yawAdjust) ...
    - (obj.savedYaw * scenario.yawAdjust);
if deltaYaw ~= 0
    assetBranch = piAssetRotate(ourRecipe,assetBranchName,...
        [0 0 (deltaYaw * scenario.yawAdjust)]);
end

end
