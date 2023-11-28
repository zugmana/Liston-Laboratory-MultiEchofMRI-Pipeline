#!/bin/bash

# Initialize variables
processing_flag=""
arg_p=""
arg_d=""
arg_c=""

# Flag to track the last processed option
last_option=""

# Iterate through the arguments
for arg in "$@"; do
  case "$arg" in
    -anat|-func)
      # Ensure that processing_flag is not already set
      if [ -z "$processing_flag" ]; then
        processing_flag="$arg"
      else
        # Display usage instructions when more than one processing flag is specified
        echo "Usage: entrypoint.sh {-anat|-func} -p participant -d directory for data -c num_proc"
        exit 1
      fi
      last_option=""
      ;;
    -p|-d|-c)
      last_option="$arg"
      ;;
    *)
      case "$last_option" in
        -p)
          arg_p="$arg"
          ;;
        -d)
          arg_d="$arg"
          ;;
        -c)
          arg_c="$arg"
          ;;
        *)
          # Display usage instructions when an unrecognized flag or argument is provided
          echo "Usage: entrypoint.sh {-anat|-func} -p participant -d directory for data -c num_proc"
          exit 1
          ;;
      esac
      last_option=""
      ;;
  esac
done

# Check if the user provided all required arguments
if [ -n "$processing_flag" ] && [ -n "$arg_p" ] && [ -n "$arg_d" ] && [ -n "$arg_c" ]; then
  # Execute the corresponding script or command for the chosen processing type
  case "$processing_flag" in
    -anat)
      # Execute the corresponding script or command for anatomical processing
      echo "Executing anatomical script with arguments: $arg_p $arg_d $arg_c"
      anat_highres_HCP_wrapper_par.sh $arg_d $arg_p $arg_c
      ;;
    -func)
      # Execute the corresponding script or command for functional processing
      echo "Executing functional script with arguments: $arg_p $arg_d $arg_c"
      func_preproc+denoise_ME-fMRI_wrapper.sh $arg_d $arg_p $arg_c
      ;;
  esac
else
  # Display usage instructions when the input is not as expected
  echo "Usage: entrypoint.sh {-anat|-func} -p participant -d directory for data -c num_proc"
  exit 1
fi
