%% qEEGLAB.m
% Displays EEG data using ACNS-compatible montages.
% Displays trends using many described and novel qEEG metrics.
% Exports qEEG trends to make correlations with external measures (GCS).
%
% Copyright 2015-2017 by Izad Rasheed MD MS
% The Ken & Ruth Davee Department of Neurology
% Feinberg School of Medicine, Northwestern University
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function qEEGLAB
%% Construct main EEG GUI
fEEG = figure;
fEEG.Name = 'EEG';
fEEG.NumberTitle = 'off';
fEEG.MenuBar = 'none'; %use 'none' to hide default MATLAB menu/toolbar
fEEG.ToolBar = 'none';
fEEG.BusyAction = 'cancel';
fEEG.KeyPressFcn = @controlEEG;
fEEG.Units = 'normalized';
fEEG.OuterPosition = [0 0 1 1];

mFile = uimenu(fEEG,'Label','File');
mOpen = uimenu(mFile,'Label','Open...','Callback',@GOpen);
mClose = uimenu(mFile,'Label','Close','Callback',@GClose,'Enable','off');
mSavePic = uimenu(mFile,'Label','Save Picture...','Callback',@GSavePic,...
    'Enable','off');
mSaveReport = uimenu(mFile,'Label','Save Report...',...
    'Callback',@GSaveRep,'Enable','off');

mOptions = uimenu(fEEG,'Label','Options','Enable','off');
mChannel = uimenu(mOptions,'Label','Channel Select...',...
    'Callback',@GChannel);
mMontage = uimenu(mOptions,'Label','Montage');
 mLB = uimenu(mMontage,'Label','Longitudinal Bipolar',...
     'Enable','off','Separator','on');
  mLB181 = uimenu(mMontage,'Label','LB18.1','Checked','on',...
      'Enable','off','Callback',@GMontage);
  mLB182 = uimenu(mMontage,'Label','LB18.2','Callback',@GMontage);
  mLB183 = uimenu(mMontage,'Label','LB18.3','Callback',@GMontage);
 mTB = uimenu(mMontage,'Label','Transverse Bipolar',...
     'Enable','off','Separator','on');
  mTB181 = uimenu(mMontage,'Label','TB18.1','Callback',@GMontage);
  mTB182 = uimenu(mMontage,'Label','TB18.2','Callback',@GMontage);
 mR = uimenu(mMontage,'Label','Referential','Enable','off',...
     'Separator','on');
  mR181 = uimenu(mMontage,'Label','R18.1','Callback',@GMontage);
  mR182 = uimenu(mMontage,'Label','R18.2','Callback',@GMontage);
  mR183 = uimenu(mMontage,'Label','R18.3','Callback',@GMontage);
  mRCz  = uimenu(mMontage,'Label','Cz Reference','Callback',@GMontage);
  mRAvg = uimenu(mMontage,'Label','Avg Reference','Callback',@GMontage);
mFilter  = uimenu(mOptions,'Label','Filter Select...',...
    'Callback',@GFilter,'Enable','off');

mAnalyze = uimenu(fEEG,'Label','Analyze','Enable','off');
 mBandpower = uimenu(mAnalyze,'Label','Bandpower','Callback',@GBandpower);
 maEEG = uimenu(mAnalyze,'Label','aEEG','Callback',@GaEEG);
 mDomFreq = uimenu(mAnalyze,'Label','Dominant Frequencies','Callback',...
     @GDomFreq);
 mSpectralEdge = uimenu(mAnalyze,'Label','Spectral Edge Frequency',...
     'Callback',@GSpectralEdge);

mWindows = uimenu(fEEG,'Label','Windows','Enable','off');
 mEEG = uimenu(mWindows,'Label','EEG','Enable','off',...
     'Checked','on');
 mSTFTMontage = uimenu(mWindows,'Label','STFT Montage',...
     'Callback',@GSTFTMontage);

%% Create initial variables
xSens = 10; % seconds per page
PPmm = get(groot,'ScreenPixelsPerInch')/25.4; % px/mm
ySens = 7; % uV/px NOT mm!!
xOffset = 1;
% Just to give these global scope
nChannels = 19; %montage (18) + EKG (1);
yOffset = linspace(-1e3,1e3,nChannels+2); %Two extra as buffers, tight axes
yLabels = cell(1,21);
maxX = 0;
raw = 0;
sRate = 0;
EEG = zeros(20);
nSamples = 0;
montage = 'LB18.1';
filename = '';
ChannelData = 0;
tStart = 0;
fSTFTMontage = figure;
fSTFTMontage.Visible = 'off';
fSTFTMontage.Name = 'Short-Time Fourier Transform Over Montage';
fSTFTMontage.NumberTitle = 'off';
fSTFTMontage.MenuBar = 'none'; %use 'none' to hide MATLAB menubar
fSTFTMontage.ToolBar = 'none';
fSTFTMontage.BusyAction = 'cancel';
fSTFTMontage.KeyPressFcn = @controlEEG;
fSTFTMontage.Units = 'normalized';
fSTFTMontage.OuterPosition = [0 0 1 1];

%% Construct EEG time-domain "scroll"
figure(fEEG)
fa = gca;
fa.XLimMode = 'manual';
fa.XGrid = 'on';
fa.YLimMode = 'manual';
fa.YTickMode = 'manual';
fa.YTickLabelMode = 'manual';
fa.Position = [0.05 0.05 0.90 0.90]; % 5% margin around edges
fa.Visible = 'off'; % hide until something is opened

disp('qEEGLAB loaded. To begin, open a file. Close the window to exit.');
waitfor(fEEG)

%% Montages
% ACNS LB18.1 longitudinal bipolar, variant 1, 18 channels + EKG
    function LB181
        EEG(1,:)  = raw(1,:)  - raw(11,:); % 1-11 = Fp1-F7
        EEG(2,:)  = raw(11,:) - raw(13,:); %11-13 =  F7-T7
        EEG(3,:)  = raw(13,:) - raw(15,:); %13-15 =  T7-P7
        EEG(4,:)  = raw(15,:) - raw(9,:);  %15- 9 =  P7-O1
        EEG(5,:)  = raw(1,:)  - raw(3,:);  % 1- 3 = Fp1-F3
        EEG(6,:)  = raw(3,:)  - raw(5,:);  % 3- 5 =  F3-C3
        EEG(7,:)  = raw(5,:)  - raw(7,:);  % 5- 7 =  C3-P3
        EEG(8,:)  = raw(7,:)  - raw(9,:);  % 7- 9 =  P3-O1
        EEG(9,:)  = raw(17,:) - raw(18,:); %17-18 =  Fz-Cz
        EEG(10,:) = raw(18,:) - raw(19,:); %18-19 =  Cz-Pz
        EEG(11,:) = raw(2,:)  - raw(4,:);  % 2- 4 = Fp2-F4
        EEG(12,:) = raw(4,:)  - raw(6,:);  % 4- 6 =  F4-C4
        EEG(13,:) = raw(6,:)  - raw(8,:);  % 6- 8 =  C4-P4
        EEG(14,:) = raw(8,:)  - raw(10,:); % 8-10 =  P4-O2
        EEG(15,:) = raw(2,:)  - raw(12,:); % 2-12 = Fp2-F8
        EEG(16,:) = raw(12,:) - raw(14,:); %12-14 =  F8-T8
        EEG(17,:) = raw(14,:) - raw(16,:); %14-16 =  T8-P8
        EEG(18,:) = raw(16,:) - raw(10,:); %16-10 =  P8-O2
        yLabels(1:19) = {'','Fp1-F7','F7-T7','T7-P7','P7-O1','Fp1-F3',...
                            'F3-C3' ,'C3-P3','P3-O1','Fz-Cz','Cz-Pz' ,...
                            'Fp2-F4','F4-C4','C4-P4','P4-O2','Fp2-F8',...
                            'F8-T8' ,'T8-P8','P8-O2'};
        fa.YTickLabel = flip(yLabels);
    end

% ACNS LB18.2 longitudinal bipolar, variant 2, 18 channels + EKG
    function LB182
        EEG(1,:)  = raw(17,:) - raw(18,:); %17-18 =  Fz-Cz
        EEG(2,:)  = raw(18,:) - raw(19,:); %18-19 =  Cz-Pz
        EEG(3,:)  = raw(1,:)  - raw(3,:);  % 1- 3 = Fp1-F3
        EEG(4,:)  = raw(3,:)  - raw(5,:);  % 3- 5 =  F3-C3
        EEG(5,:)  = raw(5,:)  - raw(7,:);  % 5- 7 =  C3-P3
        EEG(6,:)  = raw(7,:)  - raw(9,:);  % 7- 9 =  P3-O1
        EEG(7,:)  = raw(2,:)  - raw(4,:);  % 2- 4 = Fp2-F4
        EEG(8,:)  = raw(4,:)  - raw(6,:);  % 4- 6 =  F4-C4
        EEG(9,:)  = raw(6,:)  - raw(8,:);  % 6- 8 =  C4-P4
        EEG(10,:) = raw(8,:)  - raw(10,:); % 8-10 =  P4-O2
        EEG(11,:) = raw(1,:)  - raw(11,:); % 1-11 = Fp1-F7
        EEG(12,:) = raw(11,:) - raw(13,:); %11-13 =  F7-T7
        EEG(13,:) = raw(13,:) - raw(15,:); %13-15 =  T7-P7
        EEG(14,:) = raw(15,:) - raw(9,:);  %15- 9 =  P7-O1
        EEG(15,:) = raw(2,:)  - raw(12,:); % 2-12 = Fp2-F8
        EEG(16,:) = raw(12,:) - raw(14,:); %12-14 =  F8-T8
        EEG(17,:) = raw(14,:) - raw(16,:); %14-16 =  T8-P8
        EEG(18,:) = raw(16,:) - raw(10,:); %16-10 =  P8-O2
        yLabels(1:19) = {'','Fz-Cz' ,'Cz-Pz' ,'Fp1-F3','F3-C3','C3-P3' ,...
                            'P3-O1' ,'Fp2-F4','F4-C4' ,'C4-P4','P4-O2' ,...
                            'Fp1-F7','F7-T7' ,'T7-P7' ,'P7-O1','Fp2-F8',...
                            'F8-T8' ,'T8-P8' ,'P8-O2'};
        fa.YTickLabel = flip(yLabels);
    end

% ACNS LB18.3 longitudinal bipolar, variant 3, 18 channels + EKG
    function LB183
        EEG(1,:)  = raw(1,:)  - raw(11,:); % 1-11 = Fp1-F7
        EEG(2,:)  = raw(11,:) - raw(13,:); %11-13 =  F7-T7
        EEG(3,:)  = raw(13,:) - raw(15,:); %13-15 =  T7-P7
        EEG(4,:)  = raw(15,:) - raw(9,:);  %15- 9 =  P7-O1
        EEG(5,:)  = raw(2,:)  - raw(12,:); % 2-12 = Fp2-F8
        EEG(6,:)  = raw(12,:) - raw(14,:); %12-14 =  F8-T8
        EEG(7,:)  = raw(14,:) - raw(16,:); %14-16 =  T8-P8
        EEG(8,:)  = raw(16,:) - raw(10,:); %16-10 =  P8-O2
        EEG(9,:)  = raw(1,:)  - raw(3,:);  % 1- 3 = Fp1-F3
        EEG(10,:) = raw(3,:)  - raw(5,:);  % 3- 5 =  F3-C3
        EEG(11,:) = raw(5,:)  - raw(7,:);  % 5- 7 =  C3-P3
        EEG(12,:) = raw(7,:)  - raw(9,:);  % 7- 9 =  P3-O1
        EEG(13,:) = raw(2,:)  - raw(4,:);  % 2- 4 = Fp2-F4
        EEG(14,:) = raw(4,:)  - raw(6,:);  % 4- 6 =  F4-C4
        EEG(15,:) = raw(6,:)  - raw(8,:);  % 6- 8 =  C4-P4
        EEG(16,:) = raw(8,:)  - raw(10,:); % 8-10 =  P4-O2        
        EEG(17,:) = raw(17,:) - raw(18,:); %17-18 =  Fz-Cz
        EEG(18,:) = raw(18,:) - raw(19,:); %18-19 =  Cz-Pz
        yLabels(1:19) = {'','Fp1-F7','F7-T7','T7-P7','P7-O1','Fp2-F8',...
                            'F8-T8','T8-P8','P8-O2','Fp1-F3','F3-C3',...
                            'C3-P3','P3-O1','Fp2-F4','F4-C4','C4-P4',...
                            'P4-O2','Fz-Cz','Cz-Pz'};
        fa.YTickLabel = flip(yLabels);
    end

% ACNS TB18.1 transverse bipolar, variant 1, 18 channels + EKG
    function TB181
        EEG(1,:)  = raw(11,:) - raw(1,:);  %11-1  =  F7-Fp1
        EEG(2,:)  = raw(1,:)  - raw(2,:);  % 1-2  = Fp1-Fp2
        EEG(3,:)  = raw(2,:)  - raw(12,:); % 2-12 = Fp2-F8
        EEG(4,:)  = raw(11,:) - raw(3,:);  %11-3  =  F7-F3
        EEG(5,:)  = raw(3,:)  - raw(17,:); % 3-17 =  F3-Fz
        EEG(6,:)  = raw(17,:) - raw(4,:);  %17-4  =  Fz-F4
        EEG(7,:)  = raw(4,:)  - raw(12,:); % 4-12 =  F4-F8
        EEG(8,:)  = raw(13,:) - raw(5,:);  % 13-5 =  T7-C3
        EEG(9,:)  = raw(5,:)  - raw(18,:); % 5-18 =  C3-Cz
        EEG(10,:) = raw(18,:) - raw(6,:);  %18-6  =  Cz-C4
        EEG(11,:) = raw(6,:)  - raw(14,:); % 6-14 =  C4-T8
        EEG(12,:) = raw(15,:) - raw(7,:);  %15-7  =  P7-P3
        EEG(13,:) = raw(7,:)  - raw(19,:); % 7-19 =  P3-Pz
        EEG(14,:) = raw(19,:) - raw(8,:);  %19-8  =  Pz-P4
        EEG(15,:) = raw(8,:)  - raw(16,:); % 8-16 =  P4-P8
        EEG(16,:) = raw(15,:) - raw(9,:);  %15-9  =  P7-O1
        EEG(17,:) = raw(9,:)  - raw(10,:); % 9-10 =  O1-O2
        EEG(18,:) = raw(10,:) - raw(16,:); %10-16 =  O2-P8
        yLabels(1:19) = {'','F7-Fp1','Fp1-Fp2','Fp2-F8','F7-F3','F3-Fz',...
                            'Fz-F4','F4-F8','T7-C3','C3-Cz','Cz-C4',...
                            'C4-T8','P7-P3','P3-Pz','Pz-P4','P4-P8',...
                            'P7-O1','O1-O2','O2-P8'};
        fa.YTickLabel = flip(yLabels);
    end

% ACNS TB18.2 transverse bipolar, variant 2, 18 channels + EKG
    function TB182
        EEG(1,:)  = raw(1,:)  - raw(2,:);  % 1-2  = Fp1-Fp2
        EEG(2,:)  = raw(11,:) - raw(3,:);  %11-3  =  F7-F3
        EEG(3,:)  = raw(3,:)  - raw(17,:); % 3-17 =  F3-Fz
        EEG(4,:)  = raw(17,:) - raw(4,:);  %17-4  =  Fz-F4
        EEG(5,:)  = raw(4,:)  - raw(12,:); % 4-12 =  F4-F8
        EEG(6,:)  = raw(23,:) - raw(13,:); %23-13 =  A1-T7
        EEG(7,:)  = raw(13,:) - raw(5,:);  % 13-5 =  T7-C3
        EEG(8,:)  = raw(5,:)  - raw(18,:); % 5-18 =  C3-Cz
        EEG(9,:)  = raw(18,:) - raw(6,:);  %18-6  =  Cz-C4
        EEG(10,:) = raw(6,:)  - raw(14,:); % 6-14 =  C4-T8
        EEG(11,:) = raw(14,:) - raw(24,:); %14-24 =  T8-A2
        EEG(12,:) = raw(15,:) - raw(7,:);  %15-7  =  P7-P3
        EEG(13,:) = raw(7,:)  - raw(19,:); % 7-19 =  P3-Pz
        EEG(14,:) = raw(19,:) - raw(8,:);  %19-8  =  Pz-P4
        EEG(15,:) = raw(8,:)  - raw(16,:); % 8-16 =  P4-P8
        EEG(16,:) = raw(9,:)  - raw(10,:); % 9-10 =  O1-O2
        EEG(17,:) = raw(17,:) - raw(18,:); %17-18 =  Fz-Cz
        EEG(18,:) = raw(18,:) - raw(19,:); %18-19 =  Cz-Pz
        yLabels(1:19) = {'','Fp1-Fp2','F7-F3','F3-Fz','Fz-F4','F4-F8',...
                            'A1-T7','T7-C3','C3-Cz','Cz-C4','C4-T8',...
                            'T8-A2','P7-P3','P3-Pz','Pz-P4','P4-P8',...
                            'O1-O2','Fz-Cz','Cz-Pz'};
        fa.YTickLabel = flip(yLabels);
    end

% ACNS R18.1 referential, variant 1, 18 channels + EKG
    function R181
        EEG(1,:)  = raw(11,:) - raw(23,:); %11-23 =  F7-A1
        EEG(2,:)  = raw(13,:) - raw(23,:); %13-23 =  T7-A1
        EEG(3,:)  = raw(15,:) - raw(23,:); %15-23 =  P7-A1
        EEG(4,:)  = raw(1,:)  - raw(23,:); % 1-23 = Fp1-A1
        EEG(5,:)  = raw(3,:)  - raw(23,:); % 3-23 =  F3-A1
        EEG(6,:)  = raw(5,:)  - raw(23,:); % 5-23 =  C3-A1
        EEG(7,:)  = raw(7,:)  - raw(23,:); % 7-23 =  P3-A1
        EEG(8,:)  = raw(9,:)  - raw(23,:); % 9-23 =  O1-A1
        EEG(9,:)  = raw(17,:) - raw(23,:); %17-23 =  Fz-A1
        EEG(10,:) = raw(19,:) - raw(24,:); %19-24 =  Pz-A2
        EEG(11,:) = raw(2,:)  - raw(24,:); % 2-24 = Fp2-A2
        EEG(12,:) = raw(4,:)  - raw(24,:); % 4-24 =  F4-A2
        EEG(13,:) = raw(6,:)  - raw(24,:); % 6-24 =  C4-A2
        EEG(14,:) = raw(8,:)  - raw(24,:); % 8-24 =  P4-A2
        EEG(15,:) = raw(10,:) - raw(24,:); %10-24 =  O2-A2
        EEG(16,:) = raw(12,:) - raw(24,:); %12-24 =  F8-A2
        EEG(17,:) = raw(14,:) - raw(24,:); %14-24 =  T8-A2
        EEG(18,:) = raw(16,:) - raw(24,:); %16-24 =  P8-A2
        yLabels(1:19) = {'','F7-A1','T7-A1','P7-A1','Fp1-A1','F3-A1',...
                            'C3-A1','P3-A1','O1-A1','Fz-A1','Pz-A2',...
                            'Fp2-A2','F4-A2','C4-A2','P4-A2','O2-A2',...
                            'F8-A2','T8-A2','P8-A2'};
        fa.YTickLabel = flip(yLabels);
    end

% ACNS R18.2 referential, variant 2, 18 channels + EKG
    function R182
        EEG(1,:)  = raw(17,:) - raw(23,:); %17-23 =  Fz-A1
        EEG(2,:)  = raw(19,:) - raw(23,:); %19-23 =  Pz-A1
        EEG(3,:)  = raw(1,:)  - raw(23,:); % 1-23 = Fp1-A1
        EEG(4,:)  = raw(2,:)  - raw(24,:); % 2-24 = Fp2-A2
        EEG(5,:)  = raw(3,:)  - raw(23,:); % 3-23 =  F3-A1       
        EEG(6,:)  = raw(4,:)  - raw(24,:); % 4-24 =  F4-A2       
        EEG(7,:)  = raw(5,:)  - raw(23,:); % 5-23 =  C3-A1       
        EEG(8,:)  = raw(6,:)  - raw(24,:); % 6-24 =  C4-A2      
        EEG(9,:)  = raw(7,:)  - raw(23,:); % 7-23 =  P3-A1       
        EEG(10,:) = raw(8,:)  - raw(24,:); % 8-24 =  P4-A2
        EEG(11,:) = raw(9,:)  - raw(23,:); % 9-23 =  O1-A1        
        EEG(12,:) = raw(10,:) - raw(24,:); %10-24 =  O2-A2        
        EEG(13,:) = raw(11,:) - raw(23,:); %11-23 =  F7-A1
        EEG(14,:) = raw(12,:) - raw(24,:); %12-24 =  F8-A2
        EEG(15,:) = raw(13,:) - raw(23,:); %13-23 =  T7-A1
        EEG(16,:) = raw(14,:) - raw(24,:); %14-24 =  T8-A2
        EEG(17,:) = raw(15,:) - raw(23,:); %15-23 =  P7-A1
        EEG(18,:) = raw(16,:) - raw(24,:); %16-24 =  P8-A2
        yLabels(1:19) = {'','Fz-A1','Pz-A1','Fp1-A1','Fp2-A2','F3-A1',...
                            'F4-A2','C3-A1','C4-A2','P3-A1','P4-A2',...
                            'O1-A1','O2-A2','F7-A1','F8-A2','T7-A1',...
                            'T8-A2','P7-A1','P8-A2'};
        fa.YTickLabel = flip(yLabels);
    end

% ACNS R18.3 referential, variant 3, 18 channels + EKG
    function R183
        EEG(1,:)  = raw(11,:) - raw(23,:); %11-23 =  F7-A1
        EEG(2,:)  = raw(12,:) - raw(24,:); %12-24 =  F8-A2        
        EEG(3,:)  = raw(13,:) - raw(23,:); %13-23 =  T7-A1
        EEG(4,:)  = raw(14,:) - raw(24,:); %14-24 =  T8-A2
        EEG(5,:)  = raw(15,:) - raw(23,:); %15-23 =  P7-A1
        EEG(6,:)  = raw(16,:) - raw(24,:); %16-24 =  P8-A2
        EEG(7,:)  = raw(1,:)  - raw(23,:); % 1-23 = Fp1-A1
        EEG(8,:)  = raw(2,:)  - raw(24,:); % 2-24 = Fp2-A2
        EEG(9,:)  = raw(3,:)  - raw(23,:); % 3-23 =  F3-A1
        EEG(10,:) = raw(4,:)  - raw(24,:); % 4-24 =  F4-A2
        EEG(11,:) = raw(5,:)  - raw(23,:); % 5-23 =  C3-A1
        EEG(12,:) = raw(6,:)  - raw(24,:); % 6-24 =  C4-A2
        EEG(13,:) = raw(7,:)  - raw(23,:); % 7-23 =  P3-A1
        EEG(14,:) = raw(8,:)  - raw(24,:); % 8-24 =  P4-A2
        EEG(15,:) = raw(9,:)  - raw(23,:); % 9-23 =  O1-A1
        EEG(16,:) = raw(10,:) - raw(24,:); %10-24 =  O2-A2
        EEG(17,:) = raw(17,:) - raw(23,:); %17-23 =  Fz-A1
        EEG(18,:) = raw(19,:) - raw(24,:); %19-24 =  Pz-A2
        yLabels(1:19) = {'','F7-A1','F8-A2','T7-A1','T8-A2','P7-A1',...
                            'P8-A2','Fp1-A1','Fp2-A2','F3-A1','F4-A2',...
                            'C3-A1','C4-A2','P3-A1','P4-A2','O1-A1',...
                            'O2-A2','Fz-A1','Pz-A2'};
        fa.YTickLabel = flip(yLabels);
    end

% NON-ACNS RCz referential, average is Cz electrode, 18 channels + EKG
    function RCz
        EEG(1,:)  = raw(11,:) - raw(18,:); %11-18 =  F7-Cz
        EEG(2,:)  = raw(13,:) - raw(18,:); %13-18 =  T7-Cz
        EEG(3,:)  = raw(15,:) - raw(18,:); %15-18 =  P7-Cz
        EEG(4,:)  = raw(1,:)  - raw(18,:); % 1-18 = Fp1-Cz
        EEG(5,:)  = raw(3,:)  - raw(18,:); % 3-18 =  F3-Cz
        EEG(6,:)  = raw(5,:)  - raw(18,:); % 5-18 =  C3-Cz
        EEG(7,:)  = raw(7,:)  - raw(18,:); % 7-18 =  P3-Cz
        EEG(8,:)  = raw(9,:)  - raw(18,:); % 9-18 =  O1-Cz
        EEG(9,:)  = raw(17,:) - raw(18,:); %17-18 =  Fz-Cz
        EEG(10,:) = raw(19,:) - raw(18,:); %19-18 =  Pz-Cz
        EEG(11,:) = raw(2,:)  - raw(18,:); % 2-18 = Fp2-Cz
        EEG(12,:) = raw(4,:)  - raw(18,:); % 4-18 =  F4-Cz
        EEG(13,:) = raw(6,:)  - raw(18,:); % 6-18 =  C4-Cz
        EEG(14,:) = raw(8,:)  - raw(18,:); % 8-18 =  P4-Cz
        EEG(15,:) = raw(10,:) - raw(18,:); %10-18 =  O2-Cz
        EEG(16,:) = raw(12,:) - raw(18,:); %12-18 =  F8-Cz
        EEG(17,:) = raw(14,:) - raw(18,:); %14-18 =  T8-Cz
        EEG(18,:) = raw(16,:) - raw(18,:); %16-18 =  P8-Cz
        yLabels(1:19) = {'','F7-Cz','T7-Cz','P7-Cz','Fp1-Cz','F3-Cz',...
                            'C3-Cz','P3-Cz','O1-Cz','Fz-Cz','Pz-Cz',...
                            'Fp2-Cz','F4-Cz','C4-Cz','P4-Cz','O2-Cz',...
                            'F8-Cz','T8-Cz','P8-Cz'};
        fa.YTickLabel = flip(yLabels);
    end

% NON-ACNS RAvg referential, all-electrode average, 18 channels + EKG
    function RAvg
        EEGavg = zeros(1,maxX);
        EEGavg =(raw(1,:) + raw(2,:) + raw(5,:)  + raw(6,:)  + raw(7,:) ...
               + raw(8,:) + raw(9,:) + raw(10,:) + raw(11,:) + raw(12,:)...
               + raw(13,:)+ raw(14,:)+ raw(15,:) + raw(16,:) + raw(17,:)...
               + raw(18,:)+ raw(19,:))/17; %exclude F3 and F4
        EEG(1,:)  = raw(11,:) - EEGavg; %11-Avg =  F7-Avg
        EEG(2,:)  = raw(13,:) - EEGavg; %13-Avg =  T7-Avg
        EEG(3,:)  = raw(15,:) - EEGavg; %15-Avg =  P7-Avg
        EEG(4,:)  = raw(1,:)  - EEGavg; % 1-Avg = Fp1-Avg
        EEG(5,:)  = raw(3,:)  - EEGavg; % 3-Avg =  F3-Avg
        EEG(6,:)  = raw(5,:)  - EEGavg; % 5-Avg =  C3-Avg
        EEG(7,:)  = raw(7,:)  - EEGavg; % 7-Avg =  P3-Avg
        EEG(8,:)  = raw(9,:)  - EEGavg; % 9-Avg =  O1-Avg
        EEG(9,:)  = raw(17,:) - EEGavg; %17-Avg =  Fz-Avg
        EEG(10,:) = raw(19,:) - EEGavg; %19-Avg =  Pz-Avg
        EEG(11,:) = raw(2,:)  - EEGavg; % 2-Avg = Fp2-Avg
        EEG(12,:) = raw(4,:)  - EEGavg; % 4-Avg =  F4-Avg
        EEG(13,:) = raw(6,:)  - EEGavg; % 6-Avg =  C4-Avg
        EEG(14,:) = raw(8,:)  - EEGavg; % 8-Avg =  P4-Avg
        EEG(15,:) = raw(10,:) - EEGavg; %10-Avg =  O2-Avg
        EEG(16,:) = raw(12,:) - EEGavg; %12-Avg =  F8-Avg
        EEG(17,:) = raw(14,:) - EEGavg; %14-Avg =  T8-Avg
        EEG(18,:) = raw(16,:) - EEGavg; %16-Avg =  P8-Avg
        yLabels(1:19)={'','F7-Avg','T7-Avg','P7-Avg','Fp1-Avg','F3-Avg',...
                           'C3-Avg','P3-Avg','O1-Avg','Fz-Avg','Pz-Avg',...
                          'Fp2-Avg','F4-Avg','C4-Avg','P4-Avg','O2-Avg',...
                            'F8-Avg','T8-Avg','P8-Avg'};
        fa.YTickLabel = flip(yLabels);
    end

%% Filters Data
% EEG1100 says: HPF tau 0.3s, LPF 120 Hz
% EEG1200 says: High-pass 0.08Hz (tau = 2s), low-pass 60Hz (-18 dB/oct)
% JE-921A says: HPF 0.08Hz (tau = 2s), LPF 300Hz (-18 dB/oct)
% Polysmith uses: LPF Butterworth (BW = 15Hz), HPF -3 dB @ 0.5308 Hz
%                 Notch IIR -130 dB @ 60 Hz
% Maas' data from EEG-1100C / JE-921A with CALibration pulse +50 uV

    function filterEEG
        % FIR Butterworth LPF @ 70 Hz
        [LPFb,LPFa] = maxflat(10,2, 70 / (sRate/2));
        % IIR Butterworth HPF @ 1.6 Hz
        [HPFb,HPFa] = butter(2,1.6 / (sRate/2),'high');
        % IIR Notch @ 60 Hz (Q factor = 50)
        [NOTCHb,NOTCHa] = iirnotch(60/(sRate/2),(60/(sRate/2))/50);
        
        % Try: filter it all straight up, not per-screen
        % Note, if using filter instead of filtfilt,
        % any symmetric filter of length N has a delay of (N-1)/2 samples
        disp('Applying low, high, and notch filters...');
        for i=1:nChannels
            EEG(i,:) = filtfilt(LPFb,LPFa,EEG(i,:));
            EEG(i,:) = filtfilt(HPFb,HPFa,EEG(i,:));
            EEG(i,:) = filtfilt(NOTCHb,NOTCHa,EEG(i,:));
        end
        clear i;
        disp('EEG displayed. Use left/right or pageup/pagedown to scroll.');
        disp('Use up/down to adjust sensitivity.');
        disp('Use the Analyze and Windows menus for qEEG features.');
    end

%% Draw (or update) EEG
    function drawEEG
        figure(fEEG)
        cla(fa)
        fa.XLim = [xOffset xOffset+nSamples];
        hold on
        for i=1:nChannels
            plot(xOffset:xOffset+nSamples, ...
                (ySens/PPmm)*EEG(i,xOffset:xOffset+nSamples)-yOffset(i+1));
        end
        %TODO: Scalebar
        %plot([15;15],[-120;-24],'-k', ...
        %     [15;115],[-120;-120],'-k','LineWidth',2)
        clear i;
        hold off
        
        % Also update any other open windows
        if strcmp(fSTFTMontage.Visible,'on')
            figure(fSTFTMontage)
            %fSTFTa.YTickLabel = flip(yLabels);
            for i=1:nChannels
                % Position is [x y width height]
                ax = axes('Position',[0 1-(i/nChannels) 1 1/nChannels]);
                % Data, Window, Overlap, Frequencies, sRate
                [s,f,t] = spectrogram(EEG(i,xOffset:xOffset+nSamples),...
                    128,100,linspace(0,20,100),sRate);
                imagesc(t,f,abs(s));
                set(ax,'YDir','normal');
            end
            clear i;
            hold off
        end
    end

%% Deal with keyboard input on main EEG window
    function controlEEG(~, fData)
        % fData <-- use this to get console output on what key was pressed
        switch fData.Key
            case 'home'
                xOffset = 1;
            case 'end'
                xOffset = maxX - nSamples;
            case 'leftarrow' % back one second
                if xOffset > sRate %prevent overflow
                    xOffset = xOffset - sRate;
                else
                    xOffset = 1;
                end
            case 'rightarrow' % forward one second
                if xOffset+nSamples+sRate < maxX
                    xOffset = xOffset + sRate;
                else
                    xOffset = maxX - nSamples;
                end
            case 'pageup' % back xSens seconds
                if xOffset > nSamples
                    xOffset = xOffset - nSamples;
                else
                    xOffset = 1;
                end
            case 'pagedown' % forward xSens seconds
                if xOffset+(nSamples*2) < maxX
                    xOffset = xOffset + nSamples;
                else
                    xOffset = maxX - nSamples;
                end
            case 'uparrow' % make more sensitive
                ySens = ySens + 1;
            case 'downarrow' % make less sensitive
                if ySens > 1
                    ySens = ySens - 1;
                end
            otherwise
                return;
        end
        drawEEG
    end

%% GUI Callback Functions
% File

% Open file and display EEG
function GOpen(~,~)
% Open an EDF using BIOSIG v3.1.0 library which must be installed
[file,path] = uigetfile('*.edf','Select an EDF file...');
try
    % FYI No difference between double and single, so use single.
    % UCAL gives uncalibrated, we want it calibrated (data in EDF header)
    [raw,header]=sload(strcat(path,filesep,file),'OUTPUT','single');
catch me
    error('BIOSIG is not installed, or not in the MATLAB path.');
end
raw = raw'; % Columns are timepoints. Rows are channels.

try    
    sRate = header.SampleRate;
    maxX = header.NRec * sRate * header.Dur;
    EEG = zeros(18,maxX);
    tStart = header.T0; %already correct; EDF doesn't use tzmin correction
    nSamples = sRate * xSens;
    filename = header.FILE.Name;
    
    % Make table of channel data for future use
    % Label | Show | Filter | Gain | Min | Max | Mean | Std
    ChannelData = cell(length(header.Label(:,1)),8);
    ChannelData(:,1) = header.Label(:,1);
    for i=1:length(header.Label(:,1))
        if any(strcmp(ChannelData{i,1}, ...
            {'Fp1','Fp2','F3','F4','C3','C4','P3','P4','O1','O2','F7',...
             'F8','T7','T8','P7','P8','Fz','Cz','Pz','EKG','EKG1','EKG2'}))
            ChannelData{i,2} = true; % show standard EEG channels
            ChannelData{i,3} = true; % filter standard EEG channels
        else
            ChannelData{i,2} = false; % hide other channels
            ChannelData{i,3} = false; % don't filter other channels
        end
        ChannelData{i,4} = 1;
        ChannelData{i,5} = min(raw(i,:)); %provide stats on all channels
        ChannelData{i,6} = max(raw(i,:));
        ChannelData{i,7} = mean(raw(i,:));
        ChannelData{i,8} = std(raw(i,:));
    end
    disp('Data successfully read from file.');
catch me
    error('Unable to read file. Is this an EDF file?');
end
fa.Visible = 'on';
mOpen.Enable = 'off';
mClose.Enable = 'on';
mOptions.Enable = 'on';
mAnalyze.Enable = 'on';
mWindows.Enable = 'on';
channelEEG;LB181;filterEEG;drawEEG;
end

% TODO: Close
    function GClose(fControl, fData)
        disp('Not yet implemented. Just close the EEG window for now.');
    end
% TODO: Save Picture
    function GSavePic(fControl, fData)
        disp('Not yet implemented. Just print screen and use MSPaint.');
    end
% TODO: Save Report
    function GSaveRep(fControl, fData)
        disp('Not yet implemented.');
    end

%% Options
%% Channel
% OLD channel: T3 T4 T5 T6
% NEW channel: T7 T8 P7 P8
% PSG: PG1 is EOG(L), PG2 is EOG(R), T1-T2 is CHIN, GND-X3 is EKG
% X1=leg(tone?), X2=snore, X5=airflow, X6=chest (noise?), X7=abdomen (EKG?)
% In Maas first 21, EKG usually channel 31 but rarely in X1-X4 or 32
    function GChannel(~,~)
        fChannel = figure;
        fChannel.Name = 'Channel Setup';
        fChannel.NumberTitle = 'off';
        fChannel.MenuBar = 'none'; %use 'none' to hide default MATLAB menu/toolbar
        fChannel.ToolBar = 'none';
        fChannel.Units = 'normalized';
        fChannel.OuterPosition = [0 0 1 1];
        ChannelTable = uitable(fChannel);
        ChannelTable.Data = ChannelData;
        ChannelTable.ColumnName = {'Channel Name','Show?','Filter?',...
            'Gain','Min','Max','Mean','Std'};
        ChannelTable.Units = 'normalized';
        ChannelTable.Position = [0.05 0.05 0.90 0.90];
        ChannelTable.Position(3:4) = ChannelTable.Extent(3:4);
        ChannelTable.ColumnEditable = ...
          [false true true true false false false false];
        ChannelTable.DeleteFcn = @channelEEG;
    end

    function channelEEG(hObj,~)
        if nargin>0
            ChannelData = hObj.Data; %Update with new values
        end
        nChannels = 18; %skip the 18-channel EEG montage
        for i=1:length(ChannelData(:,1))
            if any(strcmp(ChannelData{i,1}, ... %skip montage channels
              {'Fp1','Fp2','F3','F4','C3','C4','P3','P4','O1','O2','F7',...
               'F8','T7','T8','P7','P8','Fz','Cz','Pz'}))
            else % for non-montage channels,
                if ChannelData{i,2} == true % if to be shown,
                    nChannels = nChannels + 1;
                    EEG(nChannels,:) = raw(i,:); % put it on!
                    yLabels{nChannels+1} = ChannelData{i,1};
                    yLabels{nChannels+2} = '';
                end
            end
        end
        clear i;
        yOffset = linspace(-1e3,1e3,nChannels+2); %Extra are axes buffers
        fa.YLim = [yOffset(1) yOffset(length(yOffset))];
        fa.YTick = yOffset;
        fa.YTickLabel = flip(yLabels(1:nChannels+2));
        drawEEG;
    end

%% Montage
    function GMontage(fControl,~)
        % Unselect previous montage
        switch montage
            case 'LB18.1'
                mLB181.Checked = 'off';
                mLB181.Enable = 'on';
            case 'LB18.2'
                mLB182.Checked = 'off';
                mLB182.Enable = 'on';
            case 'LB18.3'
                mLB183.Checked = 'off';
                mLB183.Enable = 'on';
            case 'TB18.1'
                mTB181.Checked = 'off';
                mTB181.Enable = 'on';
            case 'TB18.2'
                mTB182.Checked = 'off';
                mTB182.Enable = 'on';
            case 'R18.1'
                mR181.Checked = 'off';
                mR181.Enable = 'on';
            case 'R18.2'
                mR182.Checked = 'off';
                mR182.Enable = 'on';
            case 'R18.3'
                mR183.Checked = 'off';
                mR183.Enable = 'on';
            case 'Cz Reference'
                mRCz.Checked = 'off';
                mRCz.Enable = 'on';
            case 'Avg Reference'
                mRAvg.Checked = 'off';
                mRAvg.Enable = 'on';
            otherwise
                disp('Warning: Could not determine old montage.');
        end
        
        % Select new montage and apply it
        % Note that new montages require refiltering and redrawing.
        switch fControl.Label
            case 'LB18.1'
                mLB181.Checked = 'on';
                mLB181.Enable = 'off';
                LB181;filterEEG;drawEEG;
            case 'LB18.2'
                mLB182.Checked = 'on';
                mLB182.Enable = 'off';
                LB182;filterEEG;drawEEG;
            case 'LB18.3'
                mLB183.Checked = 'on';
                mLB183.Enable = 'off';
                LB183;filterEEG;drawEEG;
            case 'TB18.1'
                mTB181.Checked = 'on';
                mTB181.Enable = 'off';
                TB181;filterEEG;drawEEG;
            case 'TB18.2'
                mTB182.Checked = 'on';
                mTB182.Enable = 'off';
                TB182;filterEEG;drawEEG;
            case 'R18.1'
                mR181.Checked = 'on';
                mR181.Enable = 'off';
                R181;filterEEG;drawEEG;
            case 'R18.2'
                mR182.Checked = 'on';
                mR182.Enable = 'off';
                R182;filterEEG;drawEEG;
            case 'R18.3'
                mR183.Checked = 'on';
                mR183.Enable = 'off';
                R183;filterEEG;drawEEG;
            case 'Cz Reference'
                mRCz.Checked = 'on';
                mRCz.Enable = 'off';
                RCz;filterEEG;drawEEG;
            case 'Avg Reference'
                mRAvg.Checked = 'on';
                mRAvg.Enable = 'off';
                RAvg;filterEEG;drawEEG;
            otherwise
                disp('Warning: Could not determine new montage.');
        end
        montage = fControl.Label; % current montage state
    end

%% Filter
    function GFilter(fControl, fData)
        clc
        fControl
        fData
    end

%% Analyze
% Power by Band
    function GBandpower(~,~)
        disp('Running bandpower calculations...');
        % Global scope, break into bands and plot against time
        fBandpower = figure;
        fBandpower.Name = 'Power by EEG Frequency Band';
        fBandpower.NumberTitle = 'off';
        fBandpower.MenuBar = 'none'; %use 'none' to hide default MATLAB menu/toolbar
        fBandpower.ToolBar = 'none';
        fBandpower.Units = 'normalized';
        fBandpower.OuterPosition = [0 0 1 1];
        % Get bandpowers per channel over the EEG montage
        total = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        delta = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        theta = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        alpha = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
         beta = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));

        j=0;
        for i=1:sRate*60:maxX-(sRate*60) %60 = per-minute bandpower
            % NOTE: EEGLAB replaces the built-in MATLAB bandpower function.
            % This is made to use the MATLAB function, not EEGLAB's.
            j = j+1;
            total(:,j) = bandpower(EEG(:,i:i+(sRate*60))',sRate,[1 20]);
            delta(:,j) = bandpower(EEG(:,i:i+(sRate*60))',sRate,[1 4]);
            theta(:,j) = bandpower(EEG(:,i:i+(sRate*60))',sRate,[4 8]);
            alpha(:,j) = bandpower(EEG(:,i:i+(sRate*60))',sRate,[8 13]);
             beta(:,j) = bandpower(EEG(:,i:i+(sRate*60))',sRate,[13 20]);
        end
        clear i j;

        % Add extra 7 "metadata" channels:
        % NOTE: This assumes LB18.1 montage!
        %R anter (11=Fp2-F4,12=F4-C4,13=C4-P4,15=Fp2-F8,16=F8-F8,17=T8-P8),
        total(nChannels+1,:) = (total(11,:) + total(12,:) + total(13,:)...
            + total(15,:) + total(16,:) + total(17,:))/6;
        delta(nChannels+1,:) = (delta(11,:) + delta(12,:) + delta(13,:)...
            + delta(15,:) + delta(16,:) + delta(17,:))/6;
        theta(nChannels+1,:) = (theta(11,:) + theta(12,:) + theta(13,:)...
            + theta(15,:) + theta(16,:) + theta(17,:))/6;
        alpha(nChannels+1,:) = (alpha(11,:) + alpha(12,:) + alpha(13,:)...
            + alpha(15,:) + alpha(16,:) + alpha(17,:))/6;
         beta(nChannels+1,:) = (beta(11,:) + beta(12,:) + beta(13,:)...
            + beta(15,:) + beta(16,:) + beta(17,:))/6;
        %L anterior (1=Fp1-F7,2=F7-T7,3=T7-P7,5=Fp1-F3,6=F3-C3,7=C3-P3),
        total(nChannels+2,:) = (total(1,:) + total(2,:) + total(3,:)...
            + total(5,:) + total(6,:) + total(7,:))/6;
        delta(nChannels+2,:) = (delta(1,:) + delta(2,:) + delta(3,:)...
            + delta(5,:) + delta(6,:) + delta(7,:))/6;
        theta(nChannels+2,:) = (theta(1,:) + theta(2,:) + theta(3,:)...
            + theta(5,:) + theta(6,:) + theta(7,:))/6;
        alpha(nChannels+2,:) = (alpha(1,:) + alpha(2,:) + alpha(3,:)...
            + alpha(5,:) + alpha(6,:) + alpha(7,:))/6;
         beta(nChannels+2,:) = (beta(1,:) + beta(2,:) + beta(3,:)...
            + beta(5,:) + beta(6,:) + beta(7,:))/6;
        %R posterior (14=P4-O2,18=P8-O2),
        total(nChannels+3,:) = (total(14,:)+total(18,:))/2;
        delta(nChannels+3,:) = (delta(14,:)+delta(18,:))/2;
        theta(nChannels+3,:) = (theta(14,:)+theta(18,:))/2;
        alpha(nChannels+3,:) = (alpha(14,:)+alpha(18,:))/2;
         beta(nChannels+3,:) = ( beta(14,:)+ beta(18,:))/2;
        %L posterior ( 4=P7-O1, 8=P3-O1),
        total(nChannels+4,:) = (total(4,:)+total(8,:))/2;
        delta(nChannels+4,:) = (delta(4,:)+delta(8,:))/2;
        theta(nChannels+4,:) = (theta(4,:)+theta(8,:))/2;
        alpha(nChannels+4,:) = (alpha(4,:)+alpha(8,:))/2;
         beta(nChannels+4,:) = ( beta(4,:)+ beta(8,:))/2;
        %R hemisphere (11-18),
        total(nChannels+5,:) = (total(11,:) + total(12,:) + total(13,:)...
            + total(15,:) + total(16,:) + total(17,:) + total(14,:)...
            + total(18,:))/8;
        delta(nChannels+5,:) = (delta(11,:) + delta(12,:) + delta(13,:)...
            + delta(15,:) + delta(16,:) + delta(17,:) + delta(14,:)...
            + delta(18,:))/8;
        theta(nChannels+5,:) = (theta(11,:) + theta(12,:) + theta(13,:)...
            + theta(15,:) + theta(16,:) + theta(17,:) + theta(14,:)...
            + theta(18,:))/8;
        alpha(nChannels+5,:) = (alpha(11,:) + alpha(12,:) + alpha(13,:)...
            + alpha(15,:) + alpha(16,:) + alpha(17,:) + alpha(14,:)...
            + alpha(18,:))/8;
         beta(nChannels+5,:) = (beta(11,:) + beta(12,:) + beta(13,:)...
            + beta(15,:) + beta(16,:) + beta(17,:) + beta(14,:)...
            + beta(18,:))/8;
        %L hemisphere ( 1-8),
        total(nChannels+6,:) = (total(1,:) + total(2,:) + total(3,:)...
            + total(5,:) + total(6,:) + total(7,:) + total(4,:)...
            + total(8,:))/8;
        delta(nChannels+6,:) = (delta(1,:) + delta(2,:) + delta(3,:)...
            + delta(5,:) + delta(6,:) + delta(7,:) + delta(4,:)...
            + delta(8,:))/8;
        theta(nChannels+6,:) = (theta(1,:) + theta(2,:) + theta(3,:)...
            + theta(5,:) + theta(6,:) + theta(7,:) + theta(4,:)...
            + theta(8,:))/8;
        alpha(nChannels+6,:) = (alpha(1,:) + alpha(2,:) + alpha(3,:)...
            + alpha(5,:) + alpha(6,:) + alpha(7,:) + alpha(4,:)...
            + alpha(8,:))/8;
         beta(nChannels+6,:) = (beta(1,:) + beta(2,:) + beta(3,:)...
            + beta(5,:) + beta(6,:) + beta(7,:) + beta(4,:)...
            + beta(8,:))/8;
        %Global (1-18)
        total(nChannels+7,:)=(total(nChannels+5,:)+total(nChannels+6,:))/2;
        delta(nChannels+7,:)=(delta(nChannels+5,:)+delta(nChannels+6,:))/2;
        theta(nChannels+7,:)=(theta(nChannels+5,:)+theta(nChannels+6,:))/2;
        alpha(nChannels+7,:)=(alpha(nChannels+5,:)+alpha(nChannels+6,:))/2;
         beta(nChannels+7,:)=(beta(nChannels+5,:)+beta(nChannels+6,:))/2;
        
        % Plots: Total, Delta, Theta, Alpha, Beta, A:D, (A+B):(D+T)
        % Power units are |uV|^2 / Hz
        popup = uicontrol(fBandpower,'Style', 'popup',...
           'String', {'Total','Raw Delta','Raw Theta','Raw Alpha',...
           'Raw Beta','% Delta','% Theta','% Alpha','% Beta',...
           'Alpha:Delta','(Alpha+Beta):(Delta+Theta)'},'Units','normalized',...
           'Position', [0.02 0.94 0.1 0.04],'Callback', @changePlot);
        export = uicontrol(fBandpower,'Style','pushbutton', ...
            'Callback',@exportBandpower,'String','Export');
        % Position is [left bottom width height]
        imagesc(0);
        ax = gca;
        ax.Title.String = 'Select a plot type on the left to begin...';
        
        function changePlot(source,~)
            switch(source.Value)
                case 1 %Total
                    imagesc(total);c = colorbar;
                    c.Label.String = 'Power ( |uV|^2 / Hz )';
                    ax.Title.String = 'Total EEG Power, 1-20 Hz, over time';
                case 2 %Raw Delta
                    imagesc(delta);c = colorbar;
                    c.Label.String = 'Power ( |uV|^2 / Hz )';
                    ax.Title.String = 'Total EEG Power, 1-4 Hz, over time';
                case 3 %Raw Theta
                    imagesc(theta);c = colorbar;
                    c.Label.String = 'Power ( |uV|^2 / Hz )';
                    ax.Title.String = 'Total EEG Power, 4-8 Hz, over time';
                case 4 %Raw Alpha
                    imagesc(alpha);c = colorbar;
                    c.Label.String = 'Power ( |uV|^2 / Hz )';
                    ax.Title.String = 'Total EEG Power, 8-13 Hz, over time';
                case 5 %Raw Beta
                    imagesc(beta);c = colorbar;
                    c.Label.String = 'Power ( |uV|^2 / Hz )';
                    ax.Title.String = 'Total EEG Power, 13-20 Hz, over time';
                case 6 % %Delta
                    imagesc(100*(delta./total));c = colorbar;
                    c.Label.String = 'Percent of total power';
                    ax.Title.String = '% of EEG Power in 1-4 Hz, over time';
                case 7 % %Theta
                    imagesc(100*(theta./total));c = colorbar;
                    c.Label.String = 'Percent of total power';
                    ax.Title.String = '% of EEG Power in 4-8 Hz, over time';
                case 8 % %Alpha
                    imagesc(100*(alpha./total));c = colorbar;
                    c.Label.String = 'Percent of total power';
                    ax.Title.String = '% of EEG Power in 8-13 Hz, over time';
                case 9 % %Beta
                    imagesc(100*(beta./total));c = colorbar;
                    c.Label.String = 'Percent of total power';
                    ax.Title.String = '% of EEG Power in 13-20 Hz, over time';
                case 10 %Alpha:Delta
                    imagesc(alpha./delta);c = colorbar;
                    c.Label.String = 'Unitless Ratio';
                    ax.Title.String = 'Alpha:Delta Ratio, over time';
                case 11 %(Alpha+Beta):(Delta+Theta)
                    imagesc((alpha+beta)./(delta+theta));c = colorbar;
                    c.Label.String = 'Unitless Ratio';
                    ax.Title.String = '(Alpha+Beta):(Delta+Theta) Ratio, over time';
            end
            ax.YTickMode = 'manual';
            ax.YTickLabelMode = 'manual';
            ax.YTick = 1:nChannels+7;
            ax.YTickLabel = yLabels(2:nChannels+1); %first&last are blanks
            ax.YTickLabel(nChannels+1:nChannels+7) = ...
                {'R anterior','L anterior','R posterior','L posterior',...
                'R hemisphere','L hemisphere','Global'};
            ax.XLabel.String = 'Time (minutes)';
        end
        
        % Export for Maas' project
        function exportBandpower(~,~)
            bp = total';
            bp = [bp delta'];
            bp = [bp theta'];
            bp = [bp alpha'];
            bp = [bp  beta'];
            temp = 100*(delta./total);
            bp = [bp temp'];
            temp = 100*(theta./total);
            bp = [bp temp'];
            temp = 100*(alpha./total);
            bp = [bp temp'];
            temp = 100*(beta./total);
            bp = [bp temp'];
            temp = alpha./delta;
            bp = [bp temp'];
            temp = (alpha+beta)./(delta+theta);
            bp = [bp temp'];
            %Construct header
            tDate = datestr(tStart,23);
            xlHeader = cell(3,2+size(bp,2));
            xlHeader(1,1:4) = {'Filename:',filename,'Date:',tDate};
            xlHeader(2,:) = {'Time','GCS',...
            'Total Bandpower Fp1-F7', 'Total Bandpower F7-T7',...
            'Total Bandpower T7-P7' , 'Total Bandpower P7-O1',...
            'Total Bandpower Fp1-F3', 'Total Bandpower F3-C3',...
            'Total Bandpower C3-P3' , 'Total Bandpower P3-O1',...
            'Total Bandpower Fz-Cz' , 'Total Bandpower Cz-Pz',...
            'Total Bandpower Fp2-F4', 'Total Bandpower F4-C4',...
            'Total Bandpower C4-P4' , 'Total Bandpower P4-O2',...
            'Total Bandpower Fp2-F8', 'Total Bandpower F8-T8',...
            'Total Bandpower T8-P8' , 'Total Bandpower P8-O2',...
            'Total Bandpower EKG'   , 'Total Bandpower R anterior',...
            'Total Bandpower L anterior','Total Bandpower R posterior',...
            'Total Bandpower L posterior','Total Bandpower R hemisphere',...
            'Total Bandpower L hemisphere','Total Bandpower Global',...
            'Raw Delta Power Fp1-F7', 'Raw Delta Power F7-T7',...
            'Raw Delta Power T7-P7' , 'Raw Delta Power P7-O1',...
            'Raw Delta Power Fp1-F3', 'Raw Delta Power F3-C3',...
            'Raw Delta Power C3-P3' , 'Raw Delta Power P3-O1',...
            'Raw Delta Power Fz-Cz' , 'Raw Delta Power Cz-Pz',...
            'Raw Delta Power Fp2-F4', 'Raw Delta Power F4-C4',...
            'Raw Delta Power C4-P4' , 'Raw Delta Power P4-O2',...
            'Raw Delta Power Fp2-F8', 'Raw Delta Power F8-T8',...
            'Raw Delta Power T8-P8' , 'Raw Delta Power P8-O2',...
            'Raw Delta Power EKG'   , 'Raw Delta Power R anterior',...
            'Raw Delta Power L anterior','Raw Delta Power R posterior',...
            'Raw Delta Power L posterior','Raw Delta Power R hemisphere',...
            'Raw Delta Power L hemisphere','Raw Delta Power Global',...           
            'Raw Theta Power Fp1-F7', 'Raw Theta Power F7-T7',...
            'Raw Theta Power T7-P7' , 'Raw Theta Power P7-O1',...
            'Raw Theta Power Fp1-F3', 'Raw Theta Power F3-C3',...
            'Raw Theta Power C3-P3' , 'Raw Theta Power P3-O1',...
            'Raw Theta Power Fz-Cz' , 'Raw Theta Power Cz-Pz',...
            'Raw Theta Power Fp2-F4', 'Raw Theta Power F4-C4',...
            'Raw Theta Power C4-P4' , 'Raw Theta Power P4-O2',...
            'Raw Theta Power Fp2-F8', 'Raw Theta Power F8-T8',...
            'Raw Theta Power T8-P8' , 'Raw Theta Power P8-O2',...
            'Raw Theta Power EKG'   , 'Raw Theta Power R anterior',...
            'Raw Theta Power L anterior','Raw Theta Power R posterior',...
            'Raw Theta Power L posterior','Raw Theta Power R hemisphere',...
            'Raw Theta Power L hemisphere','Raw Theta Power Global',...             
            'Raw Alpha Power Fp1-F7', 'Raw Alpha Power F7-T7',...
            'Raw Alpha Power T7-P7' , 'Raw Alpha Power P7-O1',...
            'Raw Alpha Power Fp1-F3', 'Raw Alpha Power F3-C3',...
            'Raw Alpha Power C3-P3' , 'Raw Alpha Power P3-O1',...
            'Raw Alpha Power Fz-Cz' , 'Raw Alpha Power Cz-Pz',...
            'Raw Alpha Power Fp2-F4', 'Raw Alpha Power F4-C4',...
            'Raw Alpha Power C4-P4' , 'Raw Alpha Power P4-O2',...
            'Raw Alpha Power Fp2-F8', 'Raw Alpha Power F8-T8',...
            'Raw Alpha Power T8-P8' , 'Raw Alpha Power P8-O2',...
            'Raw Alpha Power EKG'   , 'Raw Alpha Power R anterior',...
            'Raw Alpha Power L anterior','Raw Alpha Power R posterior',...
            'Raw Alpha Power L posterior','Raw Alpha Power R hemisphere',...
            'Raw Alpha Power L hemisphere','Raw Alpha Power Global',...  
            'Raw Beta Power Fp1-F7', 'Raw Beta Power F7-T7',...
            'Raw Beta Power T7-P7' , 'Raw Beta Power P7-O1',...
            'Raw Beta Power Fp1-F3', 'Raw Beta Power F3-C3',...
            'Raw Beta Power C3-P3' , 'Raw Beta Power P3-O1',...
            'Raw Beta Power Fz-Cz' , 'Raw Beta Power Cz-Pz',...
            'Raw Beta Power Fp2-F4', 'Raw Beta Power F4-C4',...
            'Raw Beta Power C4-P4' , 'Raw Beta Power P4-O2',...
            'Raw Beta Power Fp2-F8', 'Raw Beta Power F8-T8',...
            'Raw Beta Power T8-P8' , 'Raw Beta Power P8-O2',...
            'Raw Beta Power EKG'   , 'Raw Beta Power R anterior',...
            'Raw Beta Power L anterior','Raw Beta Power R posterior',...
            'Raw Beta Power L posterior','Raw Beta Power R hemisphere',...
            'Raw Beta Power L hemisphere','Raw Beta Power Global',...              
            '%Delta Power Fp1-F7', '%Delta Power F7-T7',...
            '%Delta Power T7-P7' , '%Delta Power P7-O1',...
            '%Delta Power Fp1-F3', '%Delta Power F3-C3',...
            '%Delta Power C3-P3' , '%Delta Power P3-O1',...
            '%Delta Power Fz-Cz' , '%Delta Power Cz-Pz',...
            '%Delta Power Fp2-F4', '%Delta Power F4-C4',...
            '%Delta Power C4-P4' , '%Delta Power P4-O2',...
            '%Delta Power Fp2-F8', '%Delta Power F8-T8',...
            '%Delta Power T8-P8' , '%Delta Power P8-O2',...
            '%Delta Power EKG'   , '%Delta Power R anterior',...
            '%Delta Power L anterior','%Delta Power R posterior',...
            '%Delta Power L posterior','%Delta Power R hemisphere',...
            '%Delta Power L hemisphere','%Delta Power Global',...              
            '%Theta Power Fp1-F7', '%Theta Power F7-T7',...
            '%Theta Power T7-P7' , '%Theta Power P7-O1',...
            '%Theta Power Fp1-F3', '%Theta Power F3-C3',...
            '%Theta Power C3-P3' , '%Theta Power P3-O1',...
            '%Theta Power Fz-Cz' , '%Theta Power Cz-Pz',...
            '%Theta Power Fp2-F4', '%Theta Power F4-C4',...
            '%Theta Power C4-P4' , '%Theta Power P4-O2',...
            '%Theta Power Fp2-F8', '%Theta Power F8-T8',...
            '%Theta Power T8-P8' , '%Theta Power P8-O2',...
            '%Theta Power EKG'   , '%Theta Power R anterior',...
            '%Theta Power L anterior','%Theta Power R posterior',...
            '%Theta Power L posterior','%Theta Power R hemisphere',...
            '%Theta Power L hemisphere','%Theta Power Global',...              
            '%Alpha Power Fp1-F7', '%Alpha Power F7-T7',...
            '%Alpha Power T7-P7' , '%Alpha Power P7-O1',...
            '%Alpha Power Fp1-F3', '%Alpha Power F3-C3',...
            '%Alpha Power C3-P3' , '%Alpha Power P3-O1',...
            '%Alpha Power Fz-Cz' , '%Alpha Power Cz-Pz',...
            '%Alpha Power Fp2-F4', '%Alpha Power F4-C4',...
            '%Alpha Power C4-P4' , '%Alpha Power P4-O2',...
            '%Alpha Power Fp2-F8', '%Alpha Power F8-T8',...
            '%Alpha Power T8-P8' , '%Alpha Power P8-O2',...
            '%Alpha Power EKG'   , '%Alpha Power R anterior',...
            '%Alpha Power L anterior','%Alpha Power R posterior',...
            '%Alpha Power L posterior','%Alpha Power R hemisphere',...
            '%Alpha Power L hemisphere','%Alpha Power Global',...              
            '%Beta Power Fp1-F7', '%Beta Power F7-T7',...
            '%Beta Power T7-P7' , '%Beta Power P7-O1',...
            '%Beta Power Fp1-F3', '%Beta Power F3-C3',...
            '%Beta Power C3-P3' , '%Beta Power P3-O1',...
            '%Beta Power Fz-Cz' , '%Beta Power Cz-Pz',...
            '%Beta Power Fp2-F4', '%Beta Power F4-C4',...
            '%Beta Power C4-P4' , '%Beta Power P4-O2',...
            '%Beta Power Fp2-F8', '%Beta Power F8-T8',...
            '%Beta Power T8-P8' , '%Beta Power P8-O2',...
            '%Beta Power EKG'   , '%Beta Power R anterior',...
            '%Beta Power L anterior','%Beta Power R posterior',...
            '%Beta Power L posterior','%Beta Power R hemisphere',...
            '%Beta Power L hemisphere','%Beta Power Global',...              
            'Alpha:Delta Fp1-F7', 'Alpha:Delta F7-T7',...
            'Alpha:Delta T7-P7' , 'Alpha:Delta P7-O1',...
            'Alpha:Delta Fp1-F3', 'Alpha:Delta F3-C3',...
            'Alpha:Delta C3-P3' , 'Alpha:Delta P3-O1',...
            'Alpha:Delta Fz-Cz' , 'Alpha:Delta Cz-Pz',...
            'Alpha:Delta Fp2-F4', 'Alpha:Delta F4-C4',...
            'Alpha:Delta C4-P4' , 'Alpha:Delta P4-O2',...
            'Alpha:Delta Fp2-F8', 'Alpha:Delta F8-T8',...
            'Alpha:Delta T8-P8' , 'Alpha:Delta P8-O2',...
            'Alpha:Delta EKG'   , 'Alpha:Delta R anterior',...
            'Alpha:Delta L anterior','Alpha:Delta R posterior',...
            'Alpha:Delta L posterior','Alpha:Delta R hemisphere',...
            'Alpha:Delta L hemisphere','Alpha:Delta Global',...              
            '(A+B):(D+T) Fp1-F7', '(A+B):(D+T) F7-T7',...
            '(A+B):(D+T) T7-P7' , '(A+B):(D+T) P7-O1',...
            '(A+B):(D+T) Fp1-F3', '(A+B):(D+T) F3-C3',...
            '(A+B):(D+T) C3-P3' , '(A+B):(D+T) P3-O1',...
            '(A+B):(D+T) Fz-Cz' , '(A+B):(D+T) Cz-Pz',...
            '(A+B):(D+T) Fp2-F4', '(A+B):(D+T) F4-C4',...
            '(A+B):(D+T) C4-P4' , '(A+B):(D+T) P4-O2',...
            '(A+B):(D+T) Fp2-F8', '(A+B):(D+T) F8-T8',...
            '(A+B):(D+T) T8-P8' , '(A+B):(D+T) P8-O2',...
            '(A+B):(D+T) EKG'   , '(A+B):(D+T) R anterior',...
            '(A+B):(D+T) L anterior','(A+B):(D+T) R posterior',...
            '(A+B):(D+T) L posterior','(A+B):(D+T) R hemisphere',...
            '(A+B):(D+T) L hemisphere','(A+B):(D+T) Global'};
            t = (datetime(tStart) + minutes(0:size(bp,1)-1))';
            t = cellstr(string(datestr(t,13)));
            xlswrite(strcat(filename,'.xlsx'),xlHeader,'Bandpower')
            xlswrite(strcat(filename,'.xlsx'),t,'Bandpower','A3')
            xlswrite(strcat(filename,'.xlsx'),bp,'Bandpower','C3')
            disp('An Excel file containing bandpower data was exported.');
        end
    end

% aEEG
    function GaEEG(~,~)
        disp('Running amplitude-integrated EEG calculations...');
        % 2 channel version runs on C3-P3 (Channel 7), C4-P4 (Ch 13)
        % 1-channel version runs on P3-P4 (7-8, not a default channel!)

        % Global scope, break into bands and plot against time
        faEEG = figure;
        faEEG.Name = 'Amplitude-Integrated EEG (aEEG)';
        faEEG.NumberTitle = 'off';
        faEEG.MenuBar = 'none'; %use 'none' to hide default MATLAB menu/toolbar
        faEEG.ToolBar = 'none';
        faEEG.Units = 'normalized';
        faEEG.OuterPosition = [0 0 1 1];

        % aEEG algorithm, see e.g. Zhang D "Calculation of compact
        % amplitude-integrated tracing and upper and lower margins using
        % raw EEG data", Health 5(5):885-891 (2013)
        
        % 1. Will not filter beyond standard EEG filtering
        % 2. Envelope detection: I'm using Hilbert instead of Butterworth
        aEEG = zeros(size(EEG));
        % I'm specifically over-riding channel 19 to be P3-P4 (7-8)
        aEEG(19,:) = raw(7,:) - raw(8,:);  %7-8  =  P3-P4
        [LPFb,LPFa] = maxflat(10,2, 70 / (sRate/2));
        [HPFb,HPFa] = butter(2,1.6 / (sRate/2),'high');
        [NOTCHb,NOTCHa] = iirnotch(60/(sRate/2),(60/(sRate/2))/50);
        aEEG(19,:) = filtfilt(LPFb,LPFa,aEEG(19,:));
        aEEG(19,:) = filtfilt(HPFb,HPFa,aEEG(19,:));
        aEEG(19,:) = filtfilt(NOTCHb,NOTCHa,aEEG(19,:));
        for i=1:18
            [aEEG(i,:),~] = envelope(abs(EEG(i,:)));
        end
        [aEEG(19,:),~] = envelope(abs(aEEG(19,:)));
        % 3. Note min and max aEEG for each minute
        aEEGmax = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        aEEGmin = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        aEEGdel = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        j=0;
        for i=1:sRate*60:maxX-(sRate*60) %60 = per-minute
            % NOTE: EEGLAB replaces the built-in MATLAB bandpower function.
            % This is made to use the MATLAB function, not EEGLAB's.
            j = j+1;
            aEEGmax(:,j) = max(aEEG(:,i:i+(sRate*60))'); % ' ?
            aEEGmin(:,j) = min(aEEG(:,i:i+(sRate*60))'); % ' ?
            aEEGdel(:,j) = aEEGmax(:,j) - aEEGmin(:,j);
        end
        clear i j;

        % Add extra 7 "metadata" channels:
        % NOTE: This assumes LB18.1 montage!
        %R anter (11=Fp2-F4,12=F4-C4,13=C4-P4,15=Fp2-F8,16=F8-F8,17=T8-P8),
        aEEGmax(nChannels+1,:) = (aEEGmax(11,:) + aEEGmax(12,:) + ...
            aEEGmax(13,:) + aEEGmax(15,:) + aEEGmax(16,:) + ...
            aEEGmax(17,:))/6;
        aEEGmin(nChannels+1,:) = (aEEGmin(11,:) + aEEGmin(12,:) + ...
            aEEGmin(13,:) + aEEGmin(15,:) + aEEGmin(16,:) + ...
            aEEGmin(17,:))/6;
        aEEGdel(nChannels+1,:) = (aEEGdel(11,:) + aEEGdel(12,:) + ...
            aEEGdel(13,:) + aEEGdel(15,:) + aEEGdel(16,:) + ...
            aEEGdel(17,:))/6;
        %L anterior (1=Fp1-F7,2=F7-T7,3=T7-P7,5=Fp1-F3,6=F3-C3,7=C3-P3),
        aEEGmax(nChannels+2,:) = (aEEGmax(1,:) + aEEGmax(2,:) + ...
            aEEGmax(3,:) + aEEGmax(5,:) + aEEGmax(6,:) + aEEGmax(7,:))/6;
        aEEGmin(nChannels+2,:) = (aEEGmin(1,:) + aEEGmin(2,:) + ...
            aEEGmin(3,:) + aEEGmin(5,:) + aEEGmin(6,:) + aEEGmin(7,:))/6;
        aEEGdel(nChannels+2,:) = (aEEGdel(1,:) + aEEGdel(2,:) + ...
            aEEGdel(3,:) + aEEGdel(5,:) + aEEGdel(6,:) + aEEGdel(7,:))/6;
        %R posterior (14=P4-O2,18=P8-O2),
        aEEGmax(nChannels+3,:) = (aEEGmax(14,:) + aEEGmax(18,:))/2;
        aEEGmin(nChannels+3,:) = (aEEGmin(14,:) + aEEGmin(18,:))/2;
        aEEGdel(nChannels+3,:) = (aEEGdel(14,:) + aEEGdel(18,:))/2;
        %L posterior ( 4=P7-O1, 8=P3-O1),
        aEEGmax(nChannels+4,:) = (aEEGmax(4,:)+aEEGmax(8,:))/2;
        aEEGmin(nChannels+4,:) = (aEEGmin(4,:)+aEEGmin(8,:))/2;
        aEEGdel(nChannels+4,:) = (aEEGdel(4,:)+aEEGdel(8,:))/2;
        %R hemisphere (11-18),
        aEEGmax(nChannels+5,:) = (aEEGmax(11,:) + aEEGmax(12,:) + ...
            aEEGmax(13,:) + aEEGmax(14,:) + aEEGmax(15,:) + ...
            aEEGmax(16,:) + aEEGmax(17,:) + aEEGmax(18,:))/8;
        aEEGmin(nChannels+5,:) = (aEEGmin(11,:) + aEEGmin(12,:) + ...
            aEEGmin(13,:) + aEEGmin(14,:) + aEEGmin(15,:) + ...
            aEEGmin(16,:) + aEEGmin(17,:) + aEEGmin(18,:))/8;
        aEEGdel(nChannels+5,:) = (aEEGdel(11,:) + aEEGdel(12,:) + ...
            aEEGdel(13,:) + aEEGdel(14,:) + aEEGdel(15,:) + ...
            aEEGdel(16,:) + aEEGdel(17,:) + aEEGdel(18,:))/8;
        %L hemisphere ( 1-8),
        aEEGmax(nChannels+6,:) = (aEEGmax(1,:) + aEEGmax(2,:) + ...
            aEEGmax(3,:) + aEEGmax(4,:) + aEEGmax(5,:) + aEEGmax(6,:) + ...
            aEEGmax(7,:) + aEEGmax(8,:))/8;
        aEEGmin(nChannels+6,:) = (aEEGmin(1,:) + aEEGmin(2,:) + ...
            aEEGmin(3,:) + aEEGmin(4,:) + aEEGmin(5,:) + aEEGmin(6,:) + ...
            aEEGmin(7,:) + aEEGmin(8,:))/8;
        aEEGdel(nChannels+6,:) = (aEEGdel(1,:) + aEEGdel(2,:) + ...
            aEEGdel(3,:) + aEEGdel(4,:) + aEEGdel(5,:) + aEEGdel(6,:) + ...
            aEEGdel(7,:) + aEEGdel(8,:))/8;
        %Global (1-18)
        aEEGmax(nChannels+7,:) = ...
            (aEEGmax(nChannels+5,:) + aEEGmax(nChannels+6,:))/2;
        aEEGmin(nChannels+7,:) = ...
            (aEEGmin(nChannels+5,:) + aEEGmin(nChannels+6,:))/2;
        aEEGdel(nChannels+7,:) = ...
            (aEEGdel(nChannels+5,:) + aEEGdel(nChannels+6,:))/2;
        
        % Plots: Total, Delta, Theta, Alpha, Beta, A:D, (A+B):(D+T)
        % Power units are |uV|^2 / Hz
        popup = uicontrol(faEEG,'Style', 'popup',...
           'String', {'Max','Min','Max-Min'},'Units','normalized',...
           'Position', [0.02 0.94 0.1 0.04],'Callback', @changePlot);
        export = uicontrol(faEEG,'Style','pushbutton', ...
            'Callback',@exportaEEG,'String','Export');
        % Position is [left bottom width height]
        imagesc(0);
        ax = gca;
        ax.Title.String = 'Select a plot type on the left to begin...';
        
        function changePlot(source,~)
            switch(source.Value)
                case 1 %Max
                    imagesc(aEEGmax);c = colorbar;
                    c.Label.String = 'Voltage |uV|';
                    ax.Title.String = 'aEEG Maximum Envelope, over time';
                case 2 %Min
                    imagesc(aEEGmin);c = colorbar;
                    c.Label.String = 'Voltage |uV|';
                    ax.Title.String = 'aEEG Minimum Envelope, over time';
                case 3 %Del
                    imagesc(aEEGdel);c = colorbar;
                    c.Label.String = 'Voltage |uV|';
                    ax.Title.String = 'aEEG Envelope Height, over time';
            end
            ax.YTickMode = 'manual';
            ax.YTickLabelMode = 'manual';
            ax.YTick = 1:nChannels+7;
            ax.YTickLabel = yLabels(2:nChannels+1); %first&last are blanks
            ax.YTickLabel(19) = {'P3-P4'}; %custom channel 19
            ax.YTickLabel(nChannels+1:nChannels+7) = ...
                {'R anterior','L anterior','R posterior','L posterior',...
                'R hemisphere','L hemisphere','Global'};
            ax.XLabel.String = 'Time (minutes)';
        end
        
        % Export for Maas' project
        function exportaEEG(~,~)
            xaEEG = aEEGmax';
            xaEEG = [xaEEG aEEGmin'];
            xaEEG = [xaEEG aEEGdel'];
            tDate = datestr(tStart,23);
            xlHeader = cell(3,2+size(xaEEG,2));
            xlHeader(1,1:4) = {'Filename:',filename,'Date:',tDate};
            xlHeader(2,:) = {'Time','GCS',...
            'aEEG Maximum Fp1-F7', 'aEEG Maximum F7-T7',...
            'aEEG Maximum T7-P7' , 'aEEG Maximum P7-O1',...
            'aEEG Maximum Fp1-F3', 'aEEG Maximum F3-C3',...
            'aEEG Maximum C3-P3' , 'aEEG Maximum P3-O1',...
            'aEEG Maximum Fz-Cz' , 'aEEG Maximum Cz-Pz',...
            'aEEG Maximum Fp2-F4', 'aEEG Maximum F4-C4',...
            'aEEG Maximum C4-P4' , 'aEEG Maximum P4-O2',...
            'aEEG Maximum Fp2-F8', 'aEEG Maximum F8-T8',...
            'aEEG Maximum T8-P8' , 'aEEG Maximum P8-O2',...
            'aEEG Maximum P3-P4'   , 'aEEG Maximum R anterior',...
            'aEEG Maximum L anterior','aEEG Maximum R posterior',...
            'aEEG Maximum L posterior','aEEG Maximum R hemisphere',...
            'aEEG Maximum L hemisphere','aEEG Maximum Global',...
            'aEEG Minimum Fp1-F7', 'aEEG Minimum F7-T7',...
            'aEEG Minimum T7-P7' , 'aEEG Minimum P7-O1',...
            'aEEG Minimum Fp1-F3', 'aEEG Minimum F3-C3',...
            'aEEG Minimum C3-P3' , 'aEEG Minimum P3-O1',...
            'aEEG Minimum Fz-Cz' , 'aEEG Minimum Cz-Pz',...
            'aEEG Minimum Fp2-F4', 'aEEG Minimum F4-C4',...
            'aEEG Minimum C4-P4' , 'aEEG Minimum P4-O2',...
            'aEEG Minimum Fp2-F8', 'aEEG Minimum F8-T8',...
            'aEEG Minimum T8-P8' , 'aEEG Minimum P8-O2',...
            'aEEG Minimum P3-P4'   , 'aEEG Minimum R anterior',...
            'aEEG Minimum L anterior','aEEG Minimum R posterior',...
            'aEEG Minimum L posterior','aEEG Minimum R hemisphere',...
            'aEEG Minimum L hemisphere','aEEG Minimum Global',...           
            'aEEG Max-Min Fp1-F7', 'aEEG Max-Min F7-T7',...
            'aEEG Max-Min T7-P7' , 'aEEG Max-Min P7-O1',...
            'aEEG Max-Min Fp1-F3', 'aEEG Max-Min F3-C3',...
            'aEEG Max-Min C3-P3' , 'aEEG Max-Min P3-O1',...
            'aEEG Max-Min Fz-Cz' , 'aEEG Max-Min Cz-Pz',...
            'aEEG Max-Min Fp2-F4', 'aEEG Max-Min F4-C4',...
            'aEEG Max-Min C4-P4' , 'aEEG Max-Min P4-O2',...
            'aEEG Max-Min Fp2-F8', 'aEEG Max-Min F8-T8',...
            'aEEG Max-Min T8-P8' , 'aEEG Max-Min P8-O2',...
            'aEEG Max-Min P3-P4'   , 'aEEG Max-Min R anterior',...
            'aEEG Max-Min L anterior','aEEG Max-Min R posterior',...
            'aEEG Max-Min L posterior','aEEG Max-Min R hemisphere',...
            'aEEG Max-Min L hemisphere','aEEG Max-Min Global'};  
            t = (datetime(tStart) + minutes(0:size(xaEEG,1)-1))';
            t = cellstr(string(datestr(t,13)));
            xlswrite(strcat(filename,'.xlsx'),xlHeader,'aEEG')
            xlswrite(strcat(filename,'.xlsx'),t,'aEEG','A3')
            xlswrite(strcat(filename,'.xlsx'),xaEEG,'aEEG','C3')
            disp('An Excel file containing aEEG data was exported.');
        end
    end

%Dominant Frequencies
    function GDomFreq(~,~)
        disp('Running dominant frequency calculations...');
        % Global scope, break into bands and plot against time
        fDomFreq = figure;
        fDomFreq.Name = 'Median Frequency within each EEG band';
        fDomFreq.NumberTitle = 'off';
        fDomFreq.MenuBar = 'none'; %use 'none' to hide default MATLAB menu/toolbar
        fDomFreq.ToolBar = 'none';
        fDomFreq.Units = 'normalized';
        fDomFreq.OuterPosition = [0 0 1 1];
        % Get bandpowers per channel over the EEG montage
        total = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        delta = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        theta = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        alpha = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
         beta = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));

        j=0;
        for i=1:sRate*60:maxX-(sRate*60) %60 = per-minute bandpower
            % NOTE: EEGLAB replaces the built-in MATLAB bandpower function.
            % This is made to use the MATLAB function, not EEGLAB's.
            j = j+1;
            total(:,j) = medfreq(EEG(:,i:i+(sRate*60))',sRate,[1 20]);
            delta(:,j) = medfreq(EEG(:,i:i+(sRate*60))',sRate,[1 4]);
            theta(:,j) = medfreq(EEG(:,i:i+(sRate*60))',sRate,[4 8]);
            alpha(:,j) = medfreq(EEG(:,i:i+(sRate*60))',sRate,[8 13]);
             beta(:,j) = medfreq(EEG(:,i:i+(sRate*60))',sRate,[13 20]);
        end
        clear i j;

        % Add extra 7 "metadata" channels:
        % NOTE: This assumes LB18.1 montage!
        %R anter (11=Fp2-F4,12=F4-C4,13=C4-P4,15=Fp2-F8,16=F8-F8,17=T8-P8),
        total(nChannels+1,:) = (total(11,:) + total(12,:) + total(13,:)...
            + total(15,:) + total(16,:) + total(17,:))/6;
        delta(nChannels+1,:) = (delta(11,:) + delta(12,:) + delta(13,:)...
            + delta(15,:) + delta(16,:) + delta(17,:))/6;
        theta(nChannels+1,:) = (theta(11,:) + theta(12,:) + theta(13,:)...
            + theta(15,:) + theta(16,:) + theta(17,:))/6;
        alpha(nChannels+1,:) = (alpha(11,:) + alpha(12,:) + alpha(13,:)...
            + alpha(15,:) + alpha(16,:) + alpha(17,:))/6;
         beta(nChannels+1,:) = (beta(11,:) + beta(12,:) + beta(13,:)...
            + beta(15,:) + beta(16,:) + beta(17,:))/6;
        %L anterior (1=Fp1-F7,2=F7-T7,3=T7-P7,5=Fp1-F3,6=F3-C3,7=C3-P3),
        total(nChannels+2,:) = (total(1,:) + total(2,:) + total(3,:)...
            + total(5,:) + total(6,:) + total(7,:))/6;
        delta(nChannels+2,:) = (delta(1,:) + delta(2,:) + delta(3,:)...
            + delta(5,:) + delta(6,:) + delta(7,:))/6;
        theta(nChannels+2,:) = (theta(1,:) + theta(2,:) + theta(3,:)...
            + theta(5,:) + theta(6,:) + theta(7,:))/6;
        alpha(nChannels+2,:) = (alpha(1,:) + alpha(2,:) + alpha(3,:)...
            + alpha(5,:) + alpha(6,:) + alpha(7,:))/6;
         beta(nChannels+2,:) = (beta(1,:) + beta(2,:) + beta(3,:)...
            + beta(5,:) + beta(6,:) + beta(7,:))/6;
        %R posterior (14=P4-O2,18=P8-O2),
        total(nChannels+3,:) = (total(14,:)+total(18,:))/2;
        delta(nChannels+3,:) = (delta(14,:)+delta(18,:))/2;
        theta(nChannels+3,:) = (theta(14,:)+theta(18,:))/2;
        alpha(nChannels+3,:) = (alpha(14,:)+alpha(18,:))/2;
         beta(nChannels+3,:) = ( beta(14,:)+ beta(18,:))/2;
        %L posterior ( 4=P7-O1, 8=P3-O1),
        total(nChannels+4,:) = (total(4,:)+total(8,:))/2;
        delta(nChannels+4,:) = (delta(4,:)+delta(8,:))/2;
        theta(nChannels+4,:) = (theta(4,:)+theta(8,:))/2;
        alpha(nChannels+4,:) = (alpha(4,:)+alpha(8,:))/2;
         beta(nChannels+4,:) = ( beta(4,:)+ beta(8,:))/2;
        %R hemisphere (11-18),
        total(nChannels+5,:) = (total(11,:) + total(12,:) + total(13,:)...
            + total(15,:) + total(16,:) + total(17,:) + total(14,:)...
            + total(18,:))/8;
        delta(nChannels+5,:) = (delta(11,:) + delta(12,:) + delta(13,:)...
            + delta(15,:) + delta(16,:) + delta(17,:) + delta(14,:)...
            + delta(18,:))/8;
        theta(nChannels+5,:) = (theta(11,:) + theta(12,:) + theta(13,:)...
            + theta(15,:) + theta(16,:) + theta(17,:) + theta(14,:)...
            + theta(18,:))/8;
        alpha(nChannels+5,:) = (alpha(11,:) + alpha(12,:) + alpha(13,:)...
            + alpha(15,:) + alpha(16,:) + alpha(17,:) + alpha(14,:)...
            + alpha(18,:))/8;
         beta(nChannels+5,:) = (beta(11,:) + beta(12,:) + beta(13,:)...
            + beta(15,:) + beta(16,:) + beta(17,:) + beta(14,:)...
            + beta(18,:))/8;
        %L hemisphere ( 1-8),
        total(nChannels+6,:) = (total(1,:) + total(2,:) + total(3,:)...
            + total(5,:) + total(6,:) + total(7,:) + total(4,:)...
            + total(8,:))/8;
        delta(nChannels+6,:) = (delta(1,:) + delta(2,:) + delta(3,:)...
            + delta(5,:) + delta(6,:) + delta(7,:) + delta(4,:)...
            + delta(8,:))/8;
        theta(nChannels+6,:) = (theta(1,:) + theta(2,:) + theta(3,:)...
            + theta(5,:) + theta(6,:) + theta(7,:) + theta(4,:)...
            + theta(8,:))/8;
        alpha(nChannels+6,:) = (alpha(1,:) + alpha(2,:) + alpha(3,:)...
            + alpha(5,:) + alpha(6,:) + alpha(7,:) + alpha(4,:)...
            + alpha(8,:))/8;
         beta(nChannels+6,:) = (beta(1,:) + beta(2,:) + beta(3,:)...
            + beta(5,:) + beta(6,:) + beta(7,:) + beta(4,:)...
            + beta(8,:))/8;
        %Global (1-18)
        total(nChannels+7,:)=(total(nChannels+5,:)+total(nChannels+6,:))/2;
        delta(nChannels+7,:)=(delta(nChannels+5,:)+delta(nChannels+6,:))/2;
        theta(nChannels+7,:)=(theta(nChannels+5,:)+theta(nChannels+6,:))/2;
        alpha(nChannels+7,:)=(alpha(nChannels+5,:)+alpha(nChannels+6,:))/2;
         beta(nChannels+7,:)=(beta(nChannels+5,:)+beta(nChannels+6,:))/2;
        
        % Plots: Total, Delta, Theta, Alpha, Beta, A:D, (A+B):(D+T)
        % Power units are |uV|^2 / Hz
        popup = uicontrol(fDomFreq,'Style', 'popup',...
           'String', {'Total','Delta','Theta','Alpha','Beta'},... 
           'Units','normalized',...
           'Position', [0.02 0.94 0.1 0.04],'Callback', @changePlot);
        export = uicontrol(fDomFreq,'Style','pushbutton', ...
            'Callback',@exportDomFreq,'String','Export');
        % Position is [left bottom width height]
        imagesc(0);
        ax = gca;
        ax.Title.String = 'Select a plot type on the left to begin...';
        
        function changePlot(source,~)
            switch(source.Value)
                case 1 %Total
                    imagesc(total);c = colorbar;
                    c.Label.String = 'Frequency (Hz)';
                    ax.Title.String = 'Median Frequency, 1-20 Hz, over time';
                case 2 %Raw Delta
                    imagesc(delta);c = colorbar;
                    c.Label.String = 'Frequency (Hz)';
                    ax.Title.String = 'Median Frequency, 1-4 Hz, over time';
                case 3 %Raw Theta
                    imagesc(theta);c = colorbar;
                    c.Label.String = 'Frequency (Hz)';
                    ax.Title.String = 'Median Frequency, 4-8 Hz, over time';
                case 4 %Raw Alpha
                    imagesc(alpha);c = colorbar;
                    c.Label.String = 'Frequency (Hz)';
                    ax.Title.String = 'Median Frequency, 8-13 Hz, over time';
                case 5 %Raw Beta
                    imagesc(beta);c = colorbar;
                    c.Label.String = 'Frequency (Hz)';
                    ax.Title.String = 'Median Frequency, 13-20 Hz, over time';
            end
            ax.YTickMode = 'manual';
            ax.YTickLabelMode = 'manual';
            ax.YTick = 1:nChannels+7;
            ax.YTickLabel = yLabels(2:nChannels+1); %first&last are blanks
            ax.YTickLabel(nChannels+1:nChannels+7) = ...
                {'R anterior','L anterior','R posterior','L posterior',...
                'R hemisphere','L hemisphere','Global'};
            ax.XLabel.String = 'Time (minutes)';
        end
        
        % Export for Maas' project
        function exportDomFreq(~,~)
            df = total';
            df = [df delta'];
            df = [df theta'];
            df = [df alpha'];
            df = [df  beta'];
            tDate = datestr(tStart,23);
            xlHeader = cell(3,2+size(df,2));
            xlHeader(1,1:4) = {'Filename:',filename,'Date:',tDate};
            xlHeader(2,:) = {'Time','GCS',...
            'DomFreq Total Fp1-F7', 'DomFreq Total F7-T7',...
            'DomFreq Total T7-P7' , 'DomFreq Total P7-O1',...
            'DomFreq Total Fp1-F3', 'DomFreq Total F3-C3',...
            'DomFreq Total C3-P3' , 'DomFreq Total P3-O1',...
            'DomFreq Total Fz-Cz' , 'DomFreq Total Cz-Pz',...
            'DomFreq Total Fp2-F4', 'DomFreq Total F4-C4',...
            'DomFreq Total C4-P4' , 'DomFreq Total P4-O2',...
            'DomFreq Total Fp2-F8', 'DomFreq Total F8-T8',...
            'DomFreq Total T8-P8' , 'DomFreq Total P8-O2',...
            'DomFreq Total EKG'   , 'DomFreq Total R anterior',...
            'DomFreq Total L anterior','DomFreq Total R posterior',...
            'DomFreq Total L posterior','DomFreq Total R hemisphere',...
            'DomFreq Total L hemisphere','DomFreq Total Global',...
            'DomFreq Delta Fp1-F7', 'DomFreq Delta F7-T7',...
            'DomFreq Delta T7-P7' , 'DomFreq Delta P7-O1',...
            'DomFreq Delta Fp1-F3', 'DomFreq Delta F3-C3',...
            'DomFreq Delta C3-P3' , 'DomFreq Delta P3-O1',...
            'DomFreq Delta Fz-Cz' , 'DomFreq Delta Cz-Pz',...
            'DomFreq Delta Fp2-F4', 'DomFreq Delta F4-C4',...
            'DomFreq Delta C4-P4' , 'DomFreq Delta P4-O2',...
            'DomFreq Delta Fp2-F8', 'DomFreq Delta F8-T8',...
            'DomFreq Delta T8-P8' , 'DomFreq Delta P8-O2',...
            'DomFreq Delta EKG'   , 'DomFreq Delta R anterior',...
            'DomFreq Delta L anterior','DomFreq Delta R posterior',...
            'DomFreq Delta L posterior','DomFreq Delta R hemisphere',...
            'DomFreq Delta L hemisphere','DomFreq Delta Global',...           
            'DomFreq Theta Fp1-F7', 'DomFreq Theta F7-T7',...
            'DomFreq Theta T7-P7' , 'DomFreq Theta P7-O1',...
            'DomFreq Theta Fp1-F3', 'DomFreq Theta F3-C3',...
            'DomFreq Theta C3-P3' , 'DomFreq Theta P3-O1',...
            'DomFreq Theta Fz-Cz' , 'DomFreq Theta Cz-Pz',...
            'DomFreq Theta Fp2-F4', 'DomFreq Theta F4-C4',...
            'DomFreq Theta C4-P4' , 'DomFreq Theta P4-O2',...
            'DomFreq Theta Fp2-F8', 'DomFreq Theta F8-T8',...
            'DomFreq Theta T8-P8' , 'DomFreq Theta P8-O2',...
            'DomFreq Theta EKG'   , 'DomFreq Theta R anterior',...
            'DomFreq Theta L anterior','DomFreq Theta R posterior',...
            'DomFreq Theta L posterior','DomFreq Theta R hemisphere',...
            'DomFreq Theta L hemisphere','DomFreq Theta Global',...
            'DomFreq Alpha Fp1-F7', 'DomFreq Alpha F7-T7',...
            'DomFreq Alpha T7-P7' , 'DomFreq Alpha P7-O1',...
            'DomFreq Alpha Fp1-F3', 'DomFreq Alpha F3-C3',...
            'DomFreq Alpha C3-P3' , 'DomFreq Alpha P3-O1',...
            'DomFreq Alpha Fz-Cz' , 'DomFreq Alpha Cz-Pz',...
            'DomFreq Alpha Fp2-F4', 'DomFreq Alpha F4-C4',...
            'DomFreq Alpha C4-P4' , 'DomFreq Alpha P4-O2',...
            'DomFreq Alpha Fp2-F8', 'DomFreq Alpha F8-T8',...
            'DomFreq Alpha T8-P8' , 'DomFreq Alpha P8-O2',...
            'DomFreq Alpha EKG'   , 'DomFreq Alpha R anterior',...
            'DomFreq Alpha L anterior','DomFreq Alpha R posterior',...
            'DomFreq Alpha L posterior','DomFreq Alpha R hemisphere',...
            'DomFreq Alpha L hemisphere','DomFreq Alpha Global',...           
            'DomFreq Beta Fp1-F7', 'DomFreq Beta F7-T7',...
            'DomFreq Beta T7-P7' , 'DomFreq Beta P7-O1',...
            'DomFreq Beta Fp1-F3', 'DomFreq Beta F3-C3',...
            'DomFreq Beta C3-P3' , 'DomFreq Beta P3-O1',...
            'DomFreq Beta Fz-Cz' , 'DomFreq Beta Cz-Pz',...
            'DomFreq Beta Fp2-F4', 'DomFreq Beta F4-C4',...
            'DomFreq Beta C4-P4' , 'DomFreq Beta P4-O2',...
            'DomFreq Beta Fp2-F8', 'DomFreq Beta F8-T8',...
            'DomFreq Beta T8-P8' , 'DomFreq Beta P8-O2',...
            'DomFreq Beta EKG'   , 'DomFreq Beta R anterior',...
            'DomFreq Beta L anterior','DomFreq Beta R posterior',...
            'DomFreq Beta L posterior','DomFreq Beta R hemisphere',...
            'DomFreq Beta L hemisphere','DomFreq Beta Global'};  
            t = (datetime(tStart) + minutes(0:size(df,1)-1))';
            t = cellstr(string(datestr(t,13)));
            xlswrite(strcat(filename,'.xlsx'),xlHeader,'Dominant Frequency')
            xlswrite(strcat(filename,'.xlsx'),t,'Dominant Frequency','A3')
            xlswrite(strcat(filename,'.xlsx'),df,'Dominant Frequency','C3')
            disp('An Excel file with dominant frequency data was exported.');
        end
    end

%Spectral Edge Frequencies
    function GSpectralEdge(~,~)
        disp('Running spectral edge frequency calculations...');
        fOBW = figure;
        fOBW.Name = 'Spectral Edge Frequencies and Bandwidth';
        fOBW.NumberTitle = 'off';
        fOBW.MenuBar = 'none'; %use 'none' to hide default MATLAB menu/toolbar
        fOBW.ToolBar = 'none';
        fOBW.Units = 'normalized';
        fOBW.OuterPosition = [0 0 1 1];

        bw = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        flo = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        fhi = zeros(nChannels,length(1:sRate*60:maxX-(sRate*60)));
        j=0;
        for i=1:sRate*60:maxX-(sRate*60) %60 = per-minute
            j = j+1;
            [bw(:,j),flo(:,j),fhi(:,j),~] = obw(EEG(:,i:i+(sRate*60))',...
                sRate,[0 20],90);
        end
        clear i j;

        % Add extra 7 "metadata" channels:
        % NOTE: This assumes LB18.1 montage!
        %R anter (11=Fp2-F4,12=F4-C4,13=C4-P4,15=Fp2-F8,16=F8-F8,17=T8-P8),
        bw(nChannels+1,:) = (bw(11,:) + bw(12,:) + ...
            bw(13,:) + bw(15,:) + bw(16,:) + ...
            bw(17,:))/6;
        flo(nChannels+1,:) = (flo(11,:) + flo(12,:) + ...
            flo(13,:) + flo(15,:) + flo(16,:) + ...
            flo(17,:))/6;
        fhi(nChannels+1,:) = (fhi(11,:) + fhi(12,:) + ...
            fhi(13,:) + fhi(15,:) + fhi(16,:) + ...
            fhi(17,:))/6;
        %L anterior (1=Fp1-F7,2=F7-T7,3=T7-P7,5=Fp1-F3,6=F3-C3,7=C3-P3),
        bw(nChannels+2,:) = (bw(1,:) + bw(2,:) + ...
            bw(3,:) + bw(5,:) + bw(6,:) + bw(7,:))/6;
        flo(nChannels+2,:) = (flo(1,:) + flo(2,:) + ...
            flo(3,:) + flo(5,:) + flo(6,:) + flo(7,:))/6;
        fhi(nChannels+2,:) = (fhi(1,:) + fhi(2,:) + ...
            fhi(3,:) + fhi(5,:) + fhi(6,:) + fhi(7,:))/6;
        %R posterior (14=P4-O2,18=P8-O2),
        bw(nChannels+3,:) = (bw(14,:) + bw(18,:))/2;
        flo(nChannels+3,:) = (flo(14,:) + flo(18,:))/2;
        fhi(nChannels+3,:) = (fhi(14,:) + fhi(18,:))/2;
        %L posterior ( 4=P7-O1, 8=P3-O1),
        bw(nChannels+4,:) = (bw(4,:)+bw(8,:))/2;
        flo(nChannels+4,:) = (flo(4,:)+flo(8,:))/2;
        fhi(nChannels+4,:) = (fhi(4,:)+fhi(8,:))/2;
        %R hemisphere (11-18),
        bw(nChannels+5,:) = (bw(11,:) + bw(12,:) + ...
            bw(13,:) + bw(14,:) + bw(15,:) + ...
            bw(16,:) + bw(17,:) + bw(18,:))/8;
        flo(nChannels+5,:) = (flo(11,:) + flo(12,:) + ...
            flo(13,:) + flo(14,:) + flo(15,:) + ...
            flo(16,:) + flo(17,:) + flo(18,:))/8;
        fhi(nChannels+5,:) = (fhi(11,:) + fhi(12,:) + ...
            fhi(13,:) + fhi(14,:) + fhi(15,:) + ...
            fhi(16,:) + fhi(17,:) + fhi(18,:))/8;
        %L hemisphere ( 1-8),
        bw(nChannels+6,:) = (bw(1,:) + bw(2,:) + ...
            bw(3,:) + bw(4,:) + bw(5,:) + bw(6,:) + ...
            bw(7,:) + bw(8,:))/8;
        flo(nChannels+6,:) = (flo(1,:) + flo(2,:) + ...
            flo(3,:) + flo(4,:) + flo(5,:) + flo(6,:) + ...
            flo(7,:) + flo(8,:))/8;
        fhi(nChannels+6,:) = (fhi(1,:) + fhi(2,:) + ...
            fhi(3,:) + fhi(4,:) + fhi(5,:) + fhi(6,:) + ...
            fhi(7,:) + fhi(8,:))/8;
        %Global (1-18)
        bw(nChannels+7,:) = ...
            (bw(nChannels+5,:) + bw(nChannels+6,:))/2;
        flo(nChannels+7,:) = ...
            (flo(nChannels+5,:) + flo(nChannels+6,:))/2;
        fhi(nChannels+7,:) = ...
            (fhi(nChannels+5,:) + fhi(nChannels+6,:))/2;
        
        % Plots: Total, Delta, Theta, Alpha, Beta, A:D, (A+B):(D+T)
        % Power units are |uV|^2 / Hz
        popup = uicontrol(fOBW,'Style', 'popup',...
           'String', {'Bandwidth','Low Edge','High Edge'},'Units','normalized',...
           'Position', [0.02 0.94 0.1 0.04],'Callback', @changePlot);
        export = uicontrol(fOBW,'Style','pushbutton', ...
            'Callback',@exportOBW,'String','Export');
        % Position is [left bottom width height]
        imagesc(0);
        ax = gca;
        ax.Title.String = 'Select a plot type on the left to begin...';
        
        function changePlot(source,~)
            switch(source.Value)
                case 1 %Bandwidth
                    imagesc(bw);c = colorbar;
                    c.Label.String = 'Bandwidth (Hz)';
                    ax.Title.String = '90% Signal Bandwidth, over time';
                case 2 %Low Edge
                    imagesc(flo);c = colorbar;
                    c.Label.String = 'Frequency (Hz)';
                    ax.Title.String = 'Spectral Low Edge Frequency, over time';
                case 3 %High Edge
                    imagesc(fhi);c = colorbar;
                    c.Label.String = 'Frequency (Hz)';
                    ax.Title.String = 'Spectral High Edge Frequency, over time';
            end
            ax.YTickMode = 'manual';
            ax.YTickLabelMode = 'manual';
            ax.YTick = 1:nChannels+7;
            ax.YTickLabel = yLabels(2:nChannels+1); %first&last are blanks
            ax.YTickLabel(nChannels+1:nChannels+7) = ...
                {'R anterior','L anterior','R posterior','L posterior',...
                'R hemisphere','L hemisphere','Global'};
            ax.XLabel.String = 'Time (minutes)';
        end
        
        % Export for Maas' project
        function exportOBW(~,~)
            xOBW = bw';
            xOBW = [xOBW flo'];
            xOBW = [xOBW fhi'];
            tDate = datestr(tStart,23);
            xlHeader = cell(3,2+size(xOBW,2));
            xlHeader(1,1:4) = {'Filename:',filename,'Date:',tDate};
            xlHeader(2,:) = {'Time','GCS',...
            'SEF90 Bandwidth Fp1-F7', 'SEF90 Bandwidth F7-T7',...
            'SEF90 Bandwidth T7-P7' , 'SEF90 Bandwidth P7-O1',...
            'SEF90 Bandwidth Fp1-F3', 'SEF90 Bandwidth F3-C3',...
            'SEF90 Bandwidth C3-P3' , 'SEF90 Bandwidth P3-O1',...
            'SEF90 Bandwidth Fz-Cz' , 'SEF90 Bandwidth Cz-Pz',...
            'SEF90 Bandwidth Fp2-F4', 'SEF90 Bandwidth F4-C4',...
            'SEF90 Bandwidth C4-P4' , 'SEF90 Bandwidth P4-O2',...
            'SEF90 Bandwidth Fp2-F8', 'SEF90 Bandwidth F8-T8',...
            'SEF90 Bandwidth T8-P8' , 'SEF90 Bandwidth P8-O2',...
            'SEF90 Bandwidth P3-P4'   , 'SEF90 Bandwidth R anterior',...
            'SEF90 Bandwidth L anterior','SEF90 Bandwidth R posterior',...
            'SEF90 Bandwidth L posterior','SEF90 Bandwidth R hemisphere',...
            'SEF90 Bandwidth L hemisphere','SEF90 Bandwidth Global',...
            'SEF90 Low Edge Fp1-F7', 'SEF90 Low Edge F7-T7',...
            'SEF90 Low Edge T7-P7' , 'SEF90 Low Edge P7-O1',...
            'SEF90 Low Edge Fp1-F3', 'SEF90 Low Edge F3-C3',...
            'SEF90 Low Edge C3-P3' , 'SEF90 Low Edge P3-O1',...
            'SEF90 Low Edge Fz-Cz' , 'SEF90 Low Edge Cz-Pz',...
            'SEF90 Low Edge Fp2-F4', 'SEF90 Low Edge F4-C4',...
            'SEF90 Low Edge C4-P4' , 'SEF90 Low Edge P4-O2',...
            'SEF90 Low Edge Fp2-F8', 'SEF90 Low Edge F8-T8',...
            'SEF90 Low Edge T8-P8' , 'SEF90 Low Edge P8-O2',...
            'SEF90 Low Edge P3-P4'   , 'SEF90 Low Edge R anterior',...
            'SEF90 Low Edge L anterior','SEF90 Low Edge R posterior',...
            'SEF90 Low Edge L posterior','SEF90 Low Edge R hemisphere',...
            'SEF90 Low Edge L hemisphere','SEF90 Low Edge Global',...           
            'SEF90 High Edge Fp1-F7', 'SEF90 High Edge F7-T7',...
            'SEF90 High Edge T7-P7' , 'SEF90 High Edge P7-O1',...
            'SEF90 High Edge Fp1-F3', 'SEF90 High Edge F3-C3',...
            'SEF90 High Edge C3-P3' , 'SEF90 High Edge P3-O1',...
            'SEF90 High Edge Fz-Cz' , 'SEF90 High Edge Cz-Pz',...
            'SEF90 High Edge Fp2-F4', 'SEF90 High Edge F4-C4',...
            'SEF90 High Edge C4-P4' , 'SEF90 High Edge P4-O2',...
            'SEF90 High Edge Fp2-F8', 'SEF90 High Edge F8-T8',...
            'SEF90 High Edge T8-P8' , 'SEF90 High Edge P8-O2',...
            'SEF90 High Edge P3-P4'   , 'SEF90 High Edge R anterior',...
            'SEF90 High Edge L anterior','SEF90 High Edge R posterior',...
            'SEF90 High Edge L posterior','SEF90 High Edge R hemisphere',...
            'SEF90 High Edge L hemisphere','SEF90 High Edge Global'};  
            t = (datetime(tStart) + minutes(0:size(xOBW,1)-1))';
            t = cellstr(string(datestr(t,13)));
            xlswrite(strcat(filename,'.xlsx'),xlHeader,'Spectral Edge')
            xlswrite(strcat(filename,'.xlsx'),t,'Spectral Edge','A3')
            xlswrite(strcat(filename,'.xlsx'),xOBW,'Spectral Edge','C3')
            disp('An Excel file containing spectral edge data was exported.');
        end    
    end

%% Window
% STFT Scrolling Montage
    function GSTFTMontage(~,~)
        if strcmp(mSTFTMontage.Checked,'off')
            mSTFTMontage.Checked = 'on';
            fSTFTMontage.Visible = 'on';
            drawEEG;
        else
            mSTFTMontage.Checked = 'off';
            fSTFTMontage.Visible = 'off';            
        end
    end

end
%% Things left to do:
% Note: Search above code for TODO!
%
% Part 1: Quality-of-life / functionality improvements
% *: Artifact rejection / EKG removal / pop removal
% *: Make exports work for more than bipolar montage
% *: "Universal Open": Find each channel in raw data and assign
% *: Time on X-axis instead of sample number
% *: X-axis scrollbar! With begin and end time and notches with timepoints
% *: Have spectrogram with finite upper/lower POWER bounds,
%    maybe put in adaptive vertical scrollbars/upper-lower brackets!
% *: Fix per-channel sensitivity (EKG 50 uV/mm; EEG 7 uV/mm)
% *: Scale bar, maybe right Y-axis can have uV?
% *: Filter menu (low, high, notch)
% *: Error handling! and break into real functions / do documentation
%
% Part 2: qEEG Implementation
% Persyst metrics not yet implemented:
% Rhythmicity (Z) in frequency (Y; 1-25Hz) vs time (X), lateralized L & R
% - this is done "by channel" in a bipolar montage
% Asymmetry, red/left vs blue/right, frequency 1-18Hz, plotted as trendline
% - this is done as "absolute" and "relative" (EASI and REASI)
% aEEG global and lateralized L & R, log power 0 - 10 - 100 uV
% - how to do? filter, rectify, smooth?
% Peak Envelope, red vs blue, 2-20Hz, trendline
% FFT lateralized L & R, 0-20 Hz
% Suppression ratio, lateralized L &R
% New metrics not yet implemented:
% - pairwise compare (see PMID 19375386)
% - Complexity measures: Entropy, correlation dimension, spectral exponent
% - Interdependency measures: Correlation coeff, coherence, mutual
% information
% - R-R interval info on the EKG channel!
%
% Part 3: Implement the 2012 ACNS ICU EEG Standardized Nomenclature!!
% And, run an automated analyzer on the EEG! Pseudocode:
% For a given chunk (say 10 seconds) until end of recording:
%  Is it usable or artifact?
%   If artifact, note the type, and go to next chunk
%   If usable,
%    - For all channels, determine background amplitude (RMS average?) use
%    referential montage; and frequency using STFT or wavelet. Allowed to
%    have 2-3 dominant frequencies!
%    - Report frequency band as global average, and per hemisphere
%    - Report amplitude as normal; low is <20 uV p-p in "most or all" leads
%      and suppressed is <10 uV p-p. If discontinuous, do this on a BURST.
%    - Assess for asymmetry between hemispheres (expand to territories?)
%    define as mild if 0.5-1.0Hz asymmetry or <50% amplitude asymmetry
%    define as marked if >1.0Hz or >=50% asymmetry
%     + If asymmetric, is it consistent with breach effect (yes/no/unclear)
%     + If not asymmetric, call as symmetric
%    - Assess for posterior dominant rhythm (dominant frequency
%      when awake after eye closure. MUST attenuate with eye opening). Can
%      be absent. Report to nearest 0.5 Hz. Can be asymmetric, note that!
%    - Assess for anterior-posterior gradient: need ONE CONTINUOUS MINUTE 
%      where in anterior leads it's lower amplitude faster frequency and
%      in posterior leads higher amplitude slower frequency. Present/absent
%      Can also be reversed, check for and note if so
%    - Variability: I wonder if I need to do after analysing ALL chunks and
%      look for shifts over hours to do this. Yes/No/Unclear
%    - Reactivity: Yes/No/Unclear. Look for changes in amplitude or freq.
%      following stimulus (how to identify! how to quantify strength/type?) 
%      Eyeblinks and muscle artifact DON'T COUNT!
%    - Assess for continuity: over the RECORD, if there are periods of
%    attenuation or suppression <=10% record, "nearly continuous" and
%    specify if attenuated (<50% background voltage but >=10uV) or 
%    suppressed (<10uV); "discontinuous" 10-49% record; "suppression" is
%    100% of record; and burst-attenuation or burst-suppression in 50-99%
%    where you'll need to also specify duration of burst and interburst
%    intervals; defer sharp/spike/ST and epileptiform stuff inside bursts.
%    Bursts must be 0.5-30 seconds long (<0.5s is a discharge).
% NOT doing sleep structures or discharges yet! Restrain yourself!
%
% Part 4: Nice-to-have features not relevant just yet:
% - Event import, synchronization
% - Adding channel spacers or allowing different channel coloring
% - Compare my program output to Persyst, check filters and qEEG outputs
% - Keyboard/mouse input on ancilliary screens? More shortcuts?
% - Mousewheel up/down to scroll
% - Make measurements (right-click surround box, popup derived stats)