function [TrialInfo] = UpdateTrialInfo(PrevTrialInfo, MaxTrials, pRight, nConcentrations, CurrentTrial)

%Trial type (1 = left trial, 0 = right trial)
NumRightTrials = ceil(MaxTrials*pRight);
TrialTypes = ones(1, MaxTrials);
TrialTypes(1:NumRightTrials) = 2;

%Randomize trials
rng('shuffle');
RandomOrder = randperm(numel(TrialTypes));
TrialInfo.TrialTypes = TrialTypes(RandomOrder);

%Trial concentrations
Concentrations = ones(1, MaxTrials);

%IMPORTANT%

%MFC values are corrected to reach parity between banks (which is why the values
%at the same concentration are different between them). These values are
%not valid for any other odor machine, and would need recalibrating to a
%different rig, or if this one is changed in any way.

%Create values for MFC 1 (12-bit, 4095 = maximum)
MFCValues_1 = [0, 0, 0, 0, ceil(4095*.25), ceil(4095*.5), ceil(4095*.75), 4095];
%Create values for MFC 2
MFCValues_2 = [0, 0, 0, 0, ceil(4095*.25), ceil(4095*.5), ceil(4095*.75), 4095];

%These only exist to make what follows more readable
HalfIndex = floor(MaxTrials/2);
ThirdIndex = floor(MaxTrials/3);
QuarterIndex = floor(MaxTrials/4);

switch nConcentrations
    case 1
        Concentrations(1,1:end) = 8; %Max for go side
        Concentrations(2,1:end) = 1; %Min for no-go side
    case 2
        %Go side
        Concentrations(1,(1:HalfIndex)) = 8;
        Concentrations(1,(HalfIndex+1:end)) = 7;
        %No-Go side
        Concentrations(2,(1:HalfIndex)) = 1;
        Concentrations(2,(HalfIndex+1:end)) = 2;
    case 3 
        %Go side
        Concentrations(1,(1:ThirdIndex)) = 8;
        Concentrations(1,(ThirdIndex+1:ThirdIndex*2)) = 7;
        Concentrations(1,(ThirdIndex*2+1:end)) = 6;
        %No-Go side
        Concentrations(2,(1:ThirdIndex)) = 1;
        Concentrations(2,(ThirdIndex+1:ThirdIndex*2)) = 2;
        Concentrations(2,(ThirdIndex*2+1:end)) = 3;
    case 4
        %Go side
        Concentrations(1,(1:QuarterIndex)) = 8;
        Concentrations(1,(QuarterIndex+1:QuarterIndex*2)) = 7;
        Concentrations(1,(QuarterIndex*2+1:QuarterIndex*3)) = 6;
        Concentrations(1,(QuarterIndex*3+1:end)) = 5;
        %No-Go side
        Concentrations(2,(1:QuarterIndex)) = 1;
        Concentrations(2,(QuarterIndex+1:QuarterIndex*2)) = 2;
        Concentrations(2,(QuarterIndex*2+1:QuarterIndex*3)) = 3;
        Concentrations(2,(QuarterIndex*3+1:end)) = 4;
end

%Randomize concentrations
rng('shuffle');
RandomOrder = randperm(numel(TrialTypes));
TrialInfo.Concentrations = Concentrations((1:2),RandomOrder);

%Substitute previously completed trial info into new trial info
TrialInfo.TrialTypes(1:CurrentTrial-1) = PrevTrialInfo.TrialTypes(1:CurrentTrial-1);
TrialInfo.Concentrations((1:2),1:CurrentTrial-1) = PrevTrialInfo.Concentrations((1:2),1:CurrentTrial-1);

%Determine which side for go, and assign bank-specific MFC values
for ii = CurrentTrial:length(Concentrations)
    if TrialInfo.TrialTypes(ii) == 2
        TrialInfo.Concentrations(1,ii) = MFCValues_2(TrialInfo.Concentrations(1,ii));
        TrialInfo.Concentrations(2,ii) = MFCValues_2(TrialInfo.Concentrations(2,ii));
    else
        TrialInfo.Concentrations(1,ii) = MFCValues_1(TrialInfo.Concentrations(1,ii));
        TrialInfo.Concentrations(2,ii) = MFCValues_1(TrialInfo.Concentrations(2,ii));
    end
end

end