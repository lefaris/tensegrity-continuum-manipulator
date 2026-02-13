% Agile Robotics Laboratory at UA
% Date: 03/20/2025
%
% Input: 
% Modifiable inputs consist of the parameters shown below in the
% ------USER INPUTS------ section.  These include the starting orientation,
% physical properties of the primitive, external forces, and time to run
% the functions for.
%
% Note: F_s (string friction) is not given as an input - it is calculated 
%       and dependent on the changing T_12 with time
%
% Output:
% T_12s for a given time interval are calculated from body twists, body
% wrenches, and other variables.  The resulting T_12s plot how the
% primitive orientation varies with time from a given set of input
% parameters and internal properties.


clc;
clear;


%------USER INPUTS------
R0 = [0, 0, 1;... %Initial rotation matrix between two arcs:
     0, -1, 0;... %180 by X and 90 by Y
     1, 0, 0];
% R0 = [-0.5, 0, 0.8660254;... %Initial rotation matrix between two arcs:
%     0, -1, 0;... %180 by X and 120 by Y
%     0.8660254, 0, 0.5];
p0 = [0, -0.75, 0]'; %Initial translation between two arcs - recessed 3/4"

r = 1.2; %Arc radius
m = 2.232; %Arc mass

l_0 = 1.9; %Free cable length - used to be 1.4
l_max = 2.4; %Max stretched cable length
k = 0.22; %Stiffness coefficient - used to be 0.44

F_m = zeros(3,1); %Set connection force between two vertebra to zero for now
F_t = zeros(3,2); %Set tendon forces to zero for now
r_t = [-2, -0.786, 0, 1;... %Distance to two tendon paths (forces f_t)
       2, -0.786 0 1]';
r_m = [0 0.689 0 1]'; %Distance to connection point (force f_m)

t_inc = 0.1; %Time increment
t_fin = 100; %Final time to run for
%--------------------




%------Initialize Remaining Variables------
T = [R0, p0;... %Initial transformation matrix
    0, 0, 0, 1];
[omega,theta,v] = LieGroup.EquivalentScrew3(T); %Initial omega, theta, & v from T
omega = omega/norm(omega);

m1 = m*eye(3); %Mass matrix
CoM = [0, (2*r)/pi, 0]; %Center of mass of one arc
Ib = [((r^2)*m)/2 0 0;... %Moment of inertia matrix updated
      0 ((r^2)*m)/2 0;...
      0 0 ((r^2)*m)];
% Ib = [(m*(r^2)*(pi^2 - 8))/(2*(pi^2)) 0 0;... %Moment of inertia matrix updated
%       0 ((r^2)*m)/2 0;...
%       0 0 (m*(r^2)*(pi^2 - 4))/(pi^2)];
Gb = [Ib m*LieGroup.vec2so3(CoM); -m*LieGroup.vec2so3(CoM) m1]; %Spatial inertial matrix

P = [-r, 0, 0, 1;... %Node positions along arc from base
     -r/2, (-sqrt(3)*r)/2, 0, 1;...
     r/2, (-sqrt(3)*r)/2, 0, 1;...
     r, 0, 0, 1]';
Pb = P - repmat([CoM'; 0],1,4); %Node positions from CoM instead of base - important!

C1 = [1 1 1 1 0 0 0 0 0 0 0 0;... %Connectivity matrices connecting nodes from arc1 to arc2
    0 0 0 0 1 1 0 0 0 0 0 0;...
    0 0 0 0 0 0 1 1 0 0 0 0;...
    0 0 0 0 0 0 0 0 1 1 1 1];
C2 = [1 0 0 0 1 0 1 0 1 0 0 0;...
    0 1 0 0 0 0 0 0 0 1 0 0;...
    0 0 1 0 0 0 0 0 0 0 1 0;...
    0 0 0 1 0 1 0 1 0 0 0 1];
%----------------------------------------




[Ts] = dynamics(F_t, F_m, t_inc, t_fin, omega, theta, v, l_0, l_max, k, r_t, r_m, Pb, Gb, C1, C2); %Solve dynamics
plotPrimitive(Ts, P, omega, theta, v); %Plot




function [Ts] = dynamics(F_t, F_m, t_inc, t_fin, omega, theta, v, l_0, l_max, k, r_t, r_m, Pb, Gb, C1, C2)

    %------Function Description------
    % This function calculates initial body screw Xi, body twist V, and
    % transformation matrix T12 based off initial omega, theta, and v.
    %
    % Then, initial cable segment lengths S are found and fed into the 
    % bodyWrench function to calculate the wrench. This is then fed into
    % the dynVbdot function to calculate Vbdot. 
    %
    % In the subsequent loops, V is calculated from the previous Vbdot and
    % T12 is calculated from the previous T12 and integrated V.
    %-------------------------------


    Ts = zeros(100000,16); %Preallocating here since this will grow
    for j=0:t_inc:t_fin
        if j == 0
            Xi = theta*[omega',v']'; %Initial body screw
            V = Xi*0; %Initial body twist
            Tminus = LieGroup.TMatExponential3(omega,theta,v); %Initial T12
            T = Tminus*expm(LieGroup.vec2se3(V).*j);
            Ts = [T(1:4), T(5:8), T(9:12), T(13:16)];
        else
            V = (Vbdot.*j - Vbdot.*(j-t_inc)); %Body twist each iteration
            T = Tminus*expm(LieGroup.vec2se3(V).*j - LieGroup.vec2se3(V).*(j-t_inc)) %T12 each iteration
            Ts = [Ts; T(1:4), T(5:8), T(9:12), T(13:16)]; %Saving all T12s for plotting later
        end

        Tminus = T; %Reset Tminus for next loop
        S = (Pb*C1)-(T*Pb*C2); %Calculate 12 cable segment lengths dependent on T_12
        Sb = inv(T)*S; %Changing cable segment lengths to be in "{b}" on {2}
        r_s1 = Pb*C1; %Distance to each cable with respect to time
        r_s2 = Pb*C2;

        Wrench = bodyWrench(F_t, r_t, F_m, r_m, r_s2, Sb, l_0, l_max, k); %Calculate body wrench
        Vbdot = dynVbdot(Wrench, Gb, V); %Calculate Vbdot
    end
end




function Wrench = bodyWrench(F_t, r_t, F_m, r_m, r_s2, Sb, l_0, l_max, k)

    %------Function Description------
    % This function calculates the string and tendon forces and moments.
    %
    % The string forces at a given time period are calculated from Sb, the
    % free cable segment length l_0, the max cable segment length l_max,
    % and the stiffness coefficient k.
    %
    % Note that initially the tendon and connection point forces are zero.
    %-------------------------------
    
    for b = 1:length(Sb) %Calculate F_s (12 string forces)
        l_j(b) = norm(Sb(:,b));
        if l_j(b) < l_0
            f_sj(b) = 0;
        elseif l_j(b) > l_max
            f_sj(b) = (k*(l_j(b)-l_0))/l_j(b);
            Sb(:,b) = Sb(:,b)*l_max/l_j(b);
        else
            f_sj(b) = (k*(l_j(b)-l_0))/l_j(b);
        end
        F_s(:,b) = Sb(:,b)*f_sj(b);
    end
    
    for i = 1:length(F_s) %Calculate M_s (12 string moments)
        M_s(:,i) = cross(r_s2(1:3,i), F_s(1:3,i));
    end

    for a = 1:length(F_t(1,:)) %Calculate M_t (2 tendon moments)
        M_t(:,a) = cross(r_t(1:3,a), F_t(:,a));
    end
    
    SF = sum(F_s(1:3,:),2) + sum(F_t,2) + F_m; %Sum of forces acting on body
    SM = sum(M_s,2) + sum(M_t,2) + cross(r_m(1:3,:), F_m); %Sum of moments acting on body
    Wrench = [SM; SF] %Body wrench
end




function Vbdot = dynVbdot(Wrench, Gb, V)

    %------Function Description------
    % This function calculates Vbdot from Gb, V, and Wrench. The resulting
    % Vbdot is integrated and used to calculate V for time t + delta.
    %-------------------------------
    
    Vbdot = inv(Gb) * Wrench + inv(Gb) * LieGroup.Adjoint6(V)' * Gb * V;
end




function plotPrimitive(Ts, P, omega, theta, v)

    %------Function Description------
    % This function plots the two initial curved arcs (from node positions)
    % with greater thickness.  Then, the second arc is plotted from
    % calculated T12s for every time increment in the dynamics function.
    %
    % This shows how a single primitive varies with time for a given set of
    % input parameters (i.e. unstable starting orientation or applied
    % external forces).
    %-------------------------------
    
    figure;
    plot3(P(1,:), P(2,:), P(3,:), 'LineWidth', 4); % Arc1
    hold on;
    TMatB = LieGroup.TMatExponential3(omega,theta,v);
    arc2_0 = TMatB*P;
    plot3(arc2_0(1,:), arc2_0(2,:), arc2_0(3,:),'LineWidth',8) %Initial arc2
    hold on
    
    for i = 1:length(Ts)
        TMatB = reshape(Ts(i,:), [4, 4]);
        arc2 = TMatB * P;
        plot3(arc2(1,:), arc2(2,:), arc2(3,:)); % Changing arc2 position
        hold on;
    end
    
    hold off;
end