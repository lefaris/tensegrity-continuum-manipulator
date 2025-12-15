%Read in Vicon data for REACH and plot that shiz

opts = detectImportOptions('Test1.csv');
%preview('impact_full.csv',opts)
% opts.SelectedVariableNames = [3:50]; 
% opts.DataRange = '6:845';
% M = readmatrix('impact_full.csv',opts)
N = readmatrix('Test1.csv','Range','C6:BD5755');



%Read five primitives data:
%1:5750 is full range of data
e = 5750;
prim1Left1 = N(1:e, 10:12);
prim1Right1 = N(1:e, 13:15);

prim2Left1 = N(1:e, 19:21);
prim2Right1 = N(1:e, 22:24);

prim3Left1 = N(1:e, 28:30);
prim3Right1 = N(1:e, 31:33);

prim4Left1 = N(1:e, 37:39);
prim4Right1 = N(1:e, 40:42);

prim5Left1 = N(1:e, 46:48);
prim5Right1 = N(1:e, 49:51);


%Find all primitive mid-points?
prim1X = [(prim1Left1(:,1)+prim1Right1(:,1))/2];
prim1Y = [(prim1Left1(:,2)+prim1Right1(:,2))/2];
prim1Z = [(prim1Left1(:,3)+prim1Right1(:,3))/2];

prim2X = [(prim2Left1(:,1)+prim2Right1(:,1))/2];
prim2Y = [(prim2Left1(:,2)+prim2Right1(:,2))/2];
prim2Z = [(prim2Left1(:,3)+prim2Right1(:,3))/2];

prim3X = [(prim3Left1(:,1)+prim3Right1(:,1))/2];
prim3Y = [(prim3Left1(:,2)+prim3Right1(:,2))/2];
prim3Z = [(prim3Left1(:,3)+prim3Right1(:,3))/2];

prim4X = [(prim4Left1(:,1)+prim4Right1(:,1))/2];
prim4Y = [(prim4Left1(:,2)+prim4Right1(:,2))/2];
prim4Z = [(prim4Left1(:,3)+prim4Right1(:,3))/2];

prim5X = [(prim5Left1(:,1)+prim5Right1(:,1))/2];
prim5Y = [(prim5Left1(:,2)+prim5Right1(:,2))/2];
prim5Z = [(prim5Left1(:,3)+prim5Right1(:,3))/2];


prim1Xtot = [prim1Left1(:,1),prim1Right1(:,1)];
prim1Ytot = [prim1Left1(:,2),prim1Right1(:,2)];
prim1Ztot = [prim1Left1(:,3),prim1Right1(:,3)];

prim2Xtot = [prim2Left1(:,1),prim2Right1(:,1)];
prim2Ytot = [prim2Left1(:,2),prim2Right1(:,2)];
prim2Ztot = [prim2Left1(:,3),prim2Right1(:,3)];

prim3Xtot = [prim3Left1(:,1),prim3Right1(:,1)];
prim3Ytot = [prim3Left1(:,2),prim3Right1(:,2)];
prim3Ztot = [prim3Left1(:,3),prim3Right1(:,3)];

prim4Xtot = [prim4Left1(:,1),prim4Right1(:,1)];
prim4Ytot = [prim4Left1(:,2),prim4Right1(:,2)];
prim4Ztot = [prim4Left1(:,3),prim4Right1(:,3)];

prim5Xtot = [prim5Left1(:,1),prim5Right1(:,1)];
prim5Ytot = [prim5Left1(:,2),prim5Right1(:,2)];
prim5Ztot = [prim5Left1(:,3),prim5Right1(:,3)];


% %Read arc 2 data:
% arc2Left1 = M(1:840, 25:27);
% arc2Left2 = M(1:840, 28:30);
% arc2Left3 = M(1:840, 31:33);
% arc2Left4 = M(1:840, 34:36);
% 
% arc2Right1 = M(1:840, 37:39);
% arc2Right2 = M(1:840, 40:42);
% arc2Right3 = M(1:840, 43:45);
% arc2Right4 = M(1:840, 46:48);
% 
% %Combine all of arc 2 points?
% arc2LeftX = [arc2Left1(:,1),arc2Left2(:,1),arc2Left3(:,1),arc2Left4(:,1)];
% arc2LeftY = [arc2Left1(:,2),arc2Left2(:,2),arc2Left3(:,2),arc2Left4(:,2)];
% arc2LeftZ = [arc2Left1(:,3),arc2Left2(:,3),arc2Left3(:,3),arc2Left4(:,3)];
% 
% arc2RightX = [arc2Right1(:,1),arc2Right2(:,1),arc2Right3(:,1),arc2Right4(:,1)];
% arc2RightY = [arc2Right1(:,2),arc2Right2(:,2),arc2Right3(:,2),arc2Right4(:,2)];
% arc2RightZ = [arc2Right1(:,3),arc2Right2(:,3),arc2Right3(:,3),arc2Right4(:,3)];
% 
% arc2X = [(arc2Left1(:,1)+arc2Right1(:,1))/2, (arc2Left2(:,1)+arc2Right2(:,1))/2, (arc2Left3(:,1)+arc2Right3(:,1))/2, (arc2Left4(:,1)+arc2Right4(:,1))/2];
% arc2Y = [(arc2Left1(:,2)+arc2Right1(:,2))/2, (arc2Left2(:,2)+arc2Right2(:,2))/2, (arc2Left3(:,2)+arc2Right3(:,2))/2, (arc2Left4(:,2)+arc2Right4(:,2))/2];
% arc2Z = [(arc2Left1(:,3)+arc2Right1(:,3))/2, (arc2Left2(:,3)+arc2Right2(:,3))/2, (arc2Left3(:,3)+arc2Right3(:,3))/2, (arc2Left4(:,3)+arc2Right4(:,3))/2];

%Plot the discrete points from arc 1
figure(1)
plot3(prim1X(:),prim1Y(:),prim1Z(:))
hold on
plot3(prim2X(:),prim2Y(:),prim2Z(:))
hold on
plot3(prim3X(:),prim3Y(:),prim3Z(:))
hold on
plot3(prim4X(:),prim4Y(:),prim4Z(:))
hold on
plot3(prim5X(:),prim5Y(:),prim5Z(:))


j=0;
figure(2)
for i=1:10:e
    plot3(prim1Xtot(i,1:2),prim1Ytot(i,1:2),prim1Ztot(i,1:2),Color=[0 j 1])
    hold on
    plot3(prim2Xtot(i,1:2),prim2Ytot(i,1:2),prim2Ztot(i,1:2),Color=[1 0 j])
    hold on
    plot3(prim3Xtot(i,1:2),prim3Ytot(i,1:2),prim3Ztot(i,1:2),Color=[0 j 1])
    hold on
    plot3(prim4Xtot(i,1:2),prim4Ytot(i,1:2),prim4Ztot(i,1:2),Color=[1 0 j])
    hold on
    plot3(prim5Xtot(i,1:2),prim5Ytot(i,1:2),prim5Ztot(i,1:2),Color=[0 j 1])
    hold on
    plot3([prim1X(i),prim2X(i),prim3X(i),prim4X(i),prim5X(i)],[prim1Y(i),prim2Y(i),prim3Y(i),prim4Y(i),prim5Y(i)],[prim1Z(i),prim2Z(i),prim3Z(i),prim4Z(i),prim5Z(i)],Color=[0 0 0])
    j = j+0.0017;
end

k=0;
figure(3)
for i=1:10:e
    plot3([prim1X(i),prim2X(i),prim3X(i),prim4X(i),prim5X(i)],[prim1Y(i),prim2Y(i),prim3Y(i),prim4Y(i),prim5Y(i)],[prim1Z(i),prim2Z(i),prim3Z(i),prim4Z(i),prim5Z(i)],Color=[k 1 0])
    hold on
    k = k+0.00012;
end

l=0;
figure(4)
for i=1:10:570
    plot3(prim1Xtot(i,1:2),prim1Ytot(i,1:2),prim1Ztot(i,1:2),Color=[0 l 1])
    hold on
    plot3(prim2Xtot(i,1:2),prim2Ytot(i,1:2),prim2Ztot(i,1:2),Color=[1 0 l])
    hold on
    plot3(prim3Xtot(i,1:2),prim3Ytot(i,1:2),prim3Ztot(i,1:2),Color=[0 l 1])
    hold on
    plot3(prim4Xtot(i,1:2),prim4Ytot(i,1:2),prim4Ztot(i,1:2),Color=[1 0 l])
    hold on
    plot3(prim5Xtot(i,1:2),prim5Ytot(i,1:2),prim5Ztot(i,1:2),Color=[0 l 1])
    hold on
    plot3([prim1X(i),prim2X(i),prim3X(i),prim4X(i),prim5X(i)],[prim1Y(i),prim2Y(i),prim3Y(i),prim4Y(i),prim5Y(i)],[prim1Z(i),prim2Z(i),prim3Z(i),prim4Z(i),prim5Z(i)],Color=[0 0 0])
    l = l+0.017;
end