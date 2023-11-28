# install_packages.R

# Function to install a specific version of a package
install_specific_version <- function(package_name, version, repos = "http://cran.us.r-project.org") {
  install.packages(package_name, version = version, repos = repos, dependencies = TRUE)
}

# List of packages and their specific versions
packages <- list(
  "kernlab" = "0.9-24",
  "ROCR" = "1.0-7",
  "class" = "7.3-14",
  "mvtnorm" = "1.0.8",
  "multcomp" = "1.4-8",
  "coin" = "1.2.2",
  "party" = "1.0-25",
  "e1071" = "1.6-7",
  "randomForest" = "4.6-12"
)

# Install the packages with specific versions
for (package_name in names(packages)) {
  version <- packages[[package_name]]
  cat(paste("Installing", package_name, "version", version, "\n"))
  install_specific_version(package_name, version)
}

# Optional: Load the installed packages
# Example: library(kernlab)

