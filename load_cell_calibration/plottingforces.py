# -*- coding: utf-8 -*-

import matplotlib.pyplot as plt
import csv

y0, y1, y2, y3 = [], [], [], []
with open('path1_1.csv','r') as csvfile:
	lines = csv.reader(csvfile, delimiter=',')
	for row in lines:
		y0.append(float(row[0]))
		y1.append(float(row[1]))
		y2.append(float(row[2]))
		y3.append(float(row[3]))

x1 = list(range(len(y0))) #316 for the first one, 181 for second
size1 = len(y0) - 1

y4, y5, y6, y7 = [], [], [], []
with open('path1_2.csv','r') as csvfile:
	lines = csv.reader(csvfile, delimiter=',')
	for row in lines:
		y4.append(float(row[0]))
		y5.append(float(row[1]))
		y6.append(float(row[2]))
		y7.append(float(row[3]))

x2 = list(range(len(y4))) #316 for the first one, 181 for second
size2 = len(y4) - 1

# plt.plot(x, y0, color = 'r', linestyle = 'dashed',
# 		marker = 'o',label = "Load Cell 1")
# plt.plot(x, y1, color = 'g', linestyle = 'dashed',
# 		marker = 'x',label = "Load Cell 2")
# plt.plot(x, y2, color = 'b', linestyle = 'dashed',
# 		marker = '+',label = "Load Cell 3")
# plt.plot(x, y3, color = 'y', linestyle = 'dashed',
# 		marker = '*',label = "Load Cell 4")

# plt.xticks(rotation = 25)
# plt.xlabel('Time')
# plt.ylabel('Lbs force')
# plt.title('Load Cell Force Values', fontsize = 20)
# plt.grid()
# plt.legend()
# plt.show()

# Use a clean, modern style
plt.style.use('classic')  # Other good ones: 'ggplot', 'seaborn-darkgrid'

# Create the figure
fig, ax = plt.subplots(figsize=(12, 12))

# Plot with improved style
ax.plot(x1, y0, label="Load Cell 1 Order 1", color="red", linewidth=2)
ax.plot(x1, y1, label="Load Cell 2 Order 1", color="green", linewidth=2)
ax.plot(x1, y2, label="Load Cell 3 Order 1", color="blue", linewidth=2)
ax.plot(x1, y3, label="Load Cell 4 Order 1", color="orange", linewidth=2)

ax.plot(x2, y4, label="Load Cell 1 Order 2", color="red", linestyle='--', linewidth=2)
ax.plot(x2, y5, label="Load Cell 2 Order 2", color="green", linestyle='--', linewidth=2)
ax.plot(x2, y6, label="Load Cell 3 Order 2", color="blue", linestyle='--', linewidth=2)
ax.plot(x2, y7, label="Load Cell 4 Order 2", color="orange", linestyle='--', linewidth=2)

ax.plot(x2[size2], y4[size2], marker = 'o', markersize=20, color = 'red')
ax.plot(x2[size2], y5[size2], marker = 'o', markersize=20, color = 'green')
ax.plot(x2[size2], y6[size2], marker = 'o', markersize=20, color = 'blue')
ax.plot(x2[size2], y7[size2], marker = 'o', markersize=20, color = 'orange')
ax.plot(x1[size1], y0[size1], marker = 'o', markersize=20, color = 'red')
ax.plot(x1[size1], y1[size1], marker = 'o', markersize=20, color = 'green')
ax.plot(x1[size1], y2[size1], marker = 'o', markersize=20, color = 'blue')
ax.plot(x1[size1], y3[size1], marker = 'o', markersize=20, color = 'orange')

# Labels and title
ax.set_xlabel('Time (samples)', fontsize=20)
ax.set_ylabel('Force (lbs)', fontsize=20)
ax.set_title('Load Cell Force Values for Different Order', fontsize=24, weight='bold')

# Grid, legend, and tick styling
ax.grid(True, which='both', linestyle='--', linewidth=1, alpha=0.8)
ax.legend(fontsize=16)
ax.tick_params(axis='both', labelsize=18)

# Tight layout for cleaner appearance
plt.tight_layout()
plt.show()
print(plt.style.available)