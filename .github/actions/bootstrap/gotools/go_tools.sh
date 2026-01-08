#!/bin/bash
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Exit immediately if a command exits with a non-zero status
set -e

# Parses the go_deps file and generates go_install.sh with go install commands

GO_INSTALL_LINES=""

# Read the go_deps file line by line
while IFS= read -r line; do
  # Ignore lines with only whitespaces or comments
  if [[ -z "$line" || "$line" =~ ^# ]]; then
    continue
  fi

  # Split the line into columns
  IFS=" " read -r -a columns <<< "$line"
  if [[ ${#columns[@]} -lt 2 ]]; then
    echo "Invalid line: $line"
    exit 1
  fi

  # Extract columns
  col1=${columns[0]}
  col2=${columns[1]}
  col3=${columns[2]}
  col4=${columns[3]}

  # Append to GO_INSTALL_LINES
  if [[ -n "$col4" && -n "$col5" ]]; then
    GO_INSTALL_LINES+="GOBIN=/tmp go install \"$col1@v$col2\""$'\n'
    GO_INSTALL_LINES+="mv /tmp/$col3 /usr/local/bin/$col4"$'\n'
  else
    GO_INSTALL_LINES+="go install \"$col1@v$col2\""$'\n'
  fi
done < go_deps

# Create go_install.sh file
cat <<EOF > go_install.sh
#!/bin/bash -x
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

$GO_INSTALL_LINES
EOF

# Make go_install.sh executable
chmod +x go_install.sh
