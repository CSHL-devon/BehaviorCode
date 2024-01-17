%Non-modifiable general parameters
S.MaxTrials = 500;
S.GUI.pRight = 0.5; %Probability of right-lick trial
S.nConcentrations = 1; %Unique concentrations per side (1-4)

%GUI general parameters
S.GUI.PerformanceWindow = 20;
S.GUI.FreeWater = 0;
S.GUIMeta.FreeWater.Style = 'checkbox';
S.GUI.Punish = 1;
S.GUIMeta.Punish.Style = 'checkbox';
S.GUI.AirPuffOn = 0;
S.GUIMeta.AirPuffOn.Style = 'checkbox';
S.GUI.ITI = 16; %Inter-trial interval --Must allow for minimum of 20 seconds cleaning time from previous presentation end--
S.GUI.DelayPeriod = 0.1; %Time subject must wait from stimulus presentation before reward is available
S.GUI.ResponsePeriod = 3; %Time subject has to respond to stimulus presentation
S.GUI.TimeoutDuration = 0.2; %Incorrect response timeout before next trial start
S.GUI.ValveTime = 4; %Amount of liquid in uL delivered during reward

%Odor parameters
S.GUI.PureAir = 8; %Odor build-up time before stimulus presentation in seconds
S.GUI.StimulusDuration = 500; %Stimulus duration in ms
S.GUI.LeftOdor = 1; %Odor number to use for left-lick stimuli (bank 1)
S.GUI.RightOdor = 1; %Odor number to use for right-lick stimuli (bank 2)

%Panels
S.GUIPanels.General = {'pRight', 'PerformanceWindow', 'FreeWater', 'Punish','AirPuffOn', 'ITI', 'DelayPeriod', 'ResponsePeriod',... 
    'TimeoutDuration', 'ValveTime'};
S.GUIPanels.Odor = {'PureAir', 'StimulusDuration', 'LeftOdor', 'RightOdor'};