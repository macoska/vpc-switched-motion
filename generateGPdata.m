%% generateGPdata.m
% *Summary:* Generates the data for the GP models
% 
% Detailed Explanation:
%   Generates the data based on the authors previous work, see:
%       M. Omainska, J. Yamauchi, T. Beckers, T. Hatanaka, S. Hirche, and
%       M. Fujita, “Gaussian process-based visual pursuit control with
%       unknown target motion learning in three dimensions,” SICE Journal
%       of Control, Measurement, and System Integration, vol. 14, no. 1,
%       pp. 116–127, 2021.
%   Data is generated by a prior "cold-run" simulation with just the
%   Visual Motion Observer. The data is then stored in .mat files to be
%   loaded in other scripts.
%
% -----------
%
% Editor:
%   OMAINSKA Marco - Doctoral Student, Cybernetics
%       <marcoomainska@g.ecc.u-tokyo.ac.jp>
% Supervisor:
%   YAMAUCHI Junya - Assistant Professor
%       <junya_yamauchi@ipc.i.u-tokyo.ac.jp>
%
% Property of: Fujita-Yamauchi Lab, University of Tokyo, 2022
% e-mail: marcoomainska@g.ecc.u-tokyo.ac.jp
% Website: https://www.scl.ipc.i.u-tokyo.ac.jp
% February 2022
%
% ------------- BEGIN CODE -------------

%% Settings

% VMO settings

% observer gain
Ke = 30*eye(6);

% focal length
lambda = 20;

% feature points
fp = [   0,  0,  0.5;
       0.5,  0,    0;
       0,    0, -0.5;
      -0.5,  0,    0];
  

% Van-Der-Pol Trajectory Settings
eta1 = 0.5;
eta2 = 1.5;
v1 = 1;
v2 = 0.5;
offset1 = [2 0 0];
offset2 = [2 0 0];
scale1 = 1;
scale2 = 1;


% Initial conditions
gco_init = mergepose(eye(3),[0 1 0]);
gwc_init = mergepose(eye(3),[0 -5 0]);
pwo_init = [0 0 0];


%% simulate
tend = 20; % simulation time

% vanderpol 1st
psi = 1;
simout_1 = sim('generateData');

% vanderpol 2nd
psi = 2;
simout_2 = sim('generateData');


%% animate

figure('Name','Van Der Pol 1 Animation','NumberTitle','off',...
    'Units','normalized','Position',[.55 .2 .4 .5]);
title('Van Der Pol 1 Animation')
animate(simout_1);

figure('Name','Van Der Pol 2 Animation','NumberTitle','off',...
    'Units','normalized','Position',[.55 .2 .4 .5]);
title('Van Der Pol 2 Animation')
animate(simout_2);


%% Define GP datasets

% define GP dataset 1
dt = simout_1.SimulationMetadata.ModelInfo.SolverInfo.FixedStepSize;
X1_ = check(simout_1.gwo.signals.values);
Y1 = simout_1.Vbwo.signals.values;
% reduce dataset
M1 = 30;
idx = ceil(linspace(7/dt,13/dt,M1));
X1 = X1_(idx,:);
Y1 = Y1(idx,:);

% define GP dataset 2
dt = simout_2.SimulationMetadata.ModelInfo.SolverInfo.FixedStepSize;
X2_ = check(simout_2.gwo.signals.values);
Y2 = simout_2.Vbwo.signals.values;
% reduce dataset
M2 = 30;
idx = ceil(linspace(6/dt,20/dt,M2));
X2 = X2_(idx,:);
Y2 = Y2(idx,:);

% plot dataset
figure('Name','Dataset','NumberTitle','off',...
    'Units','normalized','Position',[.55 .2 .4 .5]);
ax = gca;
hold(ax,'on')
traj_1 = plot3(ax,X1_(:,1),X1_(:,2),X1_(:,3),'Color','#457b9d','LineWidth',2);
traj_2 = plot3(ax,X2_(:,1),X2_(:,2),X2_(:,3),'Color','#38b000','LineWidth',2);
data_1 = plot3(ax,X1(:,1),X1(:,2),X1(:,3),'x','Color','#e63946','MarkerSize',10,'LineWidth',2);
data_2 = plot3(ax,X2(:,1),X2(:,2),X2(:,3),'x','Color','#fb8500','MarkerSize',10,'LineWidth',2);
ax.FontSize = 15;
grid(ax,'on')
xlabel(ax,'x [m]')
ylabel(ax,'y [m]')
zlabel(ax,'z [m]')
legend(ax,[traj_1, traj_2],...
    '$\eta_1 = 0.5, \ v_1 = 1$ \quad',...
    '$\eta_2 = 1.5, \ v_2 = 0.5$ \quad',...
    'Location', 'best',...
    'FontSize', 20,...
    'interpreter', 'latex');
title(ax,'Trajectory Data')

Y1_orig = Y1;
Y2_orig = Y2;


%% Learn GP hyperparameters

% add noise to dataset
sn = 1e-2;
sn1 = 1e-2*ones(6,1);
sn2 = 1e-2*ones(6,1);
Y1  = Y1_orig + sn^2.*gpml_randn(1,M1,6);
Y2  = Y2_orig + sn^2.*gpml_randn(1,M2,6);

% Complete dataset
Xfull = [X1; X2];
Yfull = [Y1; Y2];
snfull = max([sn1, sn2],[],2);

% learn GP models
hyp1 = optimize_hyp(X1,Y1,@covSEard,sn1);
hyp2 = optimize_hyp(X2,Y2,@covSEard,sn2);
hypfull = optimize_hyp(Xfull,Yfull,@covSEard,snfull);
disp('Hyperparameter [GP Van-Der-Pol 1]:')
disp(hyp1)
disp('Hyperparameter [GP Van-Der-Pol 2]:')
disp(hyp2)
disp('Hyperparameter [GP Full]:')
disp(hypfull)


%% Save generated GP data

save('data/GP_1','X1','X1_','Y1','Y1_','hyp1','sn1')
save('data/GP_2','X2','X2_','Y2','Y2_','hyp2','sn2')
save('data/GP_full','Xfull','Yfull','hypfull','snfull')

