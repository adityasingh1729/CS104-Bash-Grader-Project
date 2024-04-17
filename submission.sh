#!/bin/bash

# Define the command-line arguments
command=$1
extra_arguments=$2

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
    if head -n 1 main.csv | grep -q ",total"; then
        isTotal=1
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
    roll_numbers=$(sed '1d' *.csv | awk -F, 'NR>1 {print $1}' | grep -v 'Roll_Number' | sort | uniq)

    # Iterate over unique roll numbers
    for roll_number in $roll_numbers; do
        # Initialize row for the current roll number
        row="$roll_number"

        # Get the name for the current roll number (assuming names don't vary)
        name=$(awk -F, -v rn="$roll_number" 'NR>1 && $1==rn {print $2; exit}' *.csv | grep -v '^$')

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
                        row="$row,a"
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
    if [ -n "$extra_arguments" ]; then
        cp "$extra_arguments" .
        echo "File uploaded successfully."
    else
        echo "Error: Missing file path. Usage: bash submission.sh upload <file_path>"
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
    *)
        echo "Invalid command. Usage: bash submission.sh <command> <extra arguments>"
        ;;
esac
