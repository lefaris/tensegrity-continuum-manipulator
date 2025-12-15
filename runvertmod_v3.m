% Vertebra Dynamic Modelings

%
clc;clear;
R = [0, 0, 1;...
    0, -1, 0;...
    1, 0, 0];
% p is only translation in y-direction, recessed 3/4 in
p = [0, -0.75, 0]';
T = [R, p;...
    0, 0, 0, 1];
% T = inv(T);
[omega,theta,v] = EquivalentScrew3(T);
%omega = omega + randn(3,1); % Commented this - why add randomness here?
omega = omega/norm(omega);

Xi_0 = theta*[omega', v']';
V_0 = Xi_0*0;
%
F_t(:,1) = [0,-5, 0]'; %tendon 1
F_t(:,2) = [0,-2, 0]'; %tendon 2
F_m = zeros(3,1);
F_t = zeros(3,2);

%CHANGEME Appended initial T_0 of all zeros
X0 = [Xi_0',V_0', T(1,1:4),T(2,1:4),T(3,1:4),T(4,1:4)]';

% Modify X0 to include 

[t, Xvals] = ode45(@(t, X) vertmod_v3(t, X, F_t, F_m), [0 0.5], X0); 

Xis = Xvals(:,1:6);
Vs =Xvals(:,7:12);

% plot(t,Xis(:,3))
% legend('1','2','3','4','5','6')

P1 = [-1.5, -0.786, 0, 1;...
    -0.95, 0.264, 0, 1;...
    0.95, 0.264, 0, 1;... 
    1.5, -0.786, 0, 1]';


%
figure
plot3(P1(1,:), P1(2,:), P1(3,:),'LineWidth',4)
hold on
for i = 1:length(Xis)
    TMatB = screw2TMat(Xi_0);
    P2_0 = TMatB*P1;
    plot3(P2_0(1,:), P2_0(2,:), P2_0(3,:),'LineWidth',8)
    hold on
    TMatB = screw2TMat(Xis(i,:)');
    P2 = TMatB*P1;
    plot3(P2(1,:), P2(2,:), P2(3,:))
    hold on    
    

end



