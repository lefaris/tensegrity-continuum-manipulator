function [Ts] = customIntegral(prev_T, F_t, F_m, t_inc, t_fin, X0)

for i=0:t_inc:t_fin
    %Constants: in, oz
    l_0 = 1.4; %Free cable length
    l_max = 2.4; %Max stretched cable length
    k = 2; %Stiffness coefficient
    r_t = [-2, -0.786, 0, 1;... %Distance to two tendon paths (forces f_t)
        2, -0.786 0 1]';
    r_m = [0 0.689 0 1]'; %Distance to connection point (force f_m)
    %CoM = [2.125, 1.186, 0.15];
    CoM = [0, 0.786, 0];
    m = 2.232; %Arc mass
    m1 = m*eye(3); %Mass matrix
    Ib = [3.143 0 6.15E-5;... %Moment of inertia matrix
        0 4.078 0;...
        6.15E-5 0 0.969];
    %Gb = [Ib zeros(3); zeros(3) m1]; %Spatial inertial matrix
    Gb = [Ib m*vec2so3(CoM); -m*vec2so3(CoM) m1]; %Spatial inertial matrix
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

    if i == 0
        Xi = X0(1:6);
        V = X0(7:12);
        Tmin = [prev_T(1:4), prev_T(5:8), prev_T(9:12), prev_T(13:16)]; %Adding T_t-1
        Tminus = reshape(Tmin,[4,4]);
        T = Tminus*expm(vec2SE3(V).*i);
        Ts = T;
    else
        %Xi = 
        V = int(Vbdot)
        T = Tminus.*expm(vec2SE3(V).*i - vec2SE3(V).*(i-1));
        Ts(end+1) = T;
    end
    
    Tminus = T; %Reset Tminus for next loop

    S1 = (P*C1-T*P*C2); %Calculate 12 cable segment lengths dependent on T_12
    r_s1 = P*C1; %Distance to each cable with respect to time
    
    %Calculate f_s (12 string forces)
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
    Vb_Vbdot = A*[Xi;V]+u;
    Vbdot = inv(Gb)*Wrench + inv(Gb)*Adjoint6(V)'*Gb*V;
    
    %dVdt = [y];
    %dVdt = [Vb_Vbdot; T(1,1:4)';T(2,1:4)';T(3,1:4)';T(4,1:4)']
end
end