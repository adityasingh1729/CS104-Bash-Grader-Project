#!/bin/bash

# Define the command-line arguments
command=$1
args=("$@")
num_args="$#"

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
    isTotal=0
    if [ -f "main.csv" ]; then
        if head -n 1 main.csv | grep -q ",total"; then
            isTotal=1
        fi
    fi
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

upload() {
    if [[ "$num_args" -eq 2 ]]; then
        if [ -n "${args[1]}" ]; then
            cp "${args[1]}" .
            echo "File uploaded successfully."
        else
            echo "Error: Missing file path. Usage: bash submission.sh upload <file_path>"
        fi
    else
        echo "Incorrect number of arguments"
    fi
}

git_dir=""
storeFolder=".hidden"
if [ -f "$storeFolder" ]; then
    read -r git_dir < "$storeFolder"
fi

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

git_commit() {
    if [[ "$num_args" -eq 3 ]]; then
        if [ ! -f "$storeFolder" ]; then
            echo "Error: Git repository not initialized. Please run 'bash submission.sh git_init <remote_dir_path>' first."
        elif [[ "${args[1]}" == "-m" ]]; then
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



git_checkout() {
    git_log="$git_dir/.git_log"
    if [ -f "$storeFolder" ]; then
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
            rm *.csv
            cp "$commit_dir"/*.csv .
            echo "Checked out to commit $hash_value."
        else
            echo "Error: Commit not found."
        fi
    else
        echo "Error: Git repository not initialized. Please run 'bash submission.sh git_init <remote_dir_path>' first."
    fi
}


# Execute the appropriate command
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
    *)
        echo "Invalid command. Usage: bash submission.sh <command> <extra arguments>"
        ;;
esac
