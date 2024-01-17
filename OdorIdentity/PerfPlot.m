function PerfPlot(PerfHandle, Action, TrialInfo, CurrentTrial, MaxTrials, PerformanceWindow, nTrialsToShow, Outcomes)

switch Action
    
    case 'init' %Initialize axes
        
        axes(PerfHandle);
        XData = 1:nTrialsToShow;
        YDataLeft = zeros(1, MaxTrials); 
        YDataRight = zeros(1, MaxTrials);

        set(PerfHandle, 'XLim', [0, length(XData)], 'YLim', [0, 1], 'YTick', [0:0.1:1]);
        xlabel(PerfHandle, 'Performance', 'FontSize', 15);
        hold(PerfHandle, 'on');
    
    
    case 'update'
        
        %Calculate performance for number of previous trials specified by
        %PerformanceWindow
        if CurrentTrial > PerformanceWindow
            nLeftTrials = 0;
            nRightTrials = 0;
            TrialData = struct('HitsLeft',0,'HitsRight',0,'FalseAlarmsLeft',0,...
                'FalseAlarmsRight',0,'MissesLeft',0,'MissesRight',0);
            for ii = (CurrentTrial-PerformanceWindow):CurrentTrial
                switch TrialInfo.TrialTypes(ii)
                    case 1
                        nLeftTrials = nLeftTrials+1;
                        switch Outcomes(ii)
                            case 1
                                TrialData.HitsLeft = TrialData.HitsLeft+1;
                            case 0
                                TrialData.FalseAlarmsLeft = TrialData.FalseAlarmsLeft+1;
                            case 3
                                TrialData.MissesLeft = TrialData.MissesLeft+1;
                        end
                    case 2
                        nRightTrials = nRightTrials+1;
                        switch Outcomes(ii)
                            case 1
                                TrialData.HitsRight = TrialData.HitsRight+1;
                            case 0
                                TrialData.FalseAlarmsRight = TrialData.FalseAlarmsRight+1;
                            case 3
                                TrialData.MissesRight = TrialData.MissesRight+1;
                        end
                end
            end
            
        LeftIncorrect = TrialData.MissesLeft+TrialData.FalseAlarmsLeft;
        RightIncorrect = TrialData.MissesRight+TrialData.FalseAlarmsRight;
        YDataLeft(CurrentTrial) = (TrialData.HitsLeft-LeftIncorrect)/nLeftTrials;
        YDataRight(CurrentTrial) = (TrialData.HitsRight-RightIncorrect)/nRightTrials;

        %Recompute xlim for plot
        FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
        mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
        mx = mn + nTrialsToShow - 1;
        set(PerfHandle,'XLim',[mn-1 mx+1]);
        
        %Set previous trials to show
        PreviousTrials = mn:CurrentTrial;
        
        %No points shown below trial 10
        if mn<10
            mn=10;
        end
        
        %Plot data
        XData = PreviousTrials; LeftPlot = YDataLeft(XData); RightPlot = YDataRight(XData);
        PerfHandle = line(XData(mn:10:end), LeftPlot(mn:10:end),'LineStyle','-','Color','b');
        PerfHandle = line(XData(mn:10:end), RightPlot(mn:10:end),'LineStyle','-','Color','k');
        
        end
        
end
end
    