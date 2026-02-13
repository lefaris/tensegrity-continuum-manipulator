% Lauren Ervin
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
% wrenches, and other variables.  Four plots show how different variables
% change over time:
% (1) Twelve cable segment lengths 
% (2) Six body wrench components
% (3) Robot orientation with each previous orientation overlain
% (4) Prettier final robot orientation with accompanying video


clc;
clear;

%------USER INPUTS------
%Stable orientation is x rotated by 180, then y rotated by 90
% Note: will need to change omega1,2 and theta1,2 to additional variables
% if attempting to change starting orientation as subsequent primitives are
% now dependent on the static relationship below
omega1 = [1,0,0]; %First rotation axis e.g. x axis = [1,0,0]
theta1 = pi; %First rotation angle
omega2 = [0,1,0]; %Second rotation axis
%theta2 = 2*pi/3; %Second rotation angle
theta2 = -pi/2; %Second rotation angle
theta3 = 2*pi/3; %Second rotation angle

r = 1.2; %Arc radius
m = 2.232; %Arc mass

p0 = [0,-0.5,0]; %Initial translation between two arcs - recessed 3/4"
p1 = [0,r,0]; %Initial translation between arc 3 fixed to arc 2
p2 = [0, 5*r/2, 0]; %Initial translation between arc 3 and 4


l_0 = 1.4; %Free cable length - used to be 1.4
l_max = 2.4; %Max stretched cable length - used to be 2.4
k = 0.44; %Stiffness coefficient - used to be 0.44
d = 0.6; %%%%%%%%Damping coefficient - test feature

F_m = zeros(3,1); %Set connection force between two vertebra to zero for now
%F_t = zeros(3,2); %Set tendon forces to zero for now
F_t = [0.2,0;0,0;0,0]; %Set tendon forces
r_t = [-2, -0.786, 0, 1;... %Distance to two tendon paths (forces f_t)
       2, -0.786 0 1]';
r_m = [0 0.689 0 1]'; %Distance to connection point (force f_m)

t_inc = 0.2; %Time increment
t_fin = 200; %Final time to run for

video_title = "MBS3.mp4"; %Update with descriptive title and make sure not to overwrite previous video
%--------------------




%------Initialize Remaining Variables------
R1 = LieGroup.MatExponential3(omega1',theta1); %Get rotation matrix from first rotation
R2 = R1*LieGroup.MatExponential3(omega2',theta2); %Get rotation matrix from second rotation
R3 = R1*LieGroup.MatExponential3(omega2',theta2); %Get rotation matrix from second rotation
T = [R2, p0'; zeros(1,3), 1]; %Initial transformation matrix b/n arcs 1 and 2
Tvert2 = [R3, p1'; zeros(1,3), 1]; %Initial transformation matrix b/n arcs 2 and 3
Tvert3 = [R2, p2'; zeros(1,3), 1]; %Initial transformation matrix b/n arcs 3 and 4

[omega,theta,v] = LieGroup.EquivalentScrew3(T); %Initial omega, theta, & v from T
omega = omega/norm(omega);

m1 = m*eye(3); %Mass matrix
CoM = [0, (2*r)/pi, 0]; %Center of mass of one arc
Ib = [((r^2)*m)/2 0 0;... %Moment of inertia matrix updated
      0 ((r^2)*m)/2 0;...
      0 0 ((r^2)*m)];
Gb = [Ib m*LieGroup.vec2so3(CoM); -m*LieGroup.vec2so3(CoM) m1]; %Spatial inertial matrix

P = [-r, 0, 0, 1;... %Node positions along arc from base
     -r/2, (-sqrt(3)*r)/2, 0, 1;...
     r/2, (-sqrt(3)*r)/2, 0, 1;...
     r, 0, 0, 1]';
%Pb = P - repmat([CoM'; 0],1,4); %Node positions from CoM instead of base - important!
Pb = P; %When I use the commented Pb above, the two arcs reach equilibrium much closer together (nearly touching)
C1 = [1 1 1 1 0 0 0 0 0 0 0 0;... %Connectivity matrices connecting nodes from arc1 to arc2
    0 0 0 0 1 1 0 0 0 0 0 0;...
    0 0 0 0 0 0 1 1 0 0 0 0;...
    0 0 0 0 0 0 0 0 1 1 1 1];
C2 = [1 0 0 0 1 0 1 0 1 0 0 0;...
    0 1 0 0 0 0 0 0 0 1 0 0;...
    0 0 1 0 0 0 0 0 0 0 1 0;...
    0 0 0 1 0 1 0 1 0 0 0 1];
%----------------------------------------




[Ts, T3s, stringLengths, Wrenches] = dynamics(F_t, F_m, t_inc, t_fin, omega, theta, v, l_0, l_max, k, d, r_t, r_m, Pb, Gb, C1, C2, Tvert2, Tvert3, r); %Solve dynamics
plotCables(stringLengths, l_max, l_0); %Plot twelve cable segment lengths with time
plotWrench(Wrenches); %Plot sum of moments and forces with time
plotPrimitive(Ts, P, omega, theta, v, Tvert2, Tvert3, T3s); %Plot two arc relations to one another over time
plotPrimitiveCurved(Ts, P, r, CoM, video_title, Tvert2, Tvert3, T3s); %Dr. V's animated plot code (modified to create a video)



function [Ts, T3s, stringLengths, Wrenches] = dynamics(F_t, F_m, t_inc, t_fin, omega, theta, v, l_0, l_max, k, d, r_t, r_m, Pb, Gb, C1, C2, Tvert2, Tvert3, r)

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
            V3 = [0;0;0;0;0;0]; %Initial V2 - unsure about this
            Tminus = LieGroup.TMatExponential3(omega,theta,v); %Initial T12
            T = Tminus*expm(LieGroup.vec2se3(V).*j);
            Ts = [T(1:4), T(5:8), T(9:12), T(13:16)];
            %T2 = Tvert2*T; %Initial T23
            %T2s = [T2(1:4), T2(5:8), T2(9:12), T2(13:16)];
            T3 = Tvert3;%*T2; %Initial T34
            T3s = [T3(1:4), T3(5:8), T3(9:12), T3(13:16)];
            count = 1;
            Wrenches = [];
            stringLengths = [];
        else
            V = (Vbdot.*j - Vbdot.*(j-t_inc)); %Body twist each iteration
            V3 = (Vbdot3.*j - Vbdot3.*(j-t_inc)); %Body twist for primitive 2 at each iteration - ???
 %           T = Tminus*expm(LieGroup.vec2se3(V).*j - LieGroup.vec2se3(V).*(j-t_inc)) %T12 each iteration
            T = Tminus*expm(LieGroup.vec2se3(V).*t_inc) %T12 each iteration
            Ts = [Ts; T(1:4), T(5:8), T(9:12), T(13:16)]; %Saving all T12s for plotting later
            T3 = T3minus*expm(LieGroup.vec2se3(V3).*t_inc) %T12 each iteration
            T3s = [T3s; T3(1:4), T3(5:8), T3(9:12), T3(13:16)]; %Saving all T12s for plotting later
            count = count + 1;
        end

        Tminus = T; %Reset Tminus for next loop
        T3minus = T3; %Reset T3minus for next loop
        S = (Pb*C1)-(T*Pb*C2); %Calculate 12 cable segment lengths dependent on T_12
        Sb = inv(T)*S; %Changing cable segment lengths to be in "{b}" on {2}
        Sbdot = T*LieGroup.vec2se3(V)*S; %%%%%Adding for damping

        S3 = (Pb*C1)-(T3*Pb*C2); %Calculate 12 cable segment lengths dependent on T_12
        S3b = inv(T3)*S; %Changing cable segment lengths to be in "{b}" on {2}
        S3bdot = T3*LieGroup.vec2se3(V3)*S3; %%%%%Adding for damping
        % S3 = T3*S; %Calculate 12 cable segment lengths dependent on T_12
        % S3b = inv(T3)*S3; %Changing cable segment lengths to be in "{b}" on {2}
        % S3bdot = T3*LieGroup.vec2se3(V3)*S3; %%%%%Adding for damping
        %Sbdot = T*LieGroup.vec2se3(V)*Pb*C2; %%%%%This makes the movement very bouncy
        
        r_s1 = Pb*C1; %Distance to each cable with respect to time
        r_s2 = Pb*C2;

        [Wrench, Wrench3, Wrenches, stringLengths] = bodyWrench(F_t, r_t, F_m, r_m, r_s2, Sb, l_0, l_max, k, d, count, Wrenches, stringLengths, Sbdot, S3b, S3bdot, r); %Calculate body wrench
        %Vbdot = dynVbdot(Wrench, Gb, V); %Calculate Vbdot
        [Vbdot, Vbdot3] = dynVbdot(Wrench, Wrench3, Gb, V, V3);
        
        
        
    end
end




function [Wrench, Wrench3, Wrenches, stringLengths] = bodyWrench(F_t, r_t, F_m, r_m, r_s2, Sb, l_0, l_max, k, d, count, Wrenches, stringLengths, Sbdot, S3b, S3bdot, r)

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
        sdot_j(b) = norm(Sbdot(:,b));

        l3_j(b) = norm(S3b(:,b));
        s3dot_j(b) = norm(S3bdot(:,b));
        if l_j(b) < l_0
            f_sj(b) = 0;
            d_sj(b) = 0; %Damping component
        elseif l_j(b) > l_max
             f_sj(b) = (k*(l_j(b)-l_0))/l_j(b);
            %f_sj(b) = (k*(l_j(b)-l_0));
            Sb(:,b) = Sb(:,b)*l_max/l_j(b);
        else
             f_sj(b) = (k*(l_j(b)-l_0))/l_j(b);
             %d_sj(b) = (d*sdot_j(b))/l_j(b);
             d_sj(b) = d*sdot_j(b);
             
             %d_sj(b) = (d*sdot_j(:,b))/Sb(:,b);
            %f_sj(b) = (k*(l_j(b)-l_0));
        end

        if l3_j(b) < l_0
            f3_sj(b) = 0;
            d3_sj(b) = 0; %Damping component
        elseif l3_j(b) > l_max
             f3_sj(b) = (k*(l3_j(b)-l_0))/l3_j(b);
             d3_sj(b) = 0; %Damping component
            %f_sj(b) = (k*(l_j(b)-l_0));
            S3b(:,b) = S3b(:,b)*l_max/l3_j(b);
        else
             f3_sj(b) = (k*(l3_j(b)-l_0))/l3_j(b);
             %d_sj(b) = (d*sdot_j(b))/l_j(b);
             d3_sj(b) = d*s3dot_j(b);
             
             %d_sj(b) = (d*sdot_j(:,b))/Sb(:,b);
            %f_sj(b) = (k*(l_j(b)-l_0));
        end

        F_s(:,b) = Sb(:,b)*f_sj(b); %Calculate F_s (12 string forces)
        %F_s(:,b) = Sb(:,b)*(f_sj(b) + d_sj(b)); %%%%%%%% Modifying to add damping data
        stringLengths(count,b) = l_j(b); %Save each cable segment length
        M_s(:,b) = cross(r_s2(1:3,b), F_s(1:3,b)); %Calculate M_s (12 string moments)

        F3_s(:,b) = S3b(:,b)*f3_sj(b);
        %F3_s(:,b) = S3b(:,b)*(f3_sj(b) + d3_sj(b)); %%%%%%%% Modifying to add damping data
        M3_s(:,b) = cross(r_s2(1:3,b), F3_s(1:3,b)); %Calculate M_s (12 string moments)
    end

    for a = 1:length(F_t(1,:)) 
        M_t(:,a) = cross(r_t(1:3,a), F_t(:,a)); %Calculate M_t (2 tendon moments)
    end
    
    SF = sum(F_s(1:3,:),2) + sum(F_t,2) + F_m; %Sum of forces acting on body
    SM = sum(M_s,2) + sum(M_t,2) + cross(r_m(1:3,:), F_m); %Sum of moments acting on body
    Wrench = [SM; SF] %Body wrench
    Wrenches(count,1:6) = Wrench'; %Save all body wrenches for plotting purposes

    S3F = sum(F3_s(1:3,:),2) + sum(F_t,2) + F_m; %Sum of forces acting on body
    S3M = sum(M3_s,2) + sum(M_t,2) + cross(r_m(1:3,:), F_m); %Sum of moments acting on body
    Wrench3 = [S3M; S3F] %Body wrench
end




function [Vbdot, Vbdot3] = dynVbdot(Wrench, Wrench3, Gb, V, V3)

    %------Function Description------
    % This function calculates Vbdot from Gb, V, and Wrench. The resulting
    % Vbdot is integrated and used to calculate V for time t + delta.
    %-------------------------------
    
    Vbdot = inv(Gb) * Wrench + inv(Gb) * LieGroup.Adjoint6(V)' * Gb * V;
    Vbdot3 = inv(Gb) * Wrench3 + inv(Gb) * LieGroup.Adjoint6(V3)' * Gb * V3;
end




function plotCables(stringLengths, l_max, l_0)

    %------Function Description------
    % This function plots how the twelve cable segment lengths connecting a
    % single primitive change with time.
    %
    % This shows when individual cables stretch or go slack.
    %-------------------------------
    figure;
    for a = 1:size(stringLengths,[2]) %Calculate F_s (12 string forces)
        subplot(3,4,a);
        x = 1:size(stringLengths,[1]); %Number of iterations (time)
        y = stringLengths(:,a); %Cable length changing w/ time per cable
        plot(x,y);
        xlabel('Time');
        ylabel('Cable Length');
        yline(l_max,'--','Max Length');
        y1 = yline(l_0,'--','Slack');
        y1.LabelVerticalAlignment = 'bottom';
        ylim ([1 (l_max+0.2)]);
        title(['Cable Segment ', num2str(a)])
    end
    hold off;
end




function plotWrench(Wrenches)

    %------Function Description------
    % This function plots the six components of the body Wrench over time.
    %-------------------------------
    figure;
    for a = 1:size(Wrenches,[2]) %Calculate F_s (12 string forces)
        subplot(2,3,a);
        x = 1:size(Wrenches,[1]); %Number of iterations (time)
        y = Wrenches(:,a); %Wrench value changing w/ time
        plot(x,y);
        xlabel('Time');
        if a == 1 || a == 2 || a == 3
            title('Sum of Moments');
        else
            title('Sum of Forces');
        end
    end
    hold off;
end




function plotPrimitive(Ts, P, omega, theta, v, Tvert2, Tvert3, T3s)

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
    arc3_0 = Tvert2*arc2_0;
    plot3(arc3_0(1,:), arc3_0(2,:), arc3_0(3,:),'LineWidth',8) %Initial arc2
    hold on
    arc4_0 = Tvert3*arc3_0;
    plot3(arc4_0(1,:), arc4_0(2,:), arc4_0(3,:),'LineWidth',8) %Initial arc2
    hold on
    
    for i = 1:length(Ts)
        TMatB = reshape(Ts(i,:), [4, 4]);
        TMatB3 = reshape(T3s(i,:), [4, 4]);
        arc2 = TMatB * P;
        plot3(arc2(1,:), arc2(2,:), arc2(3,:)); % Changing arc2 position
        hold on;
        arc3 = Tvert2*arc2;
        plot3(arc3(1,:), arc3(2,:), arc3(3,:)); % Changing arc3 position fixed to the top of arc2
        hold on
        arc4 = TMatB3*arc3;
        plot3(arc4(1,:), arc4(2,:), arc4(3,:)); % Changing arc4 position
        hold on
    end
    
    hold off;
end




function plotPrimitiveCurved(Ts, P, r, CoM, video_title, Tvert2, Tvert3, T3s)

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
    v = VideoWriter(video_title, "MPEG-4");
    v.FrameRate = 60; %Set video frame rate
    open(v);
    
    % Plotting things
    for i = 1:length(Ts)
        TMatB = reshape(Ts(i,:), [4, 4]);
        TMatB3 = reshape(T3s(i,:), [4, 4]);
        P2 = TMatB*P;
        P3 = Tvert2*P2;
        P4 = TMatB3*P3;

        % Plotting the curved strut
        semiCircle2D = @(r) [r*cos(pi:0.01:2*pi);r*sin(pi:0.01:2*pi);...
            zeros(size(cos(pi:0.01:2*pi)));ones(size(cos(pi:0.01:2*pi)))];
        plotXYZ = @(XYZ) plot3(XYZ(:,1),XYZ(:,2),XYZ(:,3));
        xyz = semiCircle2D(r);
        h=plotXYZ(xyz');
        % xlim
        hold on
        set(h,'Color','b','LineWidth',10)
        xyzRotated = TMatB*xyz;
        h=plotXYZ(xyzRotated');
        set(h,'Color','k','LineWidth',10)

        hold on
        xyz2 = Tvert2*xyzRotated;
        h=plotXYZ(xyz2');
        set(h,'Color','b','LineWidth',10)
        hold on
        xyz2Rotated = TMatB3*xyz2;
        h=plotXYZ(xyz2Rotated');
        set(h,'Color','k','LineWidth',10)

        grid on; grid minor;
        
        % Plotting Cables
        plot3(P(1,:),P(2,:),P(3,:),'om','MarkerSize',6,'Linewidth',4)
        text(P(1,:),P(2,:),P(3,:),['A','B','C','D']','FontSize',20)
        hold on
        plot3(P2(1,:),P2(2,:),P2(3,:),'om','MarkerSize',6,'Linewidth',4)
        text(P2(1,:),P2(2,:),P2(3,:),['A','B','C','D']','FontSize',20)

        hold on
        plot3(P3(1,:),P3(2,:),P3(3,:),'om','MarkerSize',6,'Linewidth',4)
        text(P3(1,:),P3(2,:),P3(3,:),['A','B','C','D']','FontSize',20)
        hold on
        plot3(P4(1,:),P4(2,:),P4(3,:),'om','MarkerSize',6,'Linewidth',4)
        text(P4(1,:),P4(2,:),P4(3,:),['A','B','C','D']','FontSize',20)

        for ii=1:4
            for jj=[1,4]
                plot3([P(1,jj);P2(1,ii)],...
                    [P(2,jj);P2(2,ii)],...
                    [P(3,jj);P2(3,ii)],'-r','Linewidth',4)

                plot3([P3(1,jj);P4(1,ii)],...
                    [P3(2,jj);P4(2,ii)],...
                    [P3(3,jj);P4(3,ii)],'-r','Linewidth',4)
            end
        end

        for jj=2:3
            for ii=[1,4]
                plot3([P(1,jj);P2(1,ii)],...
                    [P(2,jj);P2(2,ii)],...
                    [P(3,jj);P2(3,ii)],'-r','Linewidth',4)

                plot3([P3(1,jj);P4(1,ii)],...
                    [P3(2,jj);P4(2,ii)],...
                    [P3(3,jj);P4(3,ii)],'-r','Linewidth',4)
            end
        end

        % Axis
        origin = [-CoM,1];
        origin2 = TMatB*[-CoM,1]';
        plot3(origin(1),origin(2),origin(3),'x','MarkerSize',10,'Linewidth',6,...
            'Color',[0.9290, 0.6940, 0.1250]);
        plot3(origin2(1),origin2(2),origin2(3),'x','MarkerSize',10,'Linewidth',6,...
            'Color',[0.8500, 0.3250, 0.0980]);
%         for ii=1:3
%             coordinateXYZ = [zeros(2,3),ones(2,1)]';
%             %coordinateXYZ = [-CoM, 1; 0,0,0, 1]';
%             coordinateXYZ(ii,2)=r/2;
%             coordinateXYZ2 = TMatB*coordinateXYZ;
%             plot3(coordinateXYZ(1,:),coordinateXYZ(2,:),...
%             coordinateXYZ(3,:),'-.','Color',[0, 0.4470, 0.7410],'LineWidth',4)
%             plot3(coordinateXYZ2(1,:),coordinateXYZ2(2,:),...
%             coordinateXYZ2(3,:),'-.','Color',[0.25, 0.25, 0.25],'LineWidth',4)
%         end
        frame = getframe(gcf);
        writeVideo(v,frame)
        %pause(0.001)
        hold off
    end
    hold off
    close(v);
end