% Agile Robotics Laboratory  at UA
% Date: 10/04/2024
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

function [dVdt] = dynMan(t, X, F_t, F_m)
Xi = X(1:6);
V = X(7:12);
Tminus = [X(13:16)'; X(17:20)'; X(21:24)'; X(25:28)']; %Adding T_t-1
XiHat = log(Tminus) %This results in convergence, but there are NaN values
%        for the body screw and wrench
%XiHat = logm(Tminus) %This makes arc2 diverge

%Constants, in, oz
l_0 = 1.4; %Free cable length
l_max = 2.4; %Max stretched cable length
k = 2; %Stiffness coefficient



r_t = [-2, -0.786, 0, 1;... %Distance to two tendon paths (forces f_t)
    2, -0.786 0 1]';
r_m = [0 0.689 0 1]'; %Distance to connection point (force f_m)



m = 2.232; %Arc mass
m1 = m*eye(3); %Mass matrix
Ib = [3.143 0 6.15E-5;... %Moment of inertia matrix
    0 4.078 0;...
    6.15E-5 0 0.969];
Gb = [Ib zeros(3); zeros(3) m1]; %Spatial inertial matrix
P = [-1.5, -0.786, 0, 1;... % Positions of nodes on arc1
    -0.95, 0.264, 0, 1;...
    0.95, 0.264, 0, 1;... 
    1.5, -0.786, 0, 1]';

% Connectivity matrix components connecting nodes from arc1 to arc2
C1 = [1 1 1 1 0 0 0 0 0 0 0 0;...
    0 0 0 0 1 1 0 0 0 0 0 0;...
    0 0 0 0 0 0 1 1 0 0 0 0;...
    0 0 0 0 0 0 0 0 1 1 1 1];
C2 = [1 0 0 0 1 0 1 0 1 0 0 0;...
    0 1 0 0 0 0 0 0 0 1 0 0;...
    0 0 1 0 0 0 0 0 0 0 1 0;...
    0 0 0 1 0 1 0 1 0 0 0 1];

%Calculate T_12 using T_12(t-1)
if t(end) == 0
    T = Tminus; %Return the T_12 input for the first iteration
else
    T = Tminus*expm(XiHat); %We're getting complex values in the wrench
    %Different attempts for calculating T_12 and their results:
    %T = Tminus*exp(XiHat); %This makes arc2 diverge and takes forever
    %T = Tminus*expm(vec2SE3(V)); %This makes arc2 diverge
    %T = Tminus.*expm(vec2SE3(V).*t - vec2SE3(V).*(t-1)); %This makes arc2 diverge
    %T = Tminus*vec2SE3(V); %This makes arc2 diverge and squish
    %T = screw2TMat(Xi); %This makes arc2 diverge
    %T = Tminus*screw2TMat(Xi); %Arc2 still diverges
end

S1 = (P*C1-T*P*C2); %Calculate 12 cable segment lengths dependent on T_12
r_s1 = P*C1; %Distance to each cable with respect to time

%Calculate f_s (12 string forces)
for j = 1:length(S1)
    l_j(j) = norm(S1(:,j));
    if l_j(j) < l_0
        f_sj(j) = 0;
    elseif l_j(j) > l_max %Do we need this?  I don't think so
        f_sj(j) = k*(l_j(j)-l_0);
        S1(:,j) = S1(:,j)*l_max/l_j(j); 
    else
        f_sj(j) = k*(l_j(j)-l_0);
    end
    F_s(:,j) = S1(:,j)*f_sj(j);
end

%Calculate M_s (12 string moments)
for i = 1:length(F_s)
    M_s(:,i) = cross(r_s1(1:3,i), F_s(1:3,i));
end

%Calculate M_t (2 tendon moments
for i = 1:length(F_t(1,:))
    M_t(:,i) = cross(r_t(1:3,i), F_t(:,i)); 
end

SF = sum(F_s(1:3,:),2)+sum(F_t,2) + F_m; %Sum of forces acting on body
SM = sum(M_s,2) + sum(M_t,2) + cross(r_m(1:3,:), F_m); %Sum of moments acting on body
Wrench = [SM; SF] %Body wrench

%Previous state representation solving for both body twist and body twist
%dot, changed to calculate for only body twist dot
u = [zeros(6,1);inv(Gb)*Wrench];
A = [zeros(6) eye(6);
    zeros(6) inv(Gb)*Adjoint6(V)'*Gb];
y = A*[Xi;V]+u;

dVdt = [y; T(1,1:4)';T(2,1:4)';T(3,1:4)';T(4,1:4)'];
end