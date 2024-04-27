import pandas as pd
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

# Load the data from main.csv
df = pd.read_csv("main.csv")
df = df.replace('a', 0)

# Extract exam scores for clustering analysis
exam_scores = df.iloc[:, 2:]  # Exclude first two columns (Roll_Number and Name)

# Standardize the data for clustering
scaler = StandardScaler()
exam_scores_scaled = scaler.fit_transform(exam_scores)

# Perform K-Means clustering with a predefined number of clusters
num_clusters = 3  # Specify the number of clusters
kmeans = KMeans(n_clusters=num_clusters, random_state=42)
cluster_labels = kmeans.fit_predict(exam_scores_scaled)

# Add the cluster labels to the original DataFrame
df['Cluster'] = cluster_labels

# Display the clustered data
print(df[['Roll_Number', 'Name', 'Cluster']])

# Visualize the clusters (assuming 2D data for simplicity)
plt.figure(figsize=(8, 6))
plt.scatter(exam_scores_scaled[:, 0], exam_scores_scaled[:, 1], c=cluster_labels, cmap='viridis')
plt.title('Clustering of Students Based on Exam Scores')
plt.xlabel('Exam Score (First Exam)')
plt.ylabel('Exam Score (Second Exam)')
plt.colorbar(label='Cluster')
plt.grid(True)
plt.show()
