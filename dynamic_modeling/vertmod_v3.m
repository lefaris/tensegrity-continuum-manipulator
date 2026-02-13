% ======== Vertebrae Dynamic Modeling ========
% 
% Input: 
% t - time (sec)
% X [12 x 1] - state vector is the body screw and the body velocity
% F_t [3 x 1] - 
% F_m [3 x 1]
% Author: Cole Woods (cswoods@crimson.ua.edu)
function [dVdt] = vertmod_v3(t, X, F_t, F_m)
% The goal of this function is to define a single Vertebra
% Constants, in, oz
Xi = X(1:6);
V = X(7:12);

%CHANGEME Adding T_t-1
Tminus = [X(13:16)'; X(17:20)'; X(21:24)'; X(25:28)'];
XiHat = log(Tminus)

l_0 = 1.4;
l_max = 2.4;
k = 2;
c = 0.1;
r_t = [-2, -0.786, 0, 1;...
    2, -0.786 0 1]';
r_m = [0 0.689 0 1]';
CoM = [2.125, 1.186, 0.15];
m = 2.232;
m1 = m*eye(3);
Ib = [3.143 0 6.15E-5;...
    0 4.078 0;...
    6.15E-5 0 0.969];
Gb = [Ib zeros(3); zeros(3) m1];

% The positions of the nodes [4x(no of nodes)]
% In this case: [4x4]
P = [-1.5, -0.786, 0, 1;...
    -0.95, 0.264, 0, 1;...
    0.95, 0.264, 0, 1;... 
    1.5, -0.786, 0, 1]';

% Connectivity matrix components
% Ca: connecting nodes on {a} [(no of nodes)x(no of connections)]
% Cb: connecting nodes on {b} [(no of nodes)x(no of connections)]
% In this case: [4x12]
Ca = [1 1 1 1 0 0 0 0 0 0 0 0;...
    0 0 0 0 1 1 0 0 0 0 0 0;...
    0 0 0 0 0 0 1 1 0 0 0 0;...
    0 0 0 0 0 0 0 0 1 1 1 1];
Cb = [1 0 0 0 1 0 1 0 1 0 0 0;...
    0 1 0 0 0 0 0 0 0 1 0 0;...
    0 0 1 0 0 0 0 0 0 0 1 0;...
    0 0 0 1 0 1 0 1 0 0 0 1];

% Transformation matrix between {a} and {b}

%CHANGEME Adding previous T value
%T = Tminus*screw2TMat(Xi);
%[omega,theta,v] = EquivalentScrew3(T);

%Changing screw to Vb, need to add something else I think
%T = Tminus*vec2SE3(V);
if t == 0
    T = Tminus;
else
    T = Tminus.*expm(XiHat);
    %T = Tminus.*expm(vec2SE3(V).*t - vec2SE3(V).*(t-1));
end

%T = screw2TMat(Xi);
S1 = (P*Ca-T*P*Cb);
% S = P*Cb-T*P*Ca;
Tdot = T*vec2SE3(V);
Sdot = Tdot*P*Cb;


for j = 1:length(S1)
    l_j(j) = norm(S1(:,j));
    if l_j(j) < l_0
        f_sj(j) = 0;
    elseif l_j(j) > l_max
        f_sj(j) = k*(l_j(j)-l_0);
        S1(:,j) = S1(:,j)*l_max/l_j(j);
    else
        f_sj(j) = k*(l_j(j)-l_0);
    end
    F_s(:,j) = S1(:,j)*f_sj(j);
end

r_s1 = P*Ca;

%Adding this because something is wrong
r_sT = T*P*Cb;

for i = 1:length(F_s)
    M_s(:,i) = cross(r_s1(1:3,i), F_s(1:3,i));
end
for i = 1:length(F_t(1,:))
    M_t(:,i) = cross(r_t(1:3,i), F_t(:,i)); 

SF = sum(F_s(1:3,:),2)+sum(F_t,2) + F_m;
SM = sum(M_s,2) + sum(M_t,2) + cross(r_m(1:3,:), F_m);
Wrench = [SM; SF]

u = [zeros(6,1);inv(Gb)*Wrench];
A = [zeros(6) eye(6);
    zeros(6) inv(Gb)*Adjoint6(V)'*Gb];


%CHANGEME: modifying the return value to add T_t-1
%dVdt = A*[Xi;V]+u; %<- This was the previous return
y = A*[Xi;V]+u;
%dVdt = [y; T(1,1); T(1,2); T(1,3); T(1,4); T(2,1); T(2,2); T(2,3); T(2,4); T(3,1); T(3,2); T(3,3); T(3,4); T(4,1); T(4,2); T(4,3); T(4,4)];
dVdt = [y; T(1,1:4)';T(2,1:4)';T(3,1:4)';T(4,1:4)'];


end