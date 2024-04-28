import pandas as pd
import numpy as np

def median_absolute_deviation(data):
    median = np.median(data)
    deviations = np.abs(data - median)
    return np.median(deviations)

def exam_info(exam_name, csv_file):
    # Load the data from the CSV file
    df = pd.read_csv(csv_file)

    # Check if the provided exam exists in the DataFrame columns
    if exam_name not in df.columns:
        print(f"Error: Exam '{exam_name}' not found in the CSV file.")
        return

    # Filter out 'a' marks and convert to numeric format for calculations
    exam_marks_numeric = pd.to_numeric(df[exam_name], errors='coerce')
    exam_marks_numeric = exam_marks_numeric.dropna()

    if exam_marks_numeric.empty:
        print(f"No valid marks found for exam '{exam_name}'.")
        return

    # Calculate mean, median, and standard deviation
    mean_score = np.mean(exam_marks_numeric)
    median_score = np.median(exam_marks_numeric)
    std_deviation = np.std(exam_marks_numeric)
    mad_score = median_absolute_deviation(exam_marks_numeric)

    # Count the number of students who gave the exam
    students_with_marks = df[df[exam_name] != 'a']
    students_count = len(students_with_marks)

    # Find the topper
    max_score_index = exam_marks_numeric.idxmax()
    topper_info = df.iloc[max_score_index]
    topper_roll = topper_info['Roll_Number']
    topper_name = topper_info['Name']
    topper_score = topper_info[exam_name]

    # Display exam information
    print(f"Exam Name: {exam_name}")
    print(f"Mean Score: {mean_score}")
    print(f"Median Score: {median_score}")
    print(f"Standard Deviation: {std_deviation}")
    print(f"Median Absolute Deviation: {mad_score}")
    print(f"Topper: {topper_name} (Roll Number: {topper_roll}, Score: {topper_score})")
    print(f"Number of Students who appeared in the exam: {students_count}")

# Example usage
if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python exam_info.py <exam_name> <csv_file>")
    else:
        exam_name = sys.argv[1]
        csv_file = sys.argv[2]
        exam_info(exam_name, csv_file)
