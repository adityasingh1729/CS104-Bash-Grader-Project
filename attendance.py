import pandas as pd
import matplotlib.pyplot as plt

def plot_marks(csv_file):

    df = pd.read_csv(csv_file)
    
    # Calculating total entries and total 'a' entries in relevant rows/columns
    relevant_df = df.iloc[:, 2:]  # Exclude first two columns (Name and Roll_Number)
    
    # Check if 'header' column exists, and exclude it from relevant_df if present
    if 'total' in relevant_df.columns:
        relevant_df = relevant_df.drop(columns=['total'])

    total_entries = relevant_df.size
    total_a_entries = relevant_df.apply(lambda row: row.str.count('a')).sum().sum()

    # Plotting a pie chart for 'a' entries
    plt.figure(figsize=(8, 8))
    labels = ['Present', 'Absent']
    sizes = [total_entries - total_a_entries, total_a_entries]
    plt.pie(sizes, labels=labels, autopct='%1.1f%%', startangle=140)
    plt.title('Attendance Overview')
    plt.savefig('./plots/attendance_pie_chart.png')
    plt.close()

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python plot_marks.py <csv_file>")
        sys.exit(1)

    csv_file = sys.argv[1]
    plot_marks(csv_file)
