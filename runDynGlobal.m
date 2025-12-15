% Agile Robotics Laboratory  at UA
% Date: 10/04/2024
%
% (1) First defining single vertebra dynamics without external forces
% (2) Next will be iterating through series manipulator
% (3) Then will add external forces
clc;
clear;

%Initialize all variables
global prev_T; %Set global variable for T_12(t-1)
R = [0, 0, 1;... %Initial rotation matrix between two arcs
    0, -1, 0;...
    1, 0, 0];
p = [0, -0.75, 0]'; %Initial translation between two arcs - recessed 3/4"
T = [R, p;... %Initial translation matrix
    0, 0, 0, 1];
prev_T = T; %Initialize T_12(0)
[omega,theta,v] = EquivalentScrew3(T); %Initial omega, theta, & v from T
omega = omega/norm(omega);
Xi_0 = theta*[omega', v']'; %Initial body screw
V_0 = Xi_0*0; %Initial body twist
%F_t(:,1) = [0,-5, 0]'; %Force of tendon 1 - add this for external forces
%F_t(:,2) = [0,-2, 0]'; %Force of tendon 2 - add this for external forces
F_m = zeros(3,1); %Set connection force between two vertebra to zero for now
F_t = zeros(3,2); %Set tendon forces to zero for now
%X0 = [Xi_0',V_0']'; %Combine initial variables for ODE45 input
X0 = [Xi_0',V_0', T(1,1:4),T(2,1:4),T(3,1:4),T(4,1:4)]'; %Combine initial variables for ODE45 input
options = odeset('OutputFcn', @update_prev_val); %Set output function

[t, Xvals] = ode45(@(t, X) dynManGlobal(t, X, F_t, F_m), [0 0.5], X0, options); %ODE45 - may have to change ODE solver

%For each iteration, append the body screw and twist data
Xis = Xvals(:,1:6); %Body screws
Vs = Xvals(:,7:12); %Body twists
Ts = Xvals(:,13:28); %T12s?
arc1 = [-1.5, -0.786, 0, 1;... %Fixed arc1 position
    -0.95, 0.264, 0, 1;...
    0.95, 0.264, 0, 1;... 
    1.5, -0.786, 0, 1]';

%Plot the two arcs with arc2 changing with time from ODE solver
figure
plot3(arc1(1,:), arc1(2,:), arc1(3,:),'LineWidth',4) %Arc1
hold on
for i = 1:length(Xis)
    TMatB = screw2TMat(Xi_0);
    arc2_0 = TMatB*arc1;
    plot3(arc2_0(1,:), arc2_0(2,:), arc2_0(3,:),'LineWidth',8) %Initial arc2
    hold on
    %TMatB = screw2TMat(Xis(i,:)');
    TMatB = [Ts(i,1:4);Ts(i,5:8);Ts(i,9:12);Ts(i,13:16)];
    arc2 = TMatB*arc1;
    plot3(arc2(1,:), arc2(2,:), arc2(3,:)) %Changing arc2 position
    hold on    
end

%Define a wrapper function to update the global variable
function status = update_prev_val(t, y, flag)
    global prev_T;
    if isempty(flag) %Only update on normal solver steps
        prev_T = [y(13:16)'; y(17:20)'; y(21:24)'; y(25:28)'];
    end
    status = 0; %Continue the solve
end
