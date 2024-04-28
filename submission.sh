#!/bin/bash

# Define the command-line arguments
command=$1  # Store the first argument as the command
args=("$@")  # Store all command-line arguments in an array
num_args="$#"  # Count the total number of arguments

# Function to calculate total marks for each student in main.csv
total() {
    # Check if "total" column exists in main.csv header
    if ! head -n 1 main.csv | grep -q ",total"; then
        # Calculate total marks for each student and add as a new row in main.csv
        awk -F, 'NR==1{print $0",total"; next} {total=0; for(i=3;i<=NF;i++) total+=$i; sub(/\r/,"", $0); print $0 "," total}' main.csv > temp.csv
        # Replace main.csv with updated version
        mv temp.csv main.csv
    fi
}

# Function to combine CSV files into main.csv
combine() {
    # Initialize main.csv with header based on existing CSV files
    isTotal=0  # Flag to check if "total" column exists
    if [ -f "main.csv" ]; then
        if head -n 1 main.csv | grep -q ",total"; then
            isTotal=1
        fi
    fi
    # Making the header row
    header="Roll_Number,Name"
    for file in *.csv; do
        if [ "$file" != "main.csv" ]; then
            exam=$(echo "$file" | cut -d. -f1)
            header="$header,$exam"
        fi
    done
    echo "$header" > main.csv

    # Get unique roll numbers across all CSV files
    roll_numbers=$(sed '1d' *.csv | awk -F, 'NR>1 {print toupper($1)}' | grep -v 'ROLL_NUMBER' | sort | uniq)

    # Iterate over unique roll numbers
    for roll_number in $roll_numbers; do
        # Initialize row for the current roll number
        row="$roll_number"
        roll_number_lower=$(echo "$roll_number" | tr '[:upper:]' '[:lower:]')

        # Get the name for the current roll number (assuming names don't vary)
        name=$(awk -F, -v rn="$roll_number" 'NR>1 && $1==rn {print $2; exit}' *.csv | grep -v '^$')
        if [ -z "$name" ]; then
            name=$(awk -F, -v rn="$roll_number_lower" 'NR>1 && $1==rn {print $2; exit}' *.csv | grep -v '^$')
        fi

        # If name is not empty, add name to the row
        if [ -n "$name" ]; then
            row="$row,$name"

            # Iterate over CSV files to get marks for each exam
            for file in *.csv; do
                if [ "$file" != "main.csv" ]; then
                    # Extract exam name from CSV filename
                    exam=$(echo "$file" | cut -d. -f1)
                    # Get marks for the current roll number in the current exam
                    marks=$(awk -F, -v rn="$roll_number" -v ex="$exam" 'NR>1 && $1==rn {print $3}' "$file")
                    row=$(awk '{sub(/\r/,"", $0); print $0}' <<< "$row")
                    # If marks exist, add them to the row; otherwise, add "a"
                    if [ -n "$marks" ]; then
                        row="$row,$marks"
                    else
                        marks=$(awk -F, -v rn="$roll_number_lower" -v ex="$exam" 'NR>1 && $1==rn {print $3}' "$file")
                        if [ -n "$marks" ]; then
                            row="$row,$marks"
                        else
                            row="$row,a"
                        fi
                    fi
                fi
            done

            # Append row to main.csv
            echo "$row" >> main.csv
        fi
    done
    if [ $isTotal -eq 1 ]; then
        total
    fi
}

# Function to upload a file to the current directory
upload() {
    if [[ "$num_args" -eq 2 ]]; then
        if [ -n "${args[1]}" ]; then
            cp "${args[1]}" .  # Copy the specified file to the current directory
            echo "File uploaded successfully."
        else
            echo "Error: Missing file path. Usage: bash submission.sh upload <file_path>"
        fi
    else
        echo "Incorrect number of arguments"
    fi
}

storeFolder=".hidden"

# Function to initialize a Git repository
git_init() {
    if [ "$num_args" -eq 2 ]; then
        remote_dir="${args[1]}"
        if [ -n "$remote_dir" ]; then
            git_dir="$remote_dir"
            mkdir -p "$git_dir"  # Create .git directory for Git metadata
            echo "$git_dir" > "$storeFolder"
            echo "Initialized Git repository at $git_dir"
        else
            echo "Error: Missing remote directory path. Usage: bash submission.sh git_init <remote_dir_path>"
        fi
    else
        echo "Incorrect number of arguments"
    fi
}

# Function to commit changes to the Git repository
git_commit() {
    if [[ "$num_args" -eq 3 ]]; then
        if [ ! -f "$storeFolder" ]; then
            echo "Error: Git repository not initialized. Please run 'bash submission.sh git_init <remote_dir_path>' first."
        elif [[ "${args[1]}" == "-m" ]]; then
            read -r git_dir < "$storeFolder"
            commit_message="${args[2]}"
            # Generate a unique random hash value
            while true; do
                random_hash=$(LC_ALL=C tr -dc '0-9' < /dev/urandom | head -c 16)  # Generate random 16-digit hash
                if ! grep -q "^$random_hash:" "$git_dir/.git_log"; then
                    break  # Exit the loop if the hash is unique
                fi
            done
            # Get the commit time with seconds included
            commit_time=$(date +"%Y-%m-%d %H:%M:%S")
            # Check if it's the first commit (no previous commit to compare with)
            if [ ! -f "$git_dir/.git_log" ]; then
                modified_files=$(ls -1)  # List all files in the directory
            else
                # Find modified files since last commit
                last_commit_time=$(tail -n 1 "$git_dir/.git_commit_time" | awk '{print $2, $3, $4}')
                modified_files=$(find . -type f -newermt "$last_commit_time" | sed 's|^\./||')
            fi
            mkdir -p "$git_dir/$random_hash"  # Create directory for storing files at this commit
            cp -r * "$git_dir/$random_hash"  # Copy all files to commit directory
            # Print modified files
            for file in $modified_files; do
                echo "Modified file: $file"
            done
            echo "$random_hash: $commit_time" >> "$git_dir/.git_commit_time"  # Store commit time
            echo "$random_hash: $commit_message" >> "$git_dir/.git_log"  # Append commit hash and message to .git_log
            echo "Files committed successfully."
        else
            echo "Error: Missing commit message. Usage: bash submission.sh git_commit -m 'commit_message'"
        fi
    else
        echo "Incorrect number of arguments"
    fi
}

# Function to check out a specific commit in the Git repository
git_checkout() {
    if [ -f "$storeFolder" ]; then
        read -r git_dir < "$storeFolder"
        git_log="$git_dir/.git_log"
        if [[ "$num_args" -eq 3 ]]; then
            if [[ "${args[1]}" == "-m" ]]; then
                commit_message="${args[2]}"
                commit_count=$(grep -c "$commit_message" "$git_log")
                if [ "$commit_count" -gt 1 ]; then
                    echo "Error: Commit message '$commit_message' is not unique."
                    return 1
                fi
                hash_value=$(grep "$commit_message" "$git_log" | awk -F': ' '{print $1}' | tr -d '[:space:]')
                if [ -z "$hash_value" ]; then
                    echo "Error: Commit message '$commit_message' not found."
                    return 1
                fi
            else
                echo "Incorrect arguments given"
                return 1
            fi
        elif [[ "$num_args" -eq 2 ]]; then
            # Check if the provided hash value is a prefix
            partial_hash="${args[1]}"
            prefix_count=$(grep "^$partial_hash" "$git_log" | wc -l)
            if [ "$prefix_count" -eq 1 ]; then
                # Extract the full hash value
                hash_value=$(grep "^$partial_hash" "$git_log" | awk '{print substr($1, 1, length($1)-1)}' | tr -d '[:space:]')
            else
                echo "Error: Ambiguous or invalid hash value. Please provide a valid full hash value or a unique prefix."
                return 1
            fi
        else
            echo "Incorrect number of arguments"
            return 1
        fi
        commit_dir="$git_dir/$hash_value"
        if [ -d "$commit_dir" ]; then
            rm *.csv  # Remove existing CSV files
            cp "$commit_dir"/*.csv .  # Copy CSV files from the commit directory
            echo "Checked out to commit $hash_value."
        else
            echo "Error: Commit not found."
        fi
    else
        echo "Error: Git repository not initialized. Please run 'bash submission.sh git_init <remote_dir_path>' first."
    fi
}

# Function to update marks for a student in main.csv and individual exam CSV files
update() {
    if [ "$num_args" -eq 1 ]; then
        # Input student's name and roll number
        read -p "Enter student's name: " student_name
        read -p "Enter student's roll number: " student_roll

        student_roll=$(echo "$student_roll" | tr '[:lower:]' '[:upper:]')
        student_roll_lower=$(echo "$student_roll" | tr '[:upper:]' '[:lower:]')

        # Check if the roll number exists in main.csv
        if ! grep -q "^$student_roll," main.csv; then
            echo "Error: Roll number '$student_roll' not found."
            return 1
        fi

        # Check if the provided name matches the roll number row
        if ! awk -F, -v rn="$student_roll" -v name="$student_name" 'BEGIN {found=0} $1==rn && $2==name {found=1; exit} END {exit !found}' main.csv; then
            echo "Error: Name '$student_name' does not match roll number '$student_roll'."
            return 1
        fi

        # Display exams and ask which ones to update
        echo "Exams:"
        awk -F, 'NR==1{for(i=3;i<=NF;i++) print $i}' main.csv | grep -v "total"
        read -p "Enter exams to update (comma-separated): " exams_to_update

        # Iterate over selected exams and update marks
        for exam in $(echo "$exams_to_update" | tr ',' ' '); do
            # Check if the exam CSV file exists
            if [ -f "$exam.csv" ]; then
                # Check if the student's roll number is in the exam CSV file
                if grep -q "^$student_roll," "$exam.csv"; then
                    # Ask for new marks
                    read -p "Enter marks for $exam: " new_marks
                    # Update marks for existing student in the exam CSV file
                    awk -F, -v rn="$student_roll" -v mk="$new_marks" 'BEGIN {OFS=","} $1==rn {$3=mk} 1' "$exam.csv" > temp.csv && mv temp.csv "$exam.csv"
                elif grep -q "^$student_roll_lower," "$exam.csv"; then
                    # Ask for new marks
                    read -p "Enter marks for $exam: " new_marks
                    # Update marks for existing student in the exam CSV file
                    awk -F, -v rn="$student_roll_lower" -v mk="$new_marks" 'BEGIN {OFS=","} $1==rn {$3=mk} 1' "$exam.csv" > temp.csv && mv temp.csv "$exam.csv"
                else
                    # Add a new row for the student in the exam CSV file with new marks
                    read -p "Enter marks for $exam: " new_marks
                    # Check if the file ends with a newline
                    if [ -n "$(tail -c 1 "$exam.csv")" ]; then
                        echo "" >> "$exam.csv"  # Add a newline if missing
                    fi
                    # Append new student data to the exam CSV file
                    echo "$student_roll,$student_name,$new_marks" >> "$exam.csv"
                fi
            else
                # Display an error message if the exam CSV file doesn't exist
                echo "Error: Exam CSV file '$exam.csv' not found."
            fi
        done

        # Run the combine function to update main.csv
        combine
    else
        echo "Incorrect number of arguments"
    fi
}

plot_marks() {
    if [ "$num_args" -eq 1 ]; then
        python3 plot_marks.py main.csv  # Assuming main.csv is the CSV file containing student marks
    else
        echo "Incorrect number of arguments"
    fi
}

attendance() {
    if [ "$num_args" -eq 1 ]; then
        python3 attendance.py main.csv  # Assuming main.csv is the CSV file containing student marks
    else
        echo "Incorrect number of arguments"
    fi
}

# Function to calculate statistics and determine the topper
statistics() {
    if [ "$num_args" -eq 1 ]; then
        # Check if main.csv exists
        if [ ! -f "main.csv" ]; then
            echo "Error: main.csv not found. Please run 'bash submission.sh combine' to create main.csv."
            return 1
        fi

        if ! head -n 1 main.csv | grep -q ",total"; then
            echo "Error: Total column not found in main.csv. Please run 'bash submission.sh total' to calculate total marks."
            return 1
        fi

        # Call the Python script to calculate statistics and determine the topper
        python3 calculate_statistics.py main.csv
    else
        echo "Incorrect number of arguments"
    fi
}

# Function to display student information
student_info() {
    if [ "$num_args" -eq 2 ]; then
        student_roll="${args[1]}"
        # Check if main.csv exists
        if [ ! -f "main.csv" ]; then
            echo "Error: main.csv not found. Please run 'bash submission.sh combine' to create main.csv."
            return 1
        fi

        # Check if total marks have been calculated
        if ! head -n 1 main.csv | grep -q ",total"; then
            echo "Error: Total column not found in main.csv. Please run 'bash submission.sh total' to calculate total marks."
            return 1
        fi

        # Check if the student exists in main.csv
        if ! grep -q "^$student_roll," main.csv; then
            echo "Error: Student with Roll Number '$student_roll' not found in main.csv."
            return 1
        fi

        # Get the student's marks and total from main.csv
        student_info=$(awk -F, -v roll="$student_roll" 'NR>1 && $1==roll {print $0}' main.csv)
        student_total=$(echo "$student_info" | awk -F, '{print $NF}')
        student_name=$(echo "$student_info" | awk -F, '{print $2}')
        student_marks=$(echo "$student_info" | awk -F, '{for (i=3; i<=NF-1; i++) if ($i!="a") print $i}')

        # Get the number of exams in which the student was absent (marks = 'a')
        absent_exams=$(echo "$student_info" | awk -F, '{for (i=3; i<=NF-1; i++) if ($i=="a") count++} END {print count}')

        # Calculate the rank of the student based on total marks
        rank=$(awk -F, -v total="$student_total" '$NF>total {count++} END {print count}' main.csv)

        # Display student information
        echo "Student Name: $student_name"
        echo "Roll Number: $student_roll"
        echo "Rank: $rank"
        echo "Marks in Each Exam:"
        awk -F, -v roll="$student_roll" 'NR==1 {for (i=3; i<=NF-1; i++) exams[i]=$i} NR>1 && $1==roll {for (i=3; i<=NF-1; i++) print exams[i] " : " ($i=="a" ? "Absent" : $i)}' main.csv
        echo "Total Marks: $student_total"
        echo "Number of Exams Absent: $absent_exams"
    else
        echo "Incorrect number of arguments"
    fi
}

exam_info() {
    if [ "$num_args" -eq 2 ]; then
        exam_name="${args[1]}"
        if [ "$exam_name" = "total" ]; then
            echo "Error: 'total' is not a valid exam name."
        else
            python3 exam_info.py "$exam_name" main.csv  # Replace main.csv with your CSV file path
        fi
    else
        echo "Incorrect number of arguments"
    fi
}





# Execute the appropriate command based on user input
case $command in
    "combine")
        combine
        ;;
    "upload")
        upload
        ;;
    "total")
        total
        ;;
    "git_init")
        git_init
        ;;
    "git_commit")
        git_commit
        ;;
    "git_checkout")
        git_checkout
        ;;
    "update")
        update
        ;;
    "plot_marks")
        plot_marks
        ;;
    "attendance")
        attendance
        ;;
    "exam_info")
        exam_info
        ;;
    "statistics")
        statistics
        ;;
    "student_info")
        student_info
        ;;

    *)
        echo "Invalid command. Usage: bash submission.sh <command> <extra arguments>"
        ;;
esac
