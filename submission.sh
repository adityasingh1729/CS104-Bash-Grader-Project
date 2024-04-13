# #!/bin/bash

# init_string="Roll_Number,Name,Marks"

# for file in *.csv; do
#     NAME=$(echo "$file" | cut -d'.' -f1)
#     if [[ "$NAME" != "main" ]]; then
#         init_string="${init_string},${NAME}"
#     fi
# done

# echo "$init_string" > main.csv

#!/bin/bash

# Define the command line argument
command="$1"

# Check if the command is "combine"
if [ "$command" == "combine" ]; then
    # Initialize an array to store unique exam names
    declare -a exams
    
    # Loop through each CSV file in the directory
    for file in *.csv; do
        # Skip main.csv itself
        if [ "$file" != "main.csv" ]; then
            # Extract exam name from the file name
            exam="${file%.*}"
            # Append exam name to the exams array
            exams+=("$exam")
        fi
    done
    
    # Generate the header for main.csv dynamically based on unique exam names
    header="Roll_Number,Name"
    for exam in "${exams[@]}"; do
        header+=",$exam"
    done
    
    # Write the header to main.csv
    echo "$header" > main.csv
    
    # Loop through each CSV file again to populate main.csv
    for file in *.csv; do
        # Skip main.csv itself
        if [ "$file" != "main.csv" ]; then
            # Extract exam name from the file name
            exam="${file%.*}"
            
            # Process each line in the CSV file
            while IFS=',' read -r roll_number name marks; do
                # Check if the line is a header
                if [ "$roll_number" != "Roll_Number" ]; then
                    # Check if the student is already in main.csv
                    existing_student=$(grep "$roll_number" main.csv)
                    
                    # If the student doesn't exist, add a new row
                    if [ -z "$existing_student" ]; then
                        echo "$roll_number,$name" >> main.csv
                    fi
                    
                    # Append marks to the corresponding exam column
                    sed -i "/$roll_number/s/$/,$marks/" main.csv
                fi
            done < "$file"
        fi
    done
    
    echo "main.csv created successfully."
else
    echo "Invalid command. Usage: bash submission.sh combine"
fi
