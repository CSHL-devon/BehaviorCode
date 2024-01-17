function OdorIdentity

%% Setup
global BpodSystem
S = BpodSystem.ProtocolSettings;

%Initialize parameter GUI plugin
BpodParameterGUI('init', S);

%Initialize analog input module (change serial port as needed)
SniffSensor = BpodAnalogIn('COM5');
SniffSensor.SamplingRate = 1000; %Hz
SniffSensor.nActiveChannels = 1;
SniffSensor.InputRange = cellstr(["-5V:5V","-5V:5V","-5V:5V","-5V:5V","-5V:5V","-5V:5V","-5V:5V","-5V:5V"]); %Make this less stupid
SniffSensor.nSamplesToLog = Inf;

%% Get initial trial info
[TrialInfo] = GetTrialInfo(S.MaxTrials, S.GUI.pRight, S.nConcentrations);
PrevPRight = S.GUI.pRight; %For altering side probabilites later
PrevTrialInfo = TrialInfo;

%% InitializeTrialPlotting
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 600],'name','Outcome plot',... 
    'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); 

%Create outcome subplot
BpodSystem.GUIHandles.OutcomePlot = subplot(2,1,1);
SideOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',2-TrialInfo.TrialTypes);

%Create performance subplot
PerfHandle = subplot(2,1,2);
axes(PerfHandle);
nTrialsToShow = 250;
XData = 1:nTrialsToShow;
YDataLeft = zeros(1, S.MaxTrials);
YDataRight = zeros(1, S.MaxTrials);
PLeft = line(0,0,'LineStyle','-','LineWidth',1,'Marker','*','Color','b');
PRight = line(0,0,'LineStyle','-','LineWidth',1,'Marker','*','Color','k');

set(PerfHandle, 'XLim', [0, length(XData)], 'YLim', [0, 1], 'YTick', [0:0.1:1]);
xlabel(PerfHandle, 'Performance', 'FontSize', 18);
hold(PerfHandle, 'on');

%Initialize total reward amount display
TotalRewardDisplay('init');


%% Main loop

for CurrentTrial = 1:S.MaxTrials
    %Setup sniff sensor triggers for state machine
    LoadSerialMessages('AnalogIn1', {['L' 1], ['L' 0]});

    %Sync parameters from GUI
    S = BpodParameterGUI('sync', S);
    
    %Get water valve time
    RewardAmount = S.GUI.ValveTime;
    ValveTimeLeft = GetValveTimes(RewardAmount, 1);
    ValveTimeRight = GetValveTimes(RewardAmount, 2);
    
    %Update trial structure with new distribution of trial types if needed
    if S.GUI.pRight ~= PrevPRight
        [TrialInfo] = UpdateTrialInfo(PrevTrialInfo, S.MaxTrials, S.GUI.pRight, S.nConcentrations, CurrentTrial);
        PrevPRight = S.GUI.pRight;
        PrevTrialInfo = TrialInfo;
    end
    
    %Send stimulation matrix to olfactometer, and set reinforcers. Only the concentration 
    %changes between trial types in the stimulation matrix (the Concentrations variable 
    %contains "go" values in row 1, and "no-go" values in row 2)
    switch TrialInfo.TrialTypes(CurrentTrial)
        case 1 %Left rewarded
            odorStimMatrix((S.GUI.PureAir*1000), S.GUI.StimulusDuration, 0, 0, 0,... 
                9, S.GUI.LeftOdor, 9, 9, 0, TrialInfo.Concentrations(1,CurrentTrial),...
                TrialInfo.Concentrations(2,CurrentTrial), 0);
            LeftReinforcer = 'Reward';
            RightReinforcer = 'Punish';
            
        case 2 %Right rewarded
            odorStimMatrix((S.GUI.PureAir*1000), S.GUI.StimulusDuration, 0, 0, 0,... 
                9, 9, S.GUI.RightOdor, 9, 0, TrialInfo.Concentrations(2,CurrentTrial),...
                TrialInfo.Concentrations(1,CurrentTrial), 0);
            LeftReinforcer = 'Punish';
            RightReinforcer = 'Reward';
    end
     
    
    %Get stimulus duration from user
    StimulusDuration = ceil(S.GUI.StimulusDuration/1000);
    
    %Build state matrix
    sma = NewStateMatrix();
    if CurrentTrial == 1
        sma = AddState(sma, 'Name', 'ITI',...
        'Timer', S.GUI.ITI,...
        'StateChangeConditions', {'Tup', 'SniffLogStart'},...
        'OutputActions', {});
    else
        sma = AddState(sma, 'Name', 'ITI',...
            'Timer', S.GUI.ITI,...
            'StateChangeConditions', {'Tup', 'SniffLogStart'},...
            'OutputActions', {'Wire2', 1});
    end
    sma = AddState(sma, 'Name', 'SniffLogStart',... 
        'Timer', 0.1,...
        'StateChangeConditions', {'Tup', 'PresentStim'},... 
        'OutputActions', {'AnalogIn1', 1}); 
    sma = AddState(sma, 'Name', 'PresentStim',...
        'Timer', (StimulusDuration+S.GUI.PureAir+0.01),...
        'StateChangeConditions', {'Tup', 'Delay'},... 
        'OutputActions', {'Wire1', 1}); %Wire1 triggers odor machine, Wire2 changes spout position (spout initializes to bottom position)
    sma = AddState(sma, 'Name', 'Delay',...
        'Timer', S.GUI.DelayPeriod,...
        'StateChangeConditions', {'Tup', 'Response'},...
        'OutputActions', {'Wire2', 1});
    sma = AddState(sma, 'Name', 'NoResponse',...
        'Timer', 0.1,...
        'StateChangeConditions', {'Tup', 'SniffLogStop'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'SniffLogStop',... 
        'Timer', 0.1,...
        'StateChangeConditions', {'Tup', 'exit'},... 
        'OutputActions', {'AnalogIn1', 2});
    switch TrialInfo.TrialTypes(CurrentTrial)
        case 1
            if S.GUI.FreeWater == 1
                sma = AddState(sma, 'Name', 'Response',...
                    'Timer', S.GUI.ResponsePeriod,...
                    'StateChangeConditions', {'Port1In', LeftReinforcer, 'Tup', 'FreeWater'},...
                    'OutputActions', {});
            elseif S.GUI.Punish == 0
                sma = AddState(sma, 'Name', 'Response',...
                    'Timer', S.GUI.ResponsePeriod,...
                    'StateChangeConditions', {'Port1In', LeftReinforcer, 'Tup', 'NoResponse'},...
                    'OutputActions', {});
            else
                sma = AddState(sma, 'Name', 'Response',...
                    'Timer', S.GUI.ResponsePeriod,...
                    'StateChangeConditions', {'Port1In', LeftReinforcer, 'Port2In', RightReinforcer, 'Tup', 'NoResponse'},...
                    'OutputActions', {});
            end
            sma = AddState(sma, 'Name', 'FreeWater',...
                'Timer', ValveTimeLeft,...
                'StateChangeConditions', {'Tup', 'FreeWaterGrace'},...
                'OutputActions', {'ValveState', 1});
            sma = AddState(sma, 'Name', 'FreeWaterGrace',...
                'Timer', S.GUI.ResponsePeriod,...
                'StateChangeConditions', {'Port1In', 'Drinking', 'Tup', 'SniffLogStop'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Reward',...
                'Timer', ValveTimeLeft,...
                'StateChangeConditions', {'Port1In', 'Drinking', 'Tup', 'DrinkingGrace'},...
                'OutputActions', {'ValveState', 1});
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 0.1,...
                'StateChangeConditions', {'Port1Out', 'DrinkingGrace'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'DrinkingGrace',...
                'Timer', 0.5,...
                'StateChangeConditions', {'Tup', 'SniffLogStop', 'Port1In', 'Drinking'},...
                'OutputActions', {});
        case 2
            if S.GUI.FreeWater == 1
                sma = AddState(sma, 'Name', 'Response',...
                    'Timer', S.GUI.ResponsePeriod,...
                    'StateChangeConditions', {'Port2In', RightReinforcer, 'Tup', 'FreeWater'},...
                    'OutputActions', {});
            elseif S.GUI.Punish == 0
                sma = AddState(sma, 'Name', 'Response',...
                    'Timer', S.GUI.ResponsePeriod,...
                    'StateChangeConditions', {'Port2In', RightReinforcer, 'Tup', 'NoResponse'},...
                    'OutputActions', {});
            else
                sma = AddState(sma, 'Name', 'Response',...
                    'Timer', S.GUI.ResponsePeriod,...
                    'StateChangeConditions', {'Port1In', LeftReinforcer, 'Port2In', RightReinforcer, 'Tup', 'NoResponse'},...
                    'OutputActions', {});
            end
            sma = AddState(sma, 'Name', 'FreeWater',...
                'Timer', ValveTimeRight,...
                'StateChangeConditions', {'Tup', 'FreeWaterGrace'},...
                'OutputActions', {'ValveState', 2});
            sma = AddState(sma, 'Name', 'FreeWaterGrace',...
                'Timer', S.GUI.ResponsePeriod,...
                'StateChangeConditions', {'Port2In', 'Drinking', 'Tup', 'SniffLogStop'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Reward',...
                'Timer', ValveTimeRight,...
                'StateChangeConditions', {'Port2In', 'Drinking', 'Tup', 'DrinkingGrace'},...
                'OutputActions', {'ValveState', 2});
            sma = AddState(sma, 'Name', 'Drinking',...
                'Timer', 0.1,...
                'StateChangeConditions', {'Port2Out', 'DrinkingGrace'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'DrinkingGrace',...
                'Timer', 0.5,...
                'StateChangeConditions', {'Tup', 'SniffLogStop', 'Port2In', 'Drinking'},...
                'OutputActions', {});
    end
    switch S.GUI.AirPuffOn
        case 0
            sma = AddState(sma, 'Name', 'Punish',...
                'Timer', S.GUI.TimeoutDuration,...
                'StateChangeConditions', {'Tup', 'SniffLogStop'},...
                'OutputActions', {});
        case 1
            sma = AddState(sma, 'Name', 'Punish',... %Air puff
                'Timer', 0.1,...
                'StateChangeConditions', {'Tup', 'Timeout'},...
                'OutputActions', {'ValveState', 8});
            sma = AddState(sma, 'Name', 'Timeout',...
                'Timer', S.GUI.TimeoutDuration,...
                'StateChangeConditions', {'Tup', 'SniffLogStop'},...
                'OutputActions', {});
    end 
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    
%% Build trial data struct
    if ~isempty(fieldnames(RawEvents)) %If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); %Computes trial events from raw data
        BpodSystem.Data.TrialSettings(CurrentTrial) = S; %Adds settings used for the current trial to data
        BpodSystem.Data.TrialTypes(CurrentTrial) = TrialInfo.TrialTypes(CurrentTrial); %Adds trial type of the current trial to data
        BpodSystem.Data.Concentrations((1:2),CurrentTrial) = ceil(TrialInfo.Concentrations((1:2),CurrentTrial)./4095); %Adds concentration of current trial to data
        BpodSystem.Data.Sniff(CurrentTrial) = SniffSensor.getData;
        SaveBpodSessionData;
        
        %Define outcomes for side-outcome plot
        Outcomes = zeros(1,BpodSystem.Data.nTrials);
        for x = 1:BpodSystem.Data.nTrials
            if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Reward(1))
                Outcomes(x) = 1; %hit
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Punish(1))
                Outcomes(x) = 0; %false alarm
            else
                Outcomes(x) = 3; %miss
            end
        end
        
        %Update side-outcome plot
        SideOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,2-TrialInfo.TrialTypes,Outcomes);
        
        %Update performance plot
        %Calculate performance for number of previous trials specified by PerformanceWindow
        if CurrentTrial > S.GUI.PerformanceWindow
            nLeftTrials = 0;
            nRightTrials = 0;
            TrialData = struct('FalseAlarmsLeft',0,'FalseAlarmsRight',0,'MissesLeft',0,'MissesRight',0);
            for ii = (CurrentTrial-S.GUI.PerformanceWindow):CurrentTrial
                switch TrialInfo.TrialTypes(ii)
                    case 1
                        nLeftTrials = nLeftTrials+1;
                        switch Outcomes(ii)
                            case 0
                                TrialData.FalseAlarmsLeft = TrialData.FalseAlarmsLeft+1;
                            case 3
                                TrialData.MissesLeft = TrialData.MissesLeft+1;
                        end
                    case 2
                        nRightTrials = nRightTrials+1;
                        switch Outcomes(ii)
                            case 0
                                TrialData.FalseAlarmsRight = TrialData.FalseAlarmsRight+1;
                            case 3
                                TrialData.MissesRight = TrialData.MissesRight+1;
                        end
                end
            end
            
            LeftIncorrect = TrialData.MissesLeft+TrialData.FalseAlarmsLeft;
            RightIncorrect = TrialData.MissesRight+TrialData.FalseAlarmsRight;
            YDataLeft(CurrentTrial) = (nLeftTrials-LeftIncorrect)/nLeftTrials;
            YDataRight(CurrentTrial) = (nRightTrials-RightIncorrect)/nRightTrials;
            
            %Set previous trials to show
            PreviousTrials = 1:CurrentTrial-1;
            
            %Plot data
            XData = PreviousTrials; LeftPlot = YDataLeft(XData); RightPlot = YDataRight(XData);
            set(PLeft, 'xdata', XData(1:10:end), 'ydata', LeftPlot(1:10:end));
            set(PRight, 'xdata', XData(1:10:end), 'ydata', RightPlot(1:10:end));
            legend(PerfHandle,{'Left','Right'});
            
        end
        
        %Update total reward plot
        if ~isnan(BpodSystem.Data.RawEvents.Trial{CurrentTrial}.States.Reward(1)) || ~isnan(BpodSystem.Data.RawEvents.Trial{CurrentTrial}.States.FreeWater(1))
            TotalRewardDisplay('add', RewardAmount);
        end
    end
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0
        return
    end
end
end
