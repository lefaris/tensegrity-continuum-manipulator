% Agile Robotics Laboratory at UA
% Date: 01/06/2025
%
% Note: This file uses a custom integrator to account for non-standard
% diff. eq. that ODE does not solve for
%
% Input: 
% t - time (sec)
% X [18 x 1] - body screw, body velocity, and T(t-1)
% F_t [3 x 1] - tendon friction
% F_m [3 x 1] - connection forces
% Note: F_s (string friction) is not given as an input - it is calculated 
%       and dependent on the changing T_12 with time
%
% Output:
% Xi (body screw) and V (body twist) (both coming from body wrench) as well
% as T_12 (transformation matrix) varying with time for given interval
% 

clc;
clear;

%Initialize all variables
R = [0, 0, 1;... %Initial rotation matrix between two arcs:
     0, -1, 0;... %180 by X and 90 by Y
     1, 0, 0];
% R = [-0.5, 0, 0.8660254;... %Initial rotation matrix between two arcs:
%     0, -1, 0;... %180 by X and 120 by Y
%     0.8660254, 0, 0.5];
p = [0, -0.75, 0]'; %Initial translation between two arcs - recessed 3/4"
T = [R, p;... %Initial translation matrix
    0, 0, 0, 1];
[omega,theta,v] = LieGroup.EquivalentScrew3(T); %Initial omega, theta, & v from T
omega = omega/norm(omega);
F_m = zeros(3,1); %Set connection force between two vertebra to zero for now
F_t = zeros(3,2); %Set tendon forces to zero for now
X0 = [theta,omega',v']'; %Initialize variables for integrator

t_inc = 0.001; %Time increment
t_fin = 3; %Final time to run for

[Ts] = customIntegral(F_t, F_m, t_inc, t_fin, X0); %Screw ODE45 I guess

%For each iteration, append the transformation matrices
T12s = Ts(:,:); %T12s

%  arc1 = [-1.5, -0.786, 0, 1;... %Fixed arc1 position
%      -0.95, 0.264, 0, 1;...
%      0.95, 0.264, 0, 1;... 
%      1.5, -0.786, 0, 1]';
 
     arc1 = [-1.1875, 0, 0, 1;
            -0.6, -1.025, 0, 1;
            0.6, -1.025, 0, 1; 
            1.1875, 0, 0, 1]';

%Plot the two arcs with arc2 changing with time from ODE solver
figure
plot3(arc1(1,:), arc1(2,:), arc1(3,:),'LineWidth',4) %Arc1
hold on

for i = 1:length(T12s)
    TMatB = LieGroup.TMatExponential3(omega,theta,v);
    arc2_0 = TMatB*arc1;
    plot3(arc2_0(1,:), arc2_0(2,:), arc2_0(3,:),'LineWidth',8) %Initial arc2
    hold on
    Tmat = [T12s(i,1:4), T12s(i,5:8), T12s(i,9:12), T12s(i,13:16)]; %Adding T_t-1
    TMatB = reshape(Tmat,[4,4]);
    arc2 = TMatB*arc1;
    plot3(arc2(1,:), arc2(2,:), arc2(3,:)) %Changing arc2 position
    hold on    
end



function [Ts] = customIntegral(F_t, F_m, t_inc, t_fin, X0)
for j=0:t_inc:t_fin
    %Constants: in, oz
    l_0 = 1.9; %Free cable length - used to be 1.4
    l_max = 2.4; %Max stretched cable length
    k = 0.44; %Stiffness coefficient - used to be 2
    r_t = [-2, -0.786, 0, 1;... %Distance to two tendon paths (forces f_t)
        2, -0.786 0 1]';
    r_m = [0 0.689 0 1]'; %Distance to connection point (force f_m)
    %CoM = [2.125, 1.186, 0.15];
    r = 1.21875; %Just added this - unsure if correct
    CoM = [0, 0.786, 0];
    m = 2.232; %Arc mass
    %m = 2232;
    m1 = m*eye(3); %Mass matrix
%     Ib = [3.143 0 6.15E-5;... %Moment of inertia matrix
%         0 4.078 0;...
%         6.15E-5 0 0.969];
     Ib = [((r^2)*m)/2 0 0;... %Moment of inertia matrix updated
         0 ((r^2)*m)/2 0;...
         0 0 ((r^2)*m)];
    %Gb = [Ib zeros(3); zeros(3) m1]; %Spatial inertial matrix
    Gb = [Ib m*LieGroup.vec2so3(CoM); -m*LieGroup.vec2so3(CoM) m1]; %Spatial inertial matrix
%      P = [-1.5, -0.786, 0, 1;... % Positions of nodes on arc1
%          -0.95, 0.264, 0, 1;...
%          0.95, 0.264, 0, 1;... 
%          1.5, -0.786, 0, 1]';

    P = [-1.1875, 0, 0, 1;
            -0.6, -1.025, 0, 1;
            0.6, -1.025, 0, 1; 
            1.1875, 0, 0, 1]';
    
    % Connectivity matrix components connecting nodes from arc1 to arc2
    C1 = [1 1 1 1 0 0 0 0 0 0 0 0;...
        0 0 0 0 1 1 0 0 0 0 0 0;...
        0 0 0 0 0 0 1 1 0 0 0 0;...
        0 0 0 0 0 0 0 0 1 1 1 1];
    C2 = [1 0 0 0 1 0 1 0 1 0 0 0;...
        0 1 0 0 0 0 0 0 0 1 0 0;...
        0 0 1 0 0 0 0 0 0 0 1 0;...
        0 0 0 1 0 1 0 1 0 0 0 1];

    if j == 0
        Xi = X0(1)*[X0(2:4)',X0(5:7)']'; % theta*[omega', v']' Initial body screw
        V = Xi*0; %Initial body twist
        Tminus = LieGroup.TMatExponential3(X0(2:4),X0(1),X0(5:7)); %Initial T12
        T = Tminus*expm(LieGroup.vec2se3(V).*j);
        Ts = [T(1:4), T(5:8), T(9:12), T(13:16)];
    else
        V = (Vbdot.*j - Vbdot.*(j-t_inc));
        %T = logm(expm(Tminus)*expm(LieGroup.vec2se3(V).*j - LieGroup.vec2se3(V).*(j-t_inc)));
        T = Tminus*expm(LieGroup.vec2se3(V).*j - LieGroup.vec2se3(V).*(j-t_inc));
        Ts = [Ts; T(1:4), T(5:8), T(9:12), T(13:16)];
    end
    
    Tminus = T; %Reset Tminus for next loop

    S1 = (P*C1)-(T*P*C2); %Calculate 12 cable segment lengths dependent on T_12
    r_s1 = P*C1; %Distance to each cable with respect to time
    r_sT = T*P*C2;

    %Calculate f_s (12 string forces)
    for b = 1:length(S1)
        l_j(b) = norm(S1(:,b));
        if l_j(b) < l_0
            f_sj(b) = 0;
        elseif l_j(b) > l_max
            f_sj(b) = k*(l_j(b)-l_0);
            S1(:,b) = S1(:,b)*l_max/l_j(b);
        else
            f_sj(b) = k*(l_j(b)-l_0);
        end
        F_s(:,b) = S1(:,b)*f_sj(b);
    end
    
    %Calculate M_s (12 string moments)
    for i = 1:length(F_s)
        M_s(:,i) = cross(r_s1(1:3,i), F_s(1:3,i));
    end
    
    %Calculate M_t (2 tendon moments
    for k = 1:length(F_t(1,:))
        M_t(:,k) = cross(r_t(1:3,k), F_t(:,k)); 
    end
    
    SF = sum(F_s(1:3,:),2)+sum(F_t,2) + F_m; %Sum of forces acting on body
    SM = sum(M_s,2) + sum(M_t,2) + cross(r_m(1:3,:), F_m); %Sum of moments acting on body
    Wrench = [SM; SF] %Body wrench
    Vbdot = inv(Gb)*Wrench + inv(Gb)*LieGroup.Adjoint6(V)'*Gb*V %Previous state representation solving for body twist dot
end
end