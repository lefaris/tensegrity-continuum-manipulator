clc; clear; close all;
% This is just to try to get a potential omega, v
% Found R using Rx(180), Ry(90)
R = [0, 0, 1;...
    0, -1, 0;...
    1, 0, 0];
% p is only translation in y-direction, recessed 3/4 in
p = [0, -2.25, 0]'; %Changed from -0.75
% Just using transformation matrix rather than using e^[s] for now
T = [R, p;...
    0, 0, 0, 1];

[omega,theta,v] = EquivalentScrew3(T);

% omega = omega + 10*rand(3,1);
omega = omega/norm(omega);
mm =0;
%% Initial S
S_0 = theta*[omega', v']';
% S_0 = [randn(6,1)];
% S_0 = S_0/norm(S_0(1:3));
% Sbracket_0 = screw2se3(S_0); 
% r = 1.1875;

% sysParams.l_0_1 = 4.8; %Changed from 1.5
% sysParams.l_0_2 = 3.48; %Changed from 1.25
% sysParams.l_0 = 5; %Changed from 1.6
% sysParams.r = 7.9; %Changed from 1.21875
% sysParams.k = 0.8; %lb/in (back of the hand calc in lab) %Changed from 0.44
sysParams.l_0_1 = 3.25; %Changed from 1.5
sysParams.l_0_2 = 3.0; %Changed from 1.25
sysParams.l_0 = 3.3; %Changed from 1.6
sysParams.r = 4.125; %Changed from 1.21875
sysParams.k = 0.8; %lb/in (back of the hand calc in lab) %Changed from 0.44


ff = 0.1
% Fext.Fa = 0.01*[0,-1,0]';
Fext.Fa = ff*[0,-1,0]';
Fext.Fa  = zeros(3,1);
S_minV = fminunc(@(S) minimizetotalV(S,sysParams,Fext), S_0); 
TMat_minV=screw2TMat(S_minV);
fprintf('Translation = [');
fprintf(' %.2f',TMat_minV(1:3,4));
fprintf(']\n');



%% Plot 

% The pts are [pa,pb,pc,pd] 3x4 normal but 4x4 in homogenous representation
% StrutPts = [-1.1875, 0, 0, 1;
%             -0.6, -1.025, 0, 1;
%             0.6, -1.025, 0, 1; 
%             1.1875, 0, 0, 1]';

StrutPts = [-4.125, 0, 0, 1;
            -2.0625, -3.5724, 0, 1;
            2.0625, -3.5724, 0, 1; 
            4.125, 0, 0, 1]';
% The pts of the rotated struts are by S_minV
StrutPts2 = TMat_minV*StrutPts;

A1 = StrutPts(1:3,1);
B1 = StrutPts(1:3,2);
C1 = StrutPts(1:3,3);
D1 = StrutPts(1:3,4);
A2 = StrutPts2(1:3,1);
B2 = StrutPts2(1:3,2);
C2 = StrutPts2(1:3,3);
D2 = StrutPts2(1:3,4);

A1A2 = norm(A1-A2);
A1B2 = norm(A1-B2);
A1C2 = norm(A1-C2);
A1D2 = norm(A1-D2);
B1A2 = norm(B1-A2);
B1D2 = norm(B1-D2);
C1A2 = norm(C1-A2);
C1D2 = norm(C1-D2);
D1A2 = norm(D1-A2);
D1B2 = norm(D1-B2);
D1C2 = norm(D1-C2);
D1D2 = norm(D1-D2);

str_lengths = [A1A2, A1B2, A1C2, A1D2; ...
    B1A2, B1D2, C1A2, C1D2; ...
    D1A2, D1B2, D1C2, D1D2];

%% Plotting things
% Plotting the curved strut
semiCircle2D = @(r) [r*cos(pi:0.01:2*pi);r*sin(pi:0.01:2*pi);...
    zeros(size(cos(pi:0.01:2*pi)));ones(size(cos(pi:0.01:2*pi)))];
plotXYZ = @(XYZ) plot3(XYZ(:,1),XYZ(:,2),XYZ(:,3));
r = 4.125; %Changed from 1.1875
xyz = semiCircle2D(r);
f = figure
h=plotXYZ(xyz');
% xlim
hold on
set(h,'Color','b','LineWidth',7)
xyzRotated = TMat_minV*xyz;
h=plotXYZ(xyzRotated');
set(h,'Color','[0.25, 0.25, 0.25]','LineWidth',7)
% grid on; grid minor;
% Plotting Cables
plot3(StrutPts(1,:),StrutPts(2,:),StrutPts(3,:),'om','MarkerSize',6,'Linewidth',2)
text(StrutPts(1,1)-.1,StrutPts(2,1)+.2,StrutPts(3,1)-.15,'A^1','FontSize',18)
text(StrutPts(1,2),StrutPts(2,2),StrutPts(3,2)-.15,'B^1','FontSize',18)
text(StrutPts(1,3),StrutPts(2,3),StrutPts(3,3)-.1,'C^1','FontSize',18)
text(StrutPts(1,4)+.05,StrutPts(2,4),StrutPts(3,4)+.15,'D^1','FontSize',18)
% text(StrutPts(1,:),StrutPts(2,:),StrutPts(3,:),['A','B','C','D']','FontSize',20)
hold on
plot3(StrutPts2(1,:),StrutPts2(2,:),StrutPts2(3,:),'om','MarkerSize',6,'Linewidth',2)
% text(StrutPts2(1,:),StrutPts2(2,:),StrutPts2(3,:),['A','B','C','D']','FontSize',20)
text(StrutPts2(1,1)+.03,StrutPts2(2,1),StrutPts2(3,1)-.1,'A^2','FontSize',18)
text(StrutPts2(1,2),StrutPts2(2,2),StrutPts2(3,2)+.175,'B^2','FontSize',18)
text(StrutPts2(1,3)-.23,StrutPts2(2,3),StrutPts2(3,3)+.1,'C^2','FontSize',18)
text(StrutPts2(1,4)+.1,StrutPts2(2,4),StrutPts2(3,4)+.05,'D^2','FontSize',18)
for ii=1:4
    for jj=[1,4]
        plot3([StrutPts(1,jj);StrutPts2(1,ii)],...
            [StrutPts(2,jj);StrutPts2(2,ii)],...
            [StrutPts(3,jj);StrutPts2(3,ii)],'-r','Linewidth',2)
    end
end

for jj=2:3
    for ii=[1,4]
        plot3([StrutPts(1,jj);StrutPts2(1,ii)],...
            [StrutPts(2,jj);StrutPts2(2,ii)],...
            [StrutPts(3,jj);StrutPts2(3,ii)],'-r','Linewidth',2)
    end
end

% Axis
origin = [0,-.5,0,1];
origin2 = TMat_minV*[0,-.5,0,1]';
plot3(origin(1),origin(2),origin(3),'x','MarkerSize',10,'Linewidth',3,...
    'Color',[0.9290, 0.6940, 0.1250]);
plot3(origin2(1),origin2(2),origin2(3),'x','MarkerSize',10,'Linewidth',3,...
    'Color',[0.8500, 0.3250, 0.0980]);
for ii=1:3
%     coordinateXYZ = [zeros(2,3),ones(2,1)]';
    coordinateXYZ = [0 -.5 0 1; 0 -.5 0 1]';    
    coordinateXYZ(ii,2)= coordinateXYZ(ii,1)+r/4;
    coordinateXYZ2 = TMat_minV*coordinateXYZ;
    plot3(coordinateXYZ(1,:),coordinateXYZ(2,:),...
    coordinateXYZ(3,:),'-.','Color',[0, 0.4470, 0.7410],'LineWidth',3)
    plot3(coordinateXYZ2(1,:),coordinateXYZ2(2,:),...
    coordinateXYZ2(3,:),'-.','Color',[0.25, 0.25, 0.25],'LineWidth',3)
end
grid on; grid minor;
xlabel('X axis', 'FontSize',16), ylabel('Y axis', 'FontSize',16)
zlabel('Z axis', 'FontSize',16)
set(gca,'FontSize',15)
set(gca,'CameraPosition',[-6 -8.5 4]);
% view([5 125]);
pause(1)
mm = mm+1;
F(mm) = getframe(gcf);
hold off
S_0 = S_minV;

TMat_minV
str_lengths-2.65
% close

% % create the video writer with 1 fps
% writerObj = VideoWriter('LagrangeFormFind','MPEG-4');
% writerObj.FrameRate = 10;
% % set the seconds per image
% % open the video writer
% open(writerObj);
% % write the frames to the video
% for i=1:length(F)
%     % convert the image to a frame
%     frame = F(i) ;    
%     writeVideo(writerObj, frame);
% end
% % close the writer object
% close(writerObj);