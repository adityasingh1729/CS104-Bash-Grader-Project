import pandas as pd

def calculate_statistics(csv_file):
    df = pd.read_csv(csv_file)

    # Exclude "Roll_Number" and "Name" columns from coercion
    numeric_columns = [col for col in df.columns if col not in ["Roll_Number", "Name"]]
    df[numeric_columns] = df[numeric_columns].apply(pd.to_numeric, errors='coerce')

    # Calculate mean and median for each exam
    exam_stats = {}
    for exam in df.columns[2:-1]:  # Exclude "Roll_Number", "Name", and "total" columns
        exam_marks = df[exam]
        mean = round(exam_marks.mean(skipna=True), 2)  # Round mean to 2 decimal places
        median = round(exam_marks.median(skipna=True), 2)  # Round median to 2 decimal places
        exam_stats[exam] = {"Mean": mean, "Median": median}

    # Calculate total marks and rank students based on total marks
    numeric_columns_no_total = [col for col in numeric_columns if col != "total"]
    df['total'] = df[numeric_columns_no_total].sum(axis=1)  # Calculate total marks excluding the "total" column
    df['Rank'] = df['total'].rank(ascending=False, method='min')  # Rank students based on total marks

    # Sort DataFrame by rank
    df = df.sort_values(by='Rank')

    return exam_stats, df

def print_top_ranked_students(ranked_df):
    print("\nTop Ranked Students:")
    print("Rank".ljust(6), "Roll Number".ljust(12), "Name".ljust(25), "Total Marks")
    print("="*60)
    for _, row in ranked_df.head(10).iterrows():  # Print top 10 ranked students
        rank = str(int(row['Rank']))
        roll_number = str(row['Roll_Number'])
        name = row['Name']
        total_marks = str(row['total'])
        print(rank.ljust(6), roll_number.ljust(12), name.ljust(25), total_marks)

if __name__ == "__main__":
    # Assuming the CSV file name is provided as a command-line argument
    import sys

    if len(sys.argv) != 2:
        print("Usage: python calculate_statistics.py <csv_file>")
        sys.exit(1)

    csv_file = sys.argv[1]
    stats, ranked_df = calculate_statistics(csv_file)

    # Print statistics results
    print("Statistics for each exam:")
    for exam, values in stats.items():
        print(f"{exam}: Mean={values['Mean']}, Median={values['Median']}")

    # Print the top ranked students in an aesthetic format
    print_top_ranked_students(ranked_df)
