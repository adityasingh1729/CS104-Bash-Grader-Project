import pandas as pd
import matplotlib.pyplot as plt

def plot_marks(csv_file):
    df = pd.read_csv(csv_file)
    df = df.replace('a', 0)   # replacing a by 0 marks

    # Extract exam names and corresponding marks for plotting
    exam_names = df.columns[2:]

    # Convert marks to numeric values (assuming they are strings)
    df[exam_names] = df[exam_names].apply(pd.to_numeric)

    # Plotting each exam separately
    for exam in exam_names:
        plt.figure(figsize=(10, 6))
        plt.bar(df['Name'] + ' (' + df['Roll_Number'] + ')', df[exam])
        plt.xlabel('Student Names (Roll Numbers)')
        plt.ylabel('Marks')
        plt.title(f'Marks of Students in {exam}')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(f'./plots/{exam}_marks.png')  # Saving each plot as a separate image
        plt.close()

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python plot_marks.py <csv_file>")
        sys.exit(1)

    csv_file = sys.argv[1]
    plot_marks(csv_file)
