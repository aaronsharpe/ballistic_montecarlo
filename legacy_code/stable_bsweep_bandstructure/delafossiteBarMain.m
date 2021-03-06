%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% delafossiteBar.m
%
% Aaron Sharpe
% 10/17/17
%
% Simulation script file for running simulations of ballistic trajectories
% in field in a delafossite device.
% 
% In the first section, parameters of sweep are specified. Code runs
% through these parameters and outputs plots ands a gif of the simulation
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all

addpath('./bsweep_code','../fab_feature_code','../fab_feature_code/DXFLib')
savepath = '../Data/stable_bsweep_bandstructure/delafossiteBar/';



%00
% widthBar = 6.7;
% lengthBar = 174 + 4 * widthBar;
% phi = 1*pi/6-0*pi/180;

%10
%widthBar = 7.2;
%lengthBar =173 + 4 * widthBar;
%phi = 1*pi/6-10*pi/180;

%20
%widthBar = 6.8;
%lengthBar = 146 + 4 * widthBar;
%phi = 1*pi/6-20*pi/180;

%30
widthBar = 7.6;
lengthBar = 171 + 4 * widthBar;
phi = 1*pi/6-20*pi/180;


dev1 = runDelafossiteBar(lengthBar,widthBar);
close all;

% Set the limits of B sweep
% Field strength in units T * e/(hbar * 10^16)
B_Min = -0.32;
B_Max =  0.32;
B_N   =  1001; 
B = linspace(B_Min,B_Max,B_N)+1E-3;


% Edge properties of simulation
p_ifbounce_then_scatter = 1;
p_bounce_off_ohmic = 0;
L_scatter = inf; % For bulk scattering: scattering length

% Number of injected electrons per condition
N_inject = 501;

% Bandstructure inputs
% Pick something divisible by 6 + 1
n_theta = 253; % Number of points for generating Fermi surface
n_interp = 253; % Number of points to interpolate Fermi surface

%% Generate frm and caustics barrier from a fabFeature object
[frm1,~,cbs]=fabFeature_to_CausticsFrame(dev1);

frm1.plotOhmicLabels();getframe();

% If you set certain ohmics equal to eachother as below, run
% "frm.renumberOhmics()" to make a proper sequential list

%frm1.ohmics{9}.ohmNumber=7;
%frm1.ohmics{5}.ohmNumber=3;
%frm1.renumberOhmics();


frm1=frm1.add_ohmics(frm1.ohmics);

frm1.edgestyle(2) = 0; % 1
frm1.edgestyle(8) = 0;
frm1.edgestyle(4) = 0; % 2
frm1.edgestyle(6) = 0;

%frm1.plotOhmicLabels()

% Chose which ohmics are injectors or terminal ohmics
injector_ohmic=2;
frm1.injector_ohmic=injector_ohmic;
frm1.terminalOhmics=[1];


% This is the relative energy of the electrostatic barriers. If set to 1,
% the barriers are not loaded to accelerate the simulation time
ohmics_barrier=-.2;

frm1.set_og();



 frmgrp=causticFramegroup();
 frmgrp.register_frame(frm1); 
% for i=1:length(cbs)
%     cb1=causticsBarrier(cbs{i}.px,cbs{i}.py,ohmics_barrier);
%     frmgrp.register_frame(cb1);
% end

%% Generate closed caustic loop

% For positive fields
delp = delafossiteBandstructure;
delp.phi = phi;
delp.B = 1;
delp.n_theta = n_theta;
delp.n_interp = n_interp;
delp.init();
% Plot orbits to check shape
delp.KtoR(1)
delp.plotOrbits(2)

deln = delafossiteBandstructure;
deln.phi = phi;
deln.B = -1;
deln.n_theta = n_theta;
deln.n_interp = n_interp;
deln.init();
% Plot orbits to check shape
deln.KtoR(-1)

% Calculate injection probabilities
delp.injectProb(frm1.edgenorm)
deln.injectProb(frm1.edgenorm)



%% Query user and generate directory

fprintf('B_Min = %g hbar/e \n',B_Min)
fprintf('B_Max = %g hbar/e \n',B_Max)
fprintf('B_N = %g\n',B_N)
fprintf('N_inject = %g\n',N_inject)
fprintf('p_ifbounce_then_scatter = %g\n',p_ifbounce_then_scatter)
fprintf('p_bounce_off_ohmic = %g\n',p_bounce_off_ohmic)
fprintf('phi = %g\n',phi)
fprintf('n_theta = %g\n',n_theta)
fprintf('n_interp = %g\n',n_interp)
m = input('Do you want to continue, y/n [y]:','s');
if m == 'n'
    return
end

fnameoutstore = ['phi_' num2str(round(phi,3))...
    ' B_min_' num2str(B_Min) ' B_max_' num2str(B_Max)...
    ' B_N_' num2str(B_N) ' N_' num2str(N_inject)...
    ' p_scatter_' num2str(p_ifbounce_then_scatter)...
    ' p_ohmic_' num2str(p_bounce_off_ohmic)];
fn = 1;
fnameout = fnameoutstore;
while exist([savepath fnameout],'dir')
    fnameout = [fnameoutstore ' (' num2str(fn) ')'];
    fn = fn+1;
end
mkdir([savepath,fnameout]);
save([savepath,fnameout,'/frameData.mat'],'frm1','frmgrp','N_inject');

time = datestr(now,'HH:MM:SS.FFF');
fprintf('\n%s\n\n',time)

%%
% This runs the actual simulation with the above parameters set
runBsweepBS(savepath,fnameout,frmgrp,delp,deln,B,N_inject,p_ifbounce_then_scatter,...
    p_bounce_off_ohmic,L_scatter)


